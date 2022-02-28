# Snapshots and Clones

## Prerequisites

At a minimum, you will need one *PersistentVolumeClaim* in `Bound` state and a *VolumeSnapshotClass*.

### Create Persistent Volume Claims

This guide continues [example workload tutorial](example_workload.md), which creates PVCs and a Pods running I/O.

Alternatively, you can create a new PVC (if you do not have one already), using provided examples:

- [StorageClass](../deploy/examples/storageclass.yaml)
- [NAS PVC](../deploy/examples/pvc_nas.yaml)
- [Block PVC](../deploy/examples/pvc_block.yaml)

### Create VolumeSnapshotClass

VolumeSnapshotClass is similar to StorageClass, but used for snapshots.

🛈 [Full reference](snapshots_api_generated.md#volumesnapshotclass)

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: zadara-csi-snapshot-class
## reclaimPolicy tells the cluster what to do with the VolumeSnapshotContent and VPSA Snapshot,
##  when VolumeSnapshot is deleted. Allowed values: "Delete" or "Retain".
deletionPolicy: Delete
## driver refers to CSI driver name as appears in 'kubectl get csidrivers'
driver: csi.zadara.com
## parameters are driver-specific settings. Currently, no parameters are supported for VolumeSnapshotClass.
parameters: {}
```

This YAML is also available in [examples](../deploy/examples/snapshots/snapshotclass.yaml):

```shell
$ kubectl apply -f ./deploy/examples/snapshots/snapshotclass.yaml
volumesnapshotclass.snapshot.storage.k8s.io/zadara-csi-snapshot-class created
```

## Create and clone a Snapshot

🛈 All YAMLs from this guide are available in [examples/snapshots](../deploy/examples/snapshots) in this repo.

### Create VolumeSnapshot

We will create a Snapshot of `nas-io-test-0` PVC from [example workload tutorial](example_workload.md).

Make sure the PVC is in `Bound` state:

```
$ kubectl get pvc nas-io-test-0
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nas-io-test-0   Bound    pvc-6643b234-7d69-4ace-977a-24e762831fbf   50Gi       RWX            io-test-sc     69s
```

Create VolumeSnapshot as following:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: nas-io-test-0-snapshot
spec:
  volumeSnapshotClassName: zadara-csi-snapshot-class
  ## source: exactly one of:
  ## - persistentVolumeClaimName (for new snapshots)
  ## - volumeSnapshotContentName (for importing existing snapshots into k8s)
  source:
    ## persistentVolumeClaimName refers to the PVC from which a snapshot should be created
    persistentVolumeClaimName: nas-io-test-0
    ## volumeSnapshotContentName specifies the name of a pre-existing VolumeSnapshotContent object representing an existing volume snapshot
    # volumeSnapshotContentName: ""
```

Using provided examples:
```
$ kubectl apply -f ./deploy/examples/snapshots/snapshot_nas.yaml
volumesnapshot.snapshot.storage.k8s.io/nas-io-test-0-snapshot created
```

Verify creation, `READYTOUSE` must be `true`:

```
$ kubectl get volumesnapshot nas-io-test-0-snapshot
NAME                     READYTOUSE   SOURCEPVC       SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS               SNAPSHOTCONTENT                                    CREATIONTIME   AGE
nas-io-test-0-snapshot   true         nas-io-test-0                           50Gi          zadara-csi-snapshot-class   snapcontent-95730c4a-d78b-4ca3-a6d2-9b91eeb20877   <invalid>      46s
```

Check also [Snapshot Custom Resource](custom_resources_generated.md#snapshot):
```
$ kubectl get snapshot
NAME                                            STATUS   VOLUME                                     AGE
snapshot-95730c4a-d78b-4ca3-a6d2-9b91eeb20877   Ready    pvc-6643b234-7d69-4ace-977a-24e762831fbf   70s
```

At this point, a Snapshot will be created on VPSA.

### Clone VolumeSnapshot

Now we will create a new Volume, as a clone of previously created VolumeSnapshot.

⚠ `resources.requests.storage` must be the same as in VolumeSnapshot (i.e, size of the source Volume when the Snapshot was taken).
If needed, a cloned Volume can be expanded after creation.

Create a PVC as following (note the `dataSource` section):

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nas-io-test-0-snapshot-clone
spec:
  storageClassName: io-test-sc
  dataSource:
    name: nas-io-test-0-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```

Using provided examples:

```
$ kubectl apply -f ./deploy/examples/snapshots/clone_snapshot_nas.yaml
persistentvolumeclaim/nas-io-test-0-snapshot-clone created
```

Verify creation, `STATUS` should be `Bound`:
```
$ kubectl get pvc nas-io-test-0-snapshot-clone
NAME                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nas-io-test-0-snapshot-clone   Bound    pvc-bec1dd14-5689-4179-99a1-1075b88eeef2   50Gi       RWO            io-test-sc     25s
```

A new Volume will be created on the same VPSA of the source Volume.

### Cleanup

Source Volume cannot be deleted while it still has Snapshots.

⚠ Delete all VolumeSnapshots before uninstalling [example workload Chart](example_workload.md).

```
$ kubectl delete volumesnapshot nas-io-test-0-snapshot
volumesnapshot.snapshot.storage.k8s.io "nas-io-test-0-snapshot" deleted
```

Clones are independent of the source Volume and source Snapshot, they can be deleted at any time just as every other PVC.


## Clone a PVC

It is also possible to clone a PVC immediately in its current state, without creating a VolumeSnapshot.

🛈 Cloning a PVC does not use [Kubernetes Snapshots API](snapshots_api_generated.md)
(no need for Snapshot Controller or `snapshot.storage.k8s.io` CRDs).

The difference is that in PVC spec, we will use different `dataSource`.

We will create a clone  of `nas-io-test-0` PVC from [example workload tutorial](example_workload.md).
Make sure the PVC is in `Bound` state.

Create a new PVC as following:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nas-io-test-0-clone
spec:
  storageClassName: io-test-sc
  dataSource:
    name: nas-io-test-0
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
```

Using provided examples:
```
$ kubectl apply -f ./deploy/examples/snapshots/clone_pvc_nas.yaml
persistentvolumeclaim/nas-io-test-0-clone created
```

Verify creation, `STATUS` should be `Bound`:
```
$ kubectl get pvc nas-io-test-0-clone
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nas-io-test-0-clone   Bound    pvc-8ae82eb0-31f3-48ee-936f-e7583d80e281   50Gi       RWX            io-test-sc     17s
```

⚠ `resources.requests.storage` must be the same as in the source PVC.
If needed, a cloned Volume can be expanded after creation.
