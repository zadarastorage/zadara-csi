## Configuring zadara-csi plugin

<!--- helm: 10 -->

### Prerequisites
- Create at least one Storage Pool on VPSA.
- iSCSI initiator tools must be installed on K8s nodes:

    `apt-get install open-iscsi` on Ubuntu and other Debian-based

    `yum install iscsi-initiator-utils` on RedHat-based distribution

    Alternatively, you can run `./assets/prepare_node.sh -p`, to install one of the above for your Linux distribution.

- IQN (iSCSI qualified name, defined in `/etc/iscsi/initiatorname.iscsi`) *must be unique* for each Node.
If you change IQN, restart iSCSI service, using `systemctl restart iscsid`

#### Feature gates
For some CSI features, following
[feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)
must be enabled:
- Clone Volume: `VolumePVCDataSource` K8s 1.15 (enabled by default since 1.16)
- Restore Volume from Snapshot: `VolumeSnapshotDataSource` K8s 1.12+
- Expand Volume: `ExpandCSIVolumes` K8s 1.14+ (enabled by default since 1.16)
  and `ExpandInUsePersistentVolumes` K8s 1.11+ (enabled by default since 1.15)

Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` on Master and add feature gates like this:
```
 command:
    - kube-apiserver
    - --feature-gates=VolumeSnapshotDataSource=true,VolumePVCDataSource=true,ExpandCSIVolumes=true
```

Edit (create if it does not exist) `/etc/default/kubelet` on Nodes and set `kubelet` args:
```
KUBELET_EXTRA_ARGS='--feature-gates=VolumeSnapshotDataSource=true,VolumePVCDataSource=true,ExpandCSIVolumes=true'
```
You can also try editing `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf` (less preferred option).

Verify using `ps -aux | grep -e kubelet -e kube-apiserver | grep feature-gates`

_Note: the mechanism for enabling feature gates may differ between K8s versions._

#### Establishing iSCSI connectivity

The plugin requires to be able to manage iSCSI connections _on host_ for proper functioning.
You can choose between 2 different approaches:

- `rootfs`: running iscsiadm directly on host
- `client-server`: using `run-on-host-server` service

##### Running iscsiadm directly on host

This does not require any preparations to be done on Nodes (assuming you already have iSCSI initiator packages installed).

Node plugin container will run with bind mounted host root filesystem.


##### Installing run-on-host-server service
The plugin will communicate with host `iscsiadm` via Unix socket, exposed to Node plugin container.
This requires `run-on-host-server` service installed on host.

1. Copy `assets` from this repository to your working directory on a Node.

2. Run the run-on-host-server service installer
    ```
    ./assets/prepare_node.sh
    ```
    This will install `run-on-host-server` binary (currently available only for x64_64 systems) from `assets`
    and enable it as a system service (use `./assets/prepare_node.sh -u` to uninstall).

<!--- end -->

---

### Plugin deployment

Use one of the following methods:

- [Using Helm charts](deploy-helm.md)

- [Bare Kubernetes and kubectl](deploy-k8s.md)

After successful deployment you will see a Server created on your VPSA for each active K8s node. 

The most common problems:
- Invalid VPSA credentials (url, token)
- VPSA is not accessible (network problems)
- iSCSI is not configured properly:
    - initiator utils (e.g. `open-iscsi`) are not installed on K8s nodes 
    - `run-on-host-server` service is not installed, or is disabled
    - IQN in `/etc/initiatorname.iscsi` is not unique for each node

### Example workloads

These include examples of an application (nginx in most cases) using NAS and Block volumes,
dynamically provisioned by Zadara-CSI.
Also included examples of cloning volumes, creating and restoring snapshots.

- Using Helm charts (will be added soon)

- [Bare Kubernetes and kubectl](examples-k8s.md)


___

<!--- helm: 30 -->

### StorageClass parameters

| parameter | description | required | examples |
|-----------|-----------|-----------|----------|
| `poolid` |  Id of a Storage Pool to provision volumes from | If VPSA has only 1 Storage Pool - can be omitted.<br> Otherwise - required. | `pool-00000001` |

Example:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-zadara-nas
provisioner: csi.zadara.com
reclaimPolicy: Delete
allowVolumeExpansion: true
parameters:
  poolid: pool-00010003
```

### Persistent Volume Claim (PVC)

Zadara supports following `accessModes`:

| NAS | Block |
|-----|-------|
| `ReadWriteOnce` | `ReadWriteOnce` |
| `ReadOnlyMany` | `ReadOnlyMany` |
| `ReadWriteMany` | `ReadWriteMany`* |

Note: when using Block Volumes in ReadWriteMany mode,
it's user responsibility to ensure data consistency for multiple concurrent readers and writers
(e.g. using distributed filesystem like HDFS, GFS, etc.).

### Notes

#### Pods using block devices
Default security parameters do not allow `mount` inside a pod.
To add ability to mount a filesystem residing on a block device,
add following parameters to container configuration:

      securityContext:
        capabilities:
          add: ["SYS_ADMIN"]

Please, do not use `privileged: true`: because of a [bug in Docker](https://bugzilla.redhat.com/show_bug.cgi?id=1614734),
block device won't appear at requested `devicePath`.

___

#### Extended configuration

Zadara-CSI plugin supports fine-grained configuration via config file.
Config keys are case-insensitive.

Changes in config file (`/etc/csi/zadara-csi-config.yaml` by default) are monitored and updated live.

| variable | default | description |
|----------|---------|-------------|
| `vpsa.request-timeout-sec`    | 180   | VPSA Requests timeout in seconds. See http://vpsa-api.zadarastorage.com/#timeouts
| `plugin.default-volume-size-gib` | 100   | Volume size [GiB] used when no `storage` specified in `PersistentVolumeClaim`
| `plugin.log.level`              | info  | Verbosity level for plugin logs. Allowed values: `panic`, `fatal`, `error`, `warn` or `warning`, `info`, `debug`

Example config (using YAML, JSON is also supported):
```
vpsa:
  request-timeout-sec: 180
plugin:
  default-volume-size-gib: 100
  log:
    level: "debug"
```

<!--- end -->
