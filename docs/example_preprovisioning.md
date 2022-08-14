# Using pre-provisioned Volumes

Although the main purpose of CSI is dynamic volume provisioning, it is also possible to use pre-provisioned volumes.

🛈 For cloned (restored) Snapshots and Volumes see [Snapshots and Clones](example_snapshots.md) guide.

⚠ Pre-provisioned volumes require more manual configuration, than dynamically provisioned ones:

- default StorageClass logic is not applied
- reclaim policy and CSI driver name are not taken from the StorageClass
- capacity and volumeMode are not set automatically

## Enabling auto-import of VPSA Volumes

By default, Volumes that already exist on the VPSA are not created in Kubernetes or VSC.

To enable auto-import of VPSA Volumes, add `storage.zadara.com/vsc-manage-external-volumes`
annotation to VPSA Custom Resource:

```yaml
apiVersion: storage.zadara.com/v1
kind: VPSA
metadata:
  name: vpsa-sample
  annotations:
    storage.zadara.com/vsc-manage-external-volumes: "true"

...
```

Currently, any non-empty value is accepted.

Alternatively, use a one-liner:

```shell
kubectl patch vpsa vpsa-sample -p '{"metadata": {"annotations":{"storage.zadara.com/vsc-manage-external-volumes":"true"}}}' --type=merge
```

🛈 You can configure frequency of the refresh of ExternalVolumes by changing
`VSC.manageExternalVolumesRefreshPeriod` in [ConfigMap](configmap.md).

## ExternalVolume custom resource

When auto-import of VPSA Volumes is enabled, the VSC will create a new
[ExternalVolume](custom_resources_generated.md#externalvolume) Custom Resource
for each VPSA Volume that is not yet created in the Kubernetes.

```
$ kubectl get externalvolumes
NAME                      TYPE   CAPACITY   VPSA          VPSA VOLUME ID    AGE
vpsa-sample-migrated      NAS    116Gi      vpsa-sample   volume-000001e1   21h
vpsa-sample-manual-test   NAS    54Gi       vpsa-sample   volume-000000f1   12d
```

🛈 Deleting ExternalVolume does not delete the VPSA Volume.

## Using External Volume

For pre-provisioned Volumes, PersistentVolume and PersistentVolumeClaim are created manually.

Create a PersistentVolume referencing CSI driver
and [ExternalVolume](custom_resources_generated.md#externalvolume) Custom Resource,
then create a PersistentVolumeClaim referencing the PersistentVolume.

Same procedure can be used with regular Volumes (`kubectl get volumes`).

### Create Storage Class

Create a StorageClass if you do not have one already.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: io-test-nas
provisioner: csi.zadara.com
allowVolumeExpansion: true
reclaimPolicy: Delete
parameters:
  VSCStorageClassName: "vscstorageclass-sample"
```

- change `parameters.VSCStorageClassName` to the name of the VSCStorageClass (or remove to use the default)

### Creating PersistentVolume

The most important field here is `spec.csi.volumeHandle`, referring to the name of an ExternalVolume.

Example YAML:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
  annotations:
    ## pv.kubernetes.io/provisioned-by annotation is used by k8s to delete the Volume when PV is deleted.
    ## Must match CSIDriver name and `spec.csi.driver` of the PersistentVolume.
    pv.kubernetes.io/provisioned-by: csi.zadara.com
spec:
  ## volumeMode can be "Filesystem" or "Block"
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  ## NOTE: capacity is not set automatically (and not checked) for pre-provisioned PersistentVolumes.
  ## Capacity cannot be decreased after creation.
  capacity:
    storage: 1Gi
  ## storageClassName is the name of the StorageClass.
  ## Must match `spec.storageClassName` of the PersistentVolumeClaim.
  storageClassName: io-test-nas
  ## persistentVolumeReclaimPolicy is the same as reclaimPolicy in StorageClass.
  ## Default policy is "Reclaim".
  persistentVolumeReclaimPolicy: Delete
  csi:
    ## driver must match CSIDriver name and `spec.csi.driver` of the PersistentVolume.
    driver: csi.zadara.com
    ## volumeHandle refers to the name of an ExternalVolume, or a Volume Custom Resource.
    volumeHandle: vpsa-sample-manual-test  # <-- CHANGE THIS
```

_ExternalVolume_ will be converted into _Volume_ custom resource upon attaching it to a Node
i.e, before a Pod consuming the PVC starts.
In CSI spec terms, this is done as part of `ControllerPublishVolume` operation.

### Creating PersistentVolumeClaim

Example YAML:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  # namespace: my-namespace
spec:
  ## volumeMode can be "Filesystem" or "Block"
  volumeMode: Filesystem
  ## volumeName is the name of the PersistentVolume.
  volumeName: my-pv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      ## NOTE: storage capacity should be greater than or equal to the size of the PersistentVolume.
      ## Capacity cannot be decreased after creation.
      storage: 1Gi
  ## storageClassName is the name of the StorageClass.
  storageClassName: io-test-nas
```

### Creating a workload consuming the PVC

Example Deployment YAML:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-with-pv
  labels:
    app: deployment-with-pv
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deployment-with-pv
  template:
    metadata:
      labels:
        app: deployment-with-pv
    spec:
      containers:
        - name: deployment-with-pv
          image: busybox
          command:
            - /bin/sh
            - -c
            - "while true; do dd if=/dev/urandom of=/pv/test_file bs=1M count=1000; sleep 1; done"
          ## For Block volumes, use "volumeDevices" instead of "volumeMounts",
          ## and update `dd` arguments in container `command` accordingly.
          #volumeDevices:
          #  - devicePath: /dev/sdb
          #    name: my-pv
          volumeMounts:
            - name: my-volume
              mountPath: /pv
      volumes:
        - name: my-volume
          persistentVolumeClaim:
            ## claimName refers to the `metadata.name` of the PersistentVolumeClaim we created earlier
            claimName: my-pvc
```

When Pod is scheduled, _ExternalVolume_ will be converted into _Volume_ custom resource.
From there on, CSI driver will manage the lifecycle of the Volume:
attach, mount, and delete the VPSA Volume when PVC is deleted
(according to `persistentVolumeReclaimPolicy` of the PersistentVolume).

To delete the Volume, PVC should be deleted _before the PV_, otherwise Volume may not be deleted.
This issue is resolved in k8s 1.23 (alpha feature, requires feature gate),
see [this guide](https://kubernetes.io/blog/2021/12/15/kubernetes-1-23-prevent-persistentvolume-leaks-when-deleting-out-of-order/).
