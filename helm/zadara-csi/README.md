<!--- This file is auto-generated. Do not edit. -->

## Description
   The Zadara VPSA CSI provider implements an interface between the Container Storage Interface (CSI)
   and Zadara VPSA Storage Array & VPSA All-Flash, for a dynamic provisioning of persistent Block and File volumes.


## Prerequisites

- Supported distributions:
  - Ubuntu 18.04 and later
  - RHEL 7.X
  - Amazon Linux

- Create at least one Storage Pool on VPSA.

- iSCSI initiator tools must be installed on K8s nodes:

    `apt-get install open-iscsi` on Ubuntu and other Debian-based

    `yum install iscsi-initiator-utils` on RedHat-based distribution

    Alternatively, you can run `./assets/prepare_node.sh -p`, to install one of the above for your Linux distribution.

- IQN (iSCSI qualified name, defined in `/etc/iscsi/initiatorname.iscsi`) *must be unique* for each Node.
If you change IQN, restart iSCSI service, using `systemctl restart iscsid`

### Feature gates
For some CSI features, following
[feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)
must be enabled:

| Feature                       | Feature gate                   |  Available since     | Enabled by default since |
|-------------------------------|--------------------------------| ---------------------| -------------------------|
| Clone Volume                  | `VolumePVCDataSource`          | K8s 1.15             | K8s 1.16
| Restore Volume from Snapshot  | `VolumeSnapshotDataSource`     | K8s 1.12             | -
| Expand Volume                 | `ExpandCSIVolumes` <br> `ExpandInUsePersistentVolumes` | K8s 1.14 <br> K8s 1.11 | K8s 1.16 <br> K8s 1.15

#### Enabling feature gates example

_Note: the mechanism for enabling feature gates may differ between K8s versions._

In general, feature gates must be added to `kubelet` and `kube-apiserver` command-line arguments.
To verify, use `ps -aux | grep -e kubelet -e kube-apiserver | grep feature-gates`.

##### Mainline Kubernetes
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

##### Canonical microk8s

Edit `/var/snap/microk8s/current/args/kubelet` and `/var/snap/microk8s/current/args/kube-apiserver`.


### Node iSCSI Connectivity

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


## Deploying zadara-csi plugin using Helm charts

Currently Helm charts are only available locally, as part of this repository.

1. Copy `helm` directory from this repository to your current working directory.

2. Edit or create values.yaml and set CSI driver version and VPSA credentials.
    ```yaml
    image:
      repository: zadara/csi-driver
      tag: 0.14.1
      pullPolicy: IfNotPresent
    vpsa:
      url: "example.zadaravpsa.com"
      https: true
      token: "ABCD1234DEFG5678-123"
    plugin:
      provisioner: csi.zadara.com
      configDir: "/etc/csi"
      configName: "zadara-csi-config.yaml"
      iscsiMode: "rootfs"
    labels:
      stage: "production"
    ```
      If you intend to deploy multiple Zadara-CSI instances on the same cluster, set also `plugin.provisioner`
      (this is the same `provisioner` name you will use in StorageClass definition)
      to be unique for each instance. Some name describing underlying VPSA, like `all-flash.csi.zadara.com`,
      or `us-east.csi.zadara.com` will be a good choice.

3. To deploy, run:
    ```
    helm install helm/zadara-csi
    ```
   or with a different YAML for values, e.g. `my_values.yaml`:
   ```
   helm install -f my_values.yaml helm/zadara-csi
   ```

   You can verify resulting YAML files by adding `--dry-run --debug` options to above commands.

4. To verify:
   ```
   helm list
   ```

---

### Values explained

| key                   | description |
|-----------------------|-------------|
  `image.repository`    | image name on DockerHub
  `image.tag`           | image version on DockerHub
  `image.pullPolicy`    | `pullPolicy` of the image https://kubernetes.io/docs/concepts/containers/images/#updating-images
  `vpsa.url`            |  url or IP of VPSA provisioning Volumes, without `http://` or `https://` prefix
  `vpsa.https`          |  whether to use HTTPS or HTTP to access VPSA
  `vpsa.token`          |  token to access VPSA, e.g `ABCD1234DEFG5678-123`
  `plugin.provisioner`  |  the name of CSI plugin, for use in StorageClass, e.g. `us-west.csi.zadara.com` or `on-prem.csi.zadara.com`
  `plugin.configDir`    |  directory on host FS, where the plugin will look for config, or create one if doesn't exist
  `plugin.configName`   |  name of dynamic config
  `plugin.iscsiMode`    |  defines how the plugin will run `iscsiadm` commands on host. Allowed values: `rootfs` or `client-server`.
  `labels`              |  labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary `key: "value"` pairs

For more info about `plugin.iscsiMode` see Node iSCSI Connectivity section.

## Configuration

### Storage Class

| parameter | description | required  | examples |
|-----------|-------------|-----------|----------|
| `provisioner`       |  Identity of Zadara-CSI plugin. Important when you have multiple plugin instances | Yes | `all-flash.csi.zadara.com`, `us-west.csi.zadara.com` |
| `parameters.poolid` |  Id of a Storage Pool to provision volumes from | If VPSA has only 1 Storage Pool - can be omitted.<br> Otherwise - required. | `pool-00000001` |

If you are not sure what `provisioner` should be, it's value can be obtained after plugin deployment using:
- `kubectl get csidrivers.storage.k8s.io -l publisher=zadara -o yaml`.
  Look for label such as `provisioner: on-prem.csi.zadara.com`
- `helm status <release name>` will show an example of `StorageClass` with `provisioner` field.

Example:

```yaml
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


### Extended configuration

Zadara-CSI plugin supports fine-grained configuration via config file.
Config keys are case-insensitive.

Changes in config file (`/etc/csi/zadara-csi-config.yaml` by default) are monitored and updated live.

| variable | default | description |
|----------|---------|-------------|
| `vpsa.request-timeout-sec`       | 180   | VPSA Requests timeout in seconds. See http://vpsa-api.zadarastorage.com/#timeouts
| `plugin.default-volume-size-gib` | 100   | Volume size [GiB] used when no `storage` specified in `PersistentVolumeClaim`
| `plugin.log.level`               | info  | Verbosity level for plugin logs. Allowed values: `panic`, `fatal`, `error`, `warn` or `warning`, `info`, `debug`

Example config:
```yaml
vpsa:
  request-timeout-sec: 180
plugin:
  default-volume-size-gib: 100
  log:
    level: "debug"
```

### Notes

##### Pods using block devices
Default security parameters do not allow `mount` inside a pod.
To add ability to mount a filesystem residing on a block device,
add following parameters to container configuration:
```yaml
  securityContext:
    capabilities:
      add: ["SYS_ADMIN"]
```
Please, do not use `privileged: true`: because of a [bug in Docker](https://bugzilla.redhat.com/show_bug.cgi?id=1614734),
block device won't appear at requested `devicePath`.

