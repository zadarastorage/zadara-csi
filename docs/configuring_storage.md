# Kubernetes Storage configuration

## Storage Class

Example:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: zadara-csi-nas
provisioner: csi.zadara.com
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions: []
parameters:
  VSCStorageClassName: "all-flash"
  volumeOptions: ''
```

| parameter                        | description                                                                                                                                                                      | required                                           | examples                                         |
|----------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|--------------------------------------------------|
| `parameters.VSCStorageClassName` | Name of `VSCStorageClass` to provision volumes from                                                                                                                              | No (if not set, default `VSCStorageClass` is used) | `zadara-all-flash`                               |
| `parameters.volumeOptions`       | Additional options for creating Volumes, in JSON format. See `POST /api/volumes` documentation in http://vpsa-api.zadarastorage.com/#volumes for the complete list <sup>1</sup>. | No                                                 | `'{"nfsanonuid":"65500", "nfsanongid":"65500"}'` |
| `mountOptions`                   | Mount options for NAS Volumes, see [all NFS options](https://linux.die.net/man/5/nfs). Ignored for block volumes.                                                                | No                                                 | `["nfsvers=4.1", "hard"]`                        |

1. Volume options notes:
   - options that are always added:
       - `"attachpolicies": "NO"` VPSA-managed snapshot policies are not suitable for workloads that use multiple VPSA
       - `"nfsrootsquash":  "NO"` workload containers will not be able to `chmod` or `chown` mounted directory

   - options that are defined by Persistent Volume Claim (PVC)
       - `"name"`, `"capacity"`, `"block"`

   - options that are defined by Volume Service Controller (VSC)
       - `"pool"`: VSC Volume allocator decides which pool is used.

   - SMB options are generally not supported for NFS Volumes.


Read more about StorageClass configuration in [Usage Examples](examples.md#configuring-volume-options)

## Persistent Volume Claim (PVC)

Example:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: zadara-csi-nas-pvc
spec:
  accessModes:
    - ReadWriteMany
  # volumeMode can be "Filesystem" or "Block"
  volumeMode: Filesystem
  resources:
    requests:
      storage: 100Gi
  storageClassName: zadara-csi-nas
```

Zadara supports following `accessModes`:

| NAS             | Block            |
|-----------------|------------------|
| `ReadWriteOnce` | `ReadWriteOnce`  |
| `ReadOnlyMany`  | `ReadOnlyMany`   |
| `ReadWriteMany` | `ReadWriteMany`* |

Note: when using Block Volumes in `ReadWriteMany` mode, it's user's responsibility to ensure data consistency for multiple
concurrent readers and writers
(e.g. using distributed filesystem like HDFS, GFS, etc.).
