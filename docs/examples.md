# Volume provisioning

## Run a Pod with IO on Block or NAS volume

We provide one, but very flexible Helm chart example to test Zadara-CSI plugin.
This example will allow you to run a single Pod, with an arbitrary container (busybox by default), and NAS or Block volume (or both).
The configuration can be easily changed using custom Helm values file.

The chart can be found in [helm/one-pod-one-pool](../helm/one-pod-one-pool) in this repository.

1.  Get release name of CSI plugin (`zadara-csi-driver` in this example).
    ```
    $ helm list
    NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
    zadara-csi-driver       default         1               2021-07-04 11:29:08.023368123 +0300 IDT deployed        zadara-csi-2.1.0        1.3.4
    ```

2. Get `provisioner` name of plugin
    ```
    $ helm status zadara-csi-driver | grep 'provisioner:'
    provisioner: csi.zadara.com
    ```

3. Create `my_values.yaml` (see examples below), set `provisioner` field.
    Alternatively, you can edit `helm/one-pod-one-pool/values.yaml`.

    Installing with default values will create both NAS and block volumes and run IO on the NAS.


4. Install
    ```
    $ helm install io-test -f my_values.yaml helm/one-pod-one-pool
    NAME: io-test
    LAST DEPLOYED: Sun Jul  4 12:11:01 2021
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    ```
    At this point you should see IO on a Volume on VPSA side.

#### Simple IO test

Here, we create a Pod with a busybox container, running IO with `dd` against a volume,
provisioned by CSI driver `csi.zadara.com`.

Note: in these examples the containers do not run in an infinite loop -
it is expected, that the Pod will restart every few minutes.

##### NAS

Example `my_values.yaml`:

```yaml
pod:
  name: dd-to-nas
  image: busybox:latest
  args: ["dd", "if=/dev/urandom", "of=/mnt/csi/test_file", "bs=1M", "count=10000"]
  env: []
storageClass:
  reclaimPolicy: Delete
  provisioner: csi.zadara.com
nas:
  name: nas-pvc
  accessMode: ReadWriteMany
  readOnly: false
  capacity: 50Gi
  mountPath: "/mnt/csi"
block: false
```

##### Block

Example `my_values.yaml`:

```yaml
pod:
  name: dd-to-block
  image: busybox:latest
  args: ["dd", "if=/dev/urandom", "of=/dev/sdx", "bs=1M", "count=10000", "oflag=direct"]
  env: []
storageClass:
  reclaimPolicy: Delete
  provisioner: csi.zadara.com
nas: false
block:
  name: block-pvc
  accessMode: ReadWriteOnce
  readOnly: false
  capacity: 50Gi
  devicePath: "/dev/sdx"
```

## Configuring volume options

In this section we show additional examples for [Storage Class](README.md#storage-class) configuration.

You can fine-tune Volume creation options using `parameters.volumeOptions` field of StorageClass.
`volumeOptions` is a *string* in JSON format.

Full list of options is available in [VPSA REST API documentation](http://vpsa-api.zadarastorage.com/#volumes)

However, some options are not supported in StorageClass parameters:
- Following parameters are set based on PVC: `name`, `capacity`, `pool`, `block`.
- Since CSI driver supports only NFS for NAS volumes, SMB parameters are not supported.


### Volumes with auto-expand support

Know the difference:
- `allowVolumeExpansion` in StorageClass allows you to modify capacity of a PVC.
  This means you can *manually* resize a PVC on Kubernetes side (which will trigger volume resize on a VPSA).

- `plugin.autoExpandSupport` in zadara-csi Helm Chart, and `parameters.volumeOptions: '{"autoexpand":"YES"}'`
  will use [VPSA Volumes auto-expand feature](http://guides.zadarastorage.com/release-notes/1908/whats-new.html#volume-auto-expand).
  Volumes are resized *automatically*, based on free capacity.
  CSI `expander` CronJob will periodically update PVCs to reflect the actual Volume capacity.

Example StorageClass with auto-expand:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: zadara-autoexpand
provisioner: csi.zadara.com
reclaimPolicy: Delete
allowVolumeExpansion: true  # must be true, to keep PVCs in-sync with VPSA volumes
parameters:
  # poolid: pool-00010003  # set, when VPSA has multiple Storage Pools
  volumeOptions: |-
    {
      "autoexpand":"YES",
      "maxcapacity":"2000G",
      "autoexpandby":"10G"
    }
```

### Other common volumeOptions

Add the following `parameters` to your StorageClass.

Note how `volumeOptions` JSON string can be a single-line (with quotes) or multi-line (with `|-` symbol)

Encrypted volumes:
```yaml
parameters:
  volumeOptions: |-
    {
      "crypt":"YES"
    }
```

Compression and deduplication for Flash Array VPSA:
```yaml
parameters:
  volumeOptions: '{"compress":"YES", "dedupe":"YES"}'
```

# Resize Persistent Volume Claim

VPSA supports online Volume expansion for block and NAS volumes.

Resizing of a PVC can be done *with no downtime*: no need to stop IO or restart application Pods.

- For NAS volumes additional capacity is available immediately.

- Block volumes may require some extra configuration to add capacity to the file system (if present).
  [Example for ext4](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/storage_administration_guide/ext4grow).
  Typically, this can be done online as well.

### Requirements and limitations:
- To allow Persistent Volume Claims to be expanded, a StorageClass must be defined with `allowVolumeExpansion: true`.
- Capacity cannot be decreased

### Example

We will show how to add capacity to PVC `io-test-nas-pvc` from [the previous example](#volume-provisioning):
```
$ kubectl get pvc
NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
io-test-nas-pvc         Bound    pvc-4e5f9b7c-6e68-4476-95d4-6db0057ba839   50Gi       RWX            io-test-nas         7s
```

Check that `ALLOWVOLUMEEXPANSION` is enabled for the StorageClass:
```
$ kubectl get sc
NAME                PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
io-test-nas         csi.zadara.com   Delete          Immediate           true                   72s
```

Update the PVC: set capacity to `150Gi`:
```
$ kubectl patch pvc io-test-nas-pvc -p '{"spec":{"resources":{"requests":{"storage": "150Gi"}}}}'
persistentvolumeclaim/io-test-nas-pvc patched
```

You can also run `kubectl edit pvc io-test-nas-pvc` and update capacity interactively.

Capacity is updated:
```
$ kubectl get pvc
NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
io-test-nas-pvc         Bound    pvc-4e5f9b7c-6e68-4476-95d4-6db0057ba839   150Gi      RWX            io-test-nas         2m7s
```

You can also check available capacity from inside the Pod.
We use a Pod from [the previous example](#volume-provisioning):
```
$ kubectl get po
NAME                READY   STATUS    RESTARTS   AGE
io-test-dd-to-nas   1/1     Running   0          3m17s
```
Check capacity (only PVC volume shown):
```
$ kubectl exec io-test-dd-to-nas -- df -h
Filesystem                Size      Used Available Use% Mounted on
...
10.10.12.2:/export/pvc-4e5f9b7c-6e68-4476-95d4-6db0057ba839
                        150.0G    190.0M    149.8G   0% /mnt/csi
...
```

# Snapshots and clones

We provide instructions for `v1` API. To use `v1beta1` API,
replace `snapshot.storage.k8s.io/v1` with `snapshot.storage.k8s.io/v1beta1` in example YAMLs.

The following instructions apply to NAS volume.
Examples for block volume are available in `./deploy/examples/block`.
Replace `nas` with `block` in `kubectl` commands and follow the same procedure.

Full reference for `snapshot.storage.k8s.io/v1` API ais available [here](snapshots-reference.md).

---

**Additional prerequisites**

1. In these examples we assume that you already have:
    - StorageClass
    - PersistentVolumeClaim
    - Pod using the PVC

    Follow [the previous example](#volume-provisioning) to create all required resources.


2. Create a SnapshotClass.
    We will use it in all following examples.

    SnapshotClass is cluster-scoped, like StorageClass.
    Same SnapshotClass can be used for both NAS and block volume snapshots.
    ```
    $ kubectl apply -f ./deploy/examples/snapshot-class.yaml
    volumesnapshotclass.snapshot.storage.k8s.io/zadara-csi-snapclass created

    $ kubectl get volumesnapshotclass zadara-csi-snapclass
    NAME                   DRIVER           DELETIONPOLICY   AGE
    zadara-csi-snapclass   csi.zadara.com   Delete           42s
    ```

## Create and clone a Snapshot

### Create VolumeSnapshot

Now we will create a Snapshot of `io-test-nas-pvc` PVC.

This is the PVC, make sure it is in `Bound` state:
```
$ kubectl get pvc
NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
io-test-nas-pvc      Bound    pvc-3e32e7b5-b864-453c-a62b-58908d40090b   50Gi       RWX            io-test-nas      3h7m
```

In `./deploy/examples/nas/create-snapshot.yaml` we have VolumeSnapshot definition,
referencing `io-test-nas-pvc` PVC.

Create VolumeSnapshot:
```
$ kubectl apply -f ./deploy/examples/nas/create-snapshot.yaml
volumesnapshot.snapshot.storage.k8s.io/nas-snapshot-test created
```

Verify creation:
```
$ kubectl get volumesnapshot nas-snapshot-test
NAME                READYTOUSE   SOURCEPVC         SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS          SNAPSHOTCONTENT                                    CREATIONTIME   AGE
nas-snapshot-test   true         io-test-nas-pvc                           0             zadara-csi-snapclass   snapcontent-a8b8258a-ed63-46f5-85be-719174374698   3m37s          3m37s
```

At this point, a Snapshot will be created on VPSA.

### Clone VolumeSnapshot

In `./deploy/examples/nas/clone-snapshot.yaml` we have PVC definition,
referencing VolumeSnapshot `nas-snapshot-test` that we have created earlier.

Caveat: `resources.requests.storage` must be set.
However, if requested capacity is smaller, then new PVC will be created with the same capacity as the original one.
Setting capacity to a larger value will result in an error (this will be fixed in future versions).

Clone VolumeSnapshot:
```
$ kubectl apply -f ./deploy/examples/nas/clone-snapshot.yaml
persistentvolumeclaim/nas-from-snapshot created

$ kubectl get pvc nas-from-snapshot
NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nas-from-snapshot   Bound    pvc-69988436-5782-47cf-8da4-0f455b840281   50Gi       RWX            io-test-nas    3m49s
```
You should see a new Volume on your VPSA.


## Clone a PVC

It is also possible to clone a PVC immediately, without creating VolumeSnapshot
(on VPSA side a snapshot will be created automatically).

The difference is that in PVC spec, we will use different `dataSource`:

```yaml
  dataSource:
    name: io-test-nas-pvc
    kind: PersistentVolumeClaim
```

instead of

```yaml
  dataSource:
    name: nas-snapshot-test
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
```

Create a PVC as a clone of `io-test-nas-pvc`:
```
$ kubectl apply -f ./deploy/examples/nas/clone-pvc.yaml
persistentvolumeclaim/cloned-nas created

$ kubectl get pvc
NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cloned-nas          Bound    pvc-7db0d079-d885-4dab-8721-36e68e12f691   50Gi       RWO            io-test-nas    3m51s
io-test-nas-pvc     Bound    pvc-5dd71185-9538-4960-b564-60cdf0cc7ae9   50Gi       RWX            io-test-nas    16h
```

Caveat: `resources.requests.storage` must be the same as in source PVC.
Kubernetes requires that new PVC request must be greater than or equal in size to the specified PVC data source.
Setting capacity to a larger value will result in an error (this will be fixed in future versions).
