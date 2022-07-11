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

You can configure frequency of the refresh of ExternalVolumes by changing
`VSC.manageExternalVolumesRefreshPeriod` in [ConfigMap](configmap.md).

## ExternalVolume custom resource

When auto-import of VPSA Volumes is enabled, the VSC will create a new
[ExternalVolume](custom_resources_generated.md#externalvolume) Custom Resource
for each VPSA Volume that is not yet created in the Kubernetes.

```
$ kubectl get externalvolumes
NAME          TYPE   CAPACITY   VPSA          VPSA VOLUME ID    AGE
migrated      NAS    116Gi      vpsa-sample   volume-000001e1   21h
manual-test   NAS    54Gi       vpsa-sample   volume-000000f1   12d
```

🛈 Deleting ExternalVolume does not delete the VPSA Volume.

## Using External Volume

For pre-provisioned Volumes, PersistentVolume and PersistentVolumeClaim are created manually.

Create a PersistentVolume referencing CSI driver
and [ExternalVolume](custom_resources_generated.md#externalvolume) Custom Resource:

```yaml),
then create a PersistentVolumeClaim referencing the PersistentVolume.

Same procedure can be used with regular Volumes (`kubectl get volumes`).

### Creating PersistentVolume

Example YAML:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 100Gi
  storageClassName: io-test-nas
  csi:
    driver: csi.zadara.com
    volumeHandle: manual-test
```
- `spec.csi.volumeHandle` refers to the name of ExternalVolume, or Volume custom resource.
- `spec.csi.driver` refers to the name of the CSI driver (`kubectl get csidrivers`).
- `spec.storageClassName` must match `storageClassName` used in the PVC.

_ExternalVolume_ will be converted into _Volume_ custom resource upon attaching it to a Node
i.e, before a Pod consuming the PVC starts.
In CSI spec terms, this is done as part of `ControllerPublishVolume` operation.

### Creating PersistentVolumeClaim

Example YAML:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pv
  # namespace: my-namespace
spec:
  volumeName: my-pv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: io-test-nas
```

- `spec.volumeName` refers to the name of PersistentVolume.
- `spec.storageClassName` must match `storageClassName` used in the PV.
