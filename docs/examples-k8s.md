## Example workloads

### Basic example

A single pod running NginX container, with 1 dynamically provisioned Zadara Volume:

NAS (NFS)

```
kubectl create -f deploy/examples/nfs/storageclass.yaml
kubectl create -f deploy/examples/nfs/pvc.yaml
kubectl create -f deploy/examples/nfs/pod.yaml
```

Block (iSCSI)

```
kubectl create -f deploy/examples/iscsi/storageclass.yaml
kubectl create -f deploy/examples/iscsi/pvc.yaml
kubectl create -f deploy/examples/iscsi/pod.yaml
```

### Snapshots and Clones

Examples below assume that you already have created an example payload for NAS or Block volume, as shown above.

NAS (NFS)

- Clone Volume and attach to another Pod:
    ```
        kubectl create -f deploy/examples/nfs/clone/clone.yaml
        kubectl create -f deploy/examples/nfs/clone/pod.yaml
    ```
- Create snapshot, restore and attach it to another Pod:

    ```
        kubectl create -f deploy/examples/nfs/snapshot/create-snapshot.yaml
        kubectl create -f deploy/examples/nfs/snapshot/create-from-snap.yaml
        kubectl create -f deploy/examples/nfs/snapshot/pod.yaml
    ```

Block (iSCSI)

- Clone Volume and attach to another Pod:

    ```
        kubectl create -f deploy/examples/iscsi/clone/clone.yaml
        kubectl create -f deploy/examples/iscsi/clone/pod.yaml
    ```
- Create snapshot, restore and attach it to another Pod:

    ```
        kubectl create -f deploy/examples/iscsi/snapshot/create-snapshot.yaml
        kubectl create -f deploy/examples/iscsi/snapshot/create-from-snap.yaml
        kubectl create -f deploy/examples/iscsi/snapshot/pod.yaml
    ```
