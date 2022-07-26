# Using pre-provisioning Volumes

Although the main purpose of CSI is dynamic volume provisioning, it is also possible to use pre-provisioned volumes.

🛈 For cloned (restored) Snapshots and Volumes see [Snapshots and Clones](example_snapshots.md) guide.

## Enabling auto-import of VPSA Volumes

By default, Volumes that already exist on the VPSA are not created in Kubernetes or VSC.

To enable auto-import of VPSA Volumes, add `storage.zadara.com/vsc-manage-external-volumes` annotation to VPSA Custom Resource:

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

Example YAML:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  volumeMode: Filesystem # or Block
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 54Gi
  storageClassName: io-test-nas
  csi:
    driver: csi.zadara.com
    volumeHandle: vpsa-sample-manual-test  # name of an ExternalVolume, or a Volume
```
- `spec.csi.volumeHandle` refers to the `metadata.name` of _ExternalVolume_, or _Volume_ custom resource.
- `spec.csi.driver` refers to the name of the CSI driver (`kubectl get csidrivers`).
- `spec.storageClassName` refers to the `metadata.name` of an existing _StorageClass_.
  Must match `storageClassName` used in the PVC.

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
  volumeMode: Filesystem # or Block
  volumeName: my-pv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 54Gi
  storageClassName: io-test-nas
```

- `spec.volumeName` refers to the name of PersistentVolume.
- `spec.storageClassName` must match `storageClassName` used in the PV.

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
            - sleep
            - "3600"
          ## For Block volumes, use "volumeDevices" instead of "volumeMounts"
          #volumeDevices:
          #  - devicePath: /dev/sdb
          #    name: my-pv
          volumeMounts:
            - name: my-volume
              mountPath: /pv
      volumes:
        - name: my-volume
          persistentVolumeClaim:
            claimName: my-pvc # name of the PVC
```

- `claimName` refers to the `metadata.name` of the PersistentVolumeClaim we created earlier.
- use either `volumeDevices` or `volumeMounts` depending on the type of the volume.

When Pod is scheduled, _ExternalVolume_ will be converted into _Volume_ custom resource.
From there on, CSI driver will manage the lifecycle of the Volume:
attach, mount, and delete the VPSA Volume when PV is deleted (according to StorageClass' `reclaimPolicy`).
