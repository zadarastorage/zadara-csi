# Migration from CSI 1.*x* to CSI 2.0

Migration process is designed to be fail-safe and non-intrusive.
No existing resources are deleted or modified. In case of errors it is possible to continue using the previous version.

## Limitations

- This process does not allow changing `CSIDriver` name (aka `provisioner` in StorageClass), or `StorageClass` name of
  existing PVCs and PVs. As a result, migration is limited to _one CSI Driver instance_ (i.e, one VPSA)
- Migrated _Volumes_ (CSI 2.0 custom resource) use VPSA Volume ID (e.g `volume-00000001`) as a name, while new _Volumes_
  will use PV name (e.g `pvc-7b3ff978-6cd1-424a-9416-f14b51d6477f`).

## Overview

1. Prepare for migration
    - extract values from the currently installed Chart
    - configure migrator `Job`

2. Uninstall CSI 1.x.

3. Run migrator tool, which includes:
    - installing CSI 2.0 Custom Resource Definitions (CRDs)
    - creating all Custom Resources as if all PVCs were created by CSI 2.0.

4. Install CSI 2.0

## Steps

### Prepare for migration

Get computed values (the defaults merged with user overrides) from installed Zadara-CSI 1.x Helm Chart:

```shell
$ helm get values zadara-csi --all
```

Save Values YAML in a file, except for the "COMPUTED VALUES" line:

```shell
$ helm get values zadara-csi --all | grep -v "COMPUTED VALUES" > values.yaml
```

Create a ConfigMap containing computed values.
Remember ConfigMap name and file name, they will be required for `Job` configuration
(in the example all names are already set).
```shell
$ kubectl create configmap csi-v1-values --from-file ./values.yaml
configmap/csi-v1-values created
```

Edit [migration_job.yaml](./deploy/migration/migration_job.yaml), follow the comments.

Job definition:
```yaml
# OPTIONAL: use v1beta1 with older k8s versions
apiVersion: batch/v1
kind: Job
metadata:
  name: csi-migrator-job
spec:
  template:
    spec:
      activeDeadlineSeconds: 120
      restartPolicy: OnFailure
      serviceAccountName: csi-migrator-sa
      containers:
        - name: csi-migrator
          # OPTIONAL: use custom registry
          image: "docker-registry.zadara-qa.com/zadara/csi-migrator-1to2:2.0.0"
          args:
            - "migrator"
            - "-f"
            - "/config/values/values.yaml"
            - "--crd-path"
            - "/config/crd/bases"
            # OPTIONAL: Dry run mode: --dry-run {all, crd, none}.
            # - all: do not persist any changes
            # - crd: only install CRD, dry-run the rest
            # - none: persist all changes
            - "--dry-run"
            - "none"
          volumeMounts:
            - mountPath: /config/values/values.yaml
              name: values-configmap
              # REQUIRED: same as name of the key in configMap (if created from file - same as the file name)
              subPath: "values.yaml"
      volumes:
        - name: values-configmap
          configMap:
            # REQUIRED: name of a configMap containing values.yaml of CSI v1.x
            name: "csi-v1-values"
            optional: false
```

Also, `ClusterRoleBinding` requires a proper `namespace` in reference to the `ServiceAccount`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: csi-migrator-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: csi-migrator-role
subjects:
  - kind: ServiceAccount
    name: csi-migrator-sa
    # REQUIRED: current namespace
    namespace: default
```

Other parts do not require any changes

<details>
<summary>Click to expand</summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: csi-migrator-role
rules:
  - apiGroups: [ "" ]
    resources: [ "persistentvolumes" ]
    verbs: [ "get", "list", "watch" ]
  - apiGroups: [ "apiextensions.k8s.io" ]
    resources: [ "customresourcedefinitions" ]
    verbs: [ "create" ]
  - apiGroups: [ "storage.zadara.com" ]
    resources: [ "*" ]
    verbs: [ "*" ]
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: csi-migrator-sa
```

---
</details>



### Uninstall CSI Driver 1.x

This step comes before running migration to make sure that CSI resources do not change during migration process.

You may want to save user-provided `my_values.yaml` of Zadara-CSI 1.x, in case you will need to reinstall it.

```shell
$ helm get values zadara-csi | grep -v "USER-SUPPLIED VALUES" > my_values.yaml
```

Uninstall CSI Driver 1.x:
```shell
$ helm uninstall zadara-csi
```

Uninstalling does not affect I/O or any existing resources.
New PVCs and Pods will wait in `Pending` state, until a new CSI driver is deployed.

### Run migrator

```shell
$ kubectl apply -f deploy/migration/migration_job.yaml
job.batch/csi-migrator-job created
clusterrole.rbac.authorization.k8s.io/csi-migrator-role created
serviceaccount/csi-migrator-sa created
clusterrolebinding.rbac.authorization.k8s.io/csi-migrator-rolebinding created
```

When finished you will see a completed Job and its Pod:
```
$ kubectl get jobs,pods
NAME                         COMPLETIONS   DURATION   AGE
job.batch/csi-migrator-job   1/1           11s        6m11s

NAME                            READY   STATUS      RESTARTS   AGE
pod/csi-migrator-job--1-npvr8   0/1     Completed   0          6m1s
```

This is an example of Custom Resources, created after running the migrator
(taken from our example-workload Chart).

```shell
$ kubectl get vscstorageclass.storage.zadara.com -o wide
  NAME                  STATUS   DEFAULT   MEMBERS   CAPACITY MODE   TOTAL   AVAILABLE   AGE
  vscstorageclass-csi            true                                                    61s

$ kubectl get vpsa.storage.zadara.com -o wide
  NAME  STATUS   DISPLAY NAME   HOSTNAME                                 VERSION   CAPACITY MODE   TOTAL   AVAILABLE   VSC                   AGE
  csi            csi            vsa-0000028d-zadara-qa9.zadaravpsa.com                                                 vscstorageclass-csi   60s

$ kubectl get volume.storage.zadara.com -o wide
  NAME              STATUS         TYPE    CAPACITY   VPSA   AGE
  volume-000000e8   Provisioning   Block   50Gi       csi    58s
  volume-000000e9   Provisioning   NAS     50Gi       csi    58s
  volume-000000ea   Provisioning   NAS     50Gi       csi    58s
  volume-000000eb   Provisioning   Block   50Gi       csi    58s

$ kubectl get volumeattachment.storage.zadara.com -o wide
  NAME                              STATUS     ISCSI   VOLUME            VSCNODE           AGE
  volume-000000e8.k8s-base-master   Creating           volume-000000e8   k8s-base-master   57s
  volume-000000e9.k8s-base-master   Creating           volume-000000e9   k8s-base-master   57s
  volume-000000ea.k8s-base-master   Creating           volume-000000ea   k8s-base-master   57s
  volume-000000eb.k8s-base-master   Creating           volume-000000eb   k8s-base-master   57s

```

🛈 VSCNode custom resource (one for each K8s Node) is not created at this point, it will be created by CSI 2.0 after installation.

Example logs:

<details>
<summary>Click to expand</summary>

```
$ kubectl logs csi-migrator-job--1-npvr8
Feb 13 16:18:16 [INFO] Executing pre-start actions...
Feb 13 16:18:16 [INFO] Starting container...
  Feb 13 16:18:16.768811 [migrator] [1] [INFO]                            applog.reinitLogger[  70] Logger updated | mode: text, colors: true
  Feb 13 16:18:16.769741 [migrator] [1] [INFO]                                      main.main[  65] Loaded Zadara-CSI v1.x values | values: &{ValuesVPSA:{Hostname:vsa-0000028d-zadara-qa9.zadaravpsa.com Token:******** UseTLS:true VerifyTLS:true} ValuesPlugin:{Provisioner:csi.zadara.com} Images:{CSIDriver:{Tag:1.3.10}}}, path: /config/values/values.yaml
  Feb 13 16:18:17.786087 [migrator] [1] [INFO]                                      main.main[  90] Starting Custom Resources manager |
  Feb 13 16:18:17.786246 [migrator] [1] [INFO]                                      main.main[ 118] Start | opts: &{VPSAClient:0xc0006d33b0 k8sClient:0xc0006d3180 values:0xc0002b0e10 dryRunCRDs:false dryRunResources:false CSIDriverName:csi.zadara.com VSCSCName:vscstorageclass-csi VPSAName:csi commonDescription:migrated from CSI Driver csi.zadara.com v1.3.10}
  Feb 13 16:18:17.786798 [migrator] [1] [INFO]                                main.createCRDs[  32] Read resource from path | path: /config/crd/bases/storage.zadara.com_snapshots.yaml
  Feb 13 16:18:17.791215 [migrator] [1] [INFO]                                main.createCRDs[  32] Read resource from path | path: /config/crd/bases/storage.zadara.com_volumeattachments.yaml
  Feb 13 16:18:17.793044 [migrator] [1] [INFO]                                main.createCRDs[  32] Read resource from path | path: /config/crd/bases/storage.zadara.com_volumes.yaml
  Feb 13 16:18:17.795111 [migrator] [1] [INFO]                                main.createCRDs[  32] Read resource from path | path: /config/crd/bases/storage.zadara.com_vpsas.yaml
  Feb 13 16:18:17.801721 [migrator] [1] [INFO]                                main.createCRDs[  32] Read resource from path | path: /config/crd/bases/storage.zadara.com_vscnodes.yaml
  Feb 13 16:18:17.802830 [migrator] [1] [INFO]                                main.createCRDs[  32] Read resource from path | path: /config/crd/bases/storage.zadara.com_vscstorageclasses.yaml
  Feb 13 16:18:17.813452 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create CustomResourceDefinition | CustomResourceDefinition: snapshots.storage.zadara.com, dryRun: false
  Feb 13 16:18:17.825157 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create CustomResourceDefinition | dryRun: false, CustomResourceDefinition: volumeattachments.storage.zadara.com
  Feb 13 16:18:17.839757 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create CustomResourceDefinition | CustomResourceDefinition: volumes.storage.zadara.com, dryRun: false
  Feb 13 16:18:17.869543 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create CustomResourceDefinition | dryRun: false, CustomResourceDefinition: vpsas.storage.zadara.com
  Feb 13 16:18:17.882330 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create CustomResourceDefinition | CustomResourceDefinition: vscnodes.storage.zadara.com, dryRun: false
  Feb 13 16:18:17.893684 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create CustomResourceDefinition | CustomResourceDefinition: vscstorageclasses.storage.zadara.com, dryRun: false
  Feb 13 16:18:17.915280 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create VSCStorageClass | VSCStorageClass: vscstorageclass-csi, dryRun: false
I0213 16:18:19.041083       1 request.go:665] Waited for 1.121831791s due to client-side throttling, not priority and fairness, request: GET:https://10.96.0.1:443/apis/scheduling.k8s.io/v1?timeout=32s
  Feb 13 16:18:20.930041 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create VPSA | VPSA: csi, dryRun: false
  Feb 13 16:18:21.110607 [migrator] [1] [INFO]                                   main.migrate[  63] Create Volumes Custom Resources |
  Feb 13 16:18:21.110728 [migrator] [1] [INFO]                              main.convertAllPV[  80] List all PersistentVolumes |
  Feb 13 16:18:21.213167 [migrator] [1] [INFO]                              main.convertAllPV[  85] Consider only PersistentVolumes of CSIDriver csi.zadara.com |
  Feb 13 16:18:21.213299 [migrator] [1] [INFO]                              main.convertOnePV[ 121] Get VPSA Volume | PersistentVolume: pvc-72d73174-0621-4ee1-b533-52dd7608300a, VPSAVolume: volume-000000e8
  Feb 13 16:18:23.333199 [migrator] [1] [INFO]                              main.convertOnePV[ 121] Get VPSA Volume | PersistentVolume: pvc-b57a2631-8bdc-4b65-899a-0a33ee00074d, VPSAVolume: volume-000000e9
  Feb 13 16:18:23.412054 [migrator] [1] [INFO]                              main.convertOnePV[ 121] Get VPSA Volume | PersistentVolume: pvc-aafb01db-2109-4364-b6d3-e77daf048a08, VPSAVolume: volume-000000eb
  Feb 13 16:18:23.452024 [migrator] [1] [INFO]                              main.convertOnePV[ 121] Get VPSA Volume | PersistentVolume: pvc-5fea7c87-0028-4b9d-b4ca-b7b95251ef14, VPSAVolume: volume-000000ea
  Feb 13 16:18:23.483061 [migrator] [1] [INFO]                              main.convertAllPV[ 104] Selected PersistentVolumes for migration | selected: 4, CSIDriver: csi.zadara.com, total: 4
  Feb 13 16:18:23.483208 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create Volume | Volume: volume-000000e8, dryRun: false
  Feb 13 16:18:23.922674 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set Volume status | Volume: volume-000000e8, dryRun: false
  Feb 13 16:18:23.933756 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create Volume | Volume: volume-000000e9, dryRun: false
  Feb 13 16:18:23.940823 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set Volume status | Volume: volume-000000e9, dryRun: false
  Feb 13 16:18:23.958965 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create Volume | Volume: volume-000000eb, dryRun: false
  Feb 13 16:18:23.967673 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set Volume status | Volume: volume-000000eb, dryRun: false
  Feb 13 16:18:23.978704 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create Volume | Volume: volume-000000ea, dryRun: false
  Feb 13 16:18:23.985173 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set Volume status | Volume: volume-000000ea, dryRun: false
  Feb 13 16:18:23.993610 [migrator] [1] [INFO]                                   main.migrate[  69] Create VolumeAttachments Custom Resources |
  Feb 13 16:18:23.994284 [migrator] [1] [INFO]                             main.convertAllVAs[ 169] List Servers of VPSA Volume | VPSAVolume: volume-000000e8, PersistentVolume: pvc-72d73174-0621-4ee1-b533-52dd7608300a
  Feb 13 16:18:24.089675 [migrator] [1] [INFO]                             main.convertAllVAs[ 169] List Servers of VPSA Volume | PersistentVolume: pvc-b57a2631-8bdc-4b65-899a-0a33ee00074d, VPSAVolume: volume-000000e9
  Feb 13 16:18:24.162706 [migrator] [1] [INFO]                             main.convertAllVAs[ 169] List Servers of VPSA Volume | VPSAVolume: volume-000000eb, PersistentVolume: pvc-aafb01db-2109-4364-b6d3-e77daf048a08
  Feb 13 16:18:24.243237 [migrator] [1] [INFO]                             main.convertAllVAs[ 169] List Servers of VPSA Volume | PersistentVolume: pvc-5fea7c87-0028-4b9d-b4ca-b7b95251ef14, VPSAVolume: volume-000000ea
  Feb 13 16:18:24.476647 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create VolumeAttachment | dryRun: false, VolumeAttachment: volume-000000e8.k8s-base-master
  Feb 13 16:18:24.551607 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set VolumeAttachment status | VolumeAttachment: volume-000000e8.k8s-base-master, dryRun: false
  Feb 13 16:18:24.558314 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create VolumeAttachment | VolumeAttachment: volume-000000e9.k8s-base-master, dryRun: false
  Feb 13 16:18:24.567585 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set VolumeAttachment status | dryRun: false, VolumeAttachment: volume-000000e9.k8s-base-master
  Feb 13 16:18:24.574219 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create VolumeAttachment | VolumeAttachment: volume-000000eb.k8s-base-master, dryRun: false
  Feb 13 16:18:24.581149 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set VolumeAttachment status | dryRun: false, VolumeAttachment: volume-000000eb.k8s-base-master
  Feb 13 16:18:24.592495 [migrator] [1] [INFO]                                 main.k8sCreate[ 235] Create VolumeAttachment | dryRun: false, VolumeAttachment: volume-000000ea.k8s-base-master
  Feb 13 16:18:24.599221 [migrator] [1] [INFO]                           main.k8sUpdateStatus[ 246] Set VolumeAttachment status | VolumeAttachment: volume-000000ea.k8s-base-master, dryRun: false
  Feb 13 16:18:24.611127 [migrator] [1] [INFO]                                   main.migrate[  74] Done |
```

---
</details>

### Finish migration

Install CSI 2.0: see [instructions](helm_deploy.md)

⚠ If your CSI Driver 1.x used a custom `provisioner` name (not `csi.zadara.com`),
please make sure it stays the same in CSI 2.0 `values.yaml`.

After installing, all Custom Resources will be updated.
This might take a few moments, after CSI 2.0 Pods are up and running.

Upon success, all `STATUS` columns will report `Ready` state.

## Cleanup

Delete migrator `Job` and its RBAC.
```
$ kubectl delete -f deploy/migration/migration_job.yaml
```

### Abort migration

In case of errors, you may want to delete Custom Resources and CRDs to start anew.

Deleting CRDs will cascade delete all associated Custom Resources.

⚠ Do not run these command if CSI 2.0 is already installed - it will delete all Volumes and other VPSA resources.

```
kubectl delete crd snapshots.storage.zadara.com
kubectl delete crd volumeattachments.storage.zadara.com
kubectl delete crd volumes.storage.zadara.com
kubectl delete crd vpsas.storage.zadara.com
kubectl delete crd vscnodes.storage.zadara.com
kubectl delete crd vscstorageclasses.storage.zadara.com
```
