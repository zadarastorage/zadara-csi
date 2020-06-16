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

- iSCSI initiator tools must be installed and running on K8s nodes:

    On Ubuntu and other Debian-based:
    ```
    apt-get install open-iscsi
    systemctl enable iscsid
    systemctl start iscsid
    ```

    On RedHat-based distribution:
    ```
    yum install iscsi-initiator-utils
    systemctl enable iscsid
    systemctl start iscsid
    systemctl enable iscsi
    systemctl start iscsi
    ```

    Alternatively, you can run `./assets/prepare_node.sh -p`, to install one of the above for your Linux distribution.

- IQN (iSCSI qualified name, defined in `/etc/iscsi/initiatorname.iscsi`) *must be unique* for each Node.
If you change IQN, restart iSCSI service, using `systemctl restart iscsid`

### Feature gates
K8s 1.17+ users can skip this section.

For some CSI features, following
[feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)
must be enabled:

| Feature                       | Feature gate                   |  Available since     | Enabled by default since |
|-------------------------------|--------------------------------| ---------------------| -------------------------|
| Clone Volume                  | `VolumePVCDataSource`          | K8s 1.15             | K8s 1.16
| Restore Volume from Snapshot  | `VolumeSnapshotDataSource`     | K8s 1.12             | K8s 1.17
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
      tag: 1.2.5
      pullPolicy: IfNotPresent
    vpsa:
      url: "example.zadaravpsa.com"
      https: true
      token: "FAKETOKEN1234567-123"
    plugin:
      provisioner: csi.zadara.com
      iscsiMode: "rootfs"
      healthzPort: 9808
      autoExpandSupport:
        schedule: "*/10 * * * *"
    labels:
      stage: "production"
    ```
      If you intend to deploy multiple Zadara-CSI instances on the same cluster, set also `plugin.provisioner`
      (this is the same `provisioner` name you will use in StorageClass definition)
      to be unique for each instance. Some name describing underlying VPSA, like `all-flash.csi.zadara.com`,
      or `us-east.csi.zadara.com` will be a good choice.

3. Deploy

   - Helm 2:
       ```
       $ helm install helm/zadara-csi
       ```
       or with a different YAML for values, e.g. `my_values.yaml`:
       ```
       $ helm install -f my_values.yaml helm/zadara-csi
       ```

   - Helm 3 users need to specify release name, e.g. `zadara-csi-driver`, or use `--generate-name` flag:
       ```
       $ helm install zadara-csi-driver helm/zadara-csi
       $ helm install --generate-name   helm/zadara-csi

       $ helm install zadara-csi-driver -f my_values.yaml helm/zadara-csi
       $ helm install --generate-name   -f my_values.yaml helm/zadara-csi
       ```

   You can verify resulting YAML files by adding `--dry-run --debug` options to above commands.

4. Verify installation
   ```
   $ helm list
   NAME               NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
   zadara-csi-driver  default         1               2020-02-03 12:42:56.468379418 +0200 IST deployed        zadara-csi-1.1.0        1.2.0

   $ helm status zadara-csi-driver
   NAME: zadara-csi-driver
   LAST DEPLOYED: Mon Feb  3 12:42:56 2020
   NAMESPACE: default
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   ##############################################################################
   ####   Successfully installed Zadara-CSI                                  ####
   ##############################################################################
   Thank you for installing zadara-csi!
   Your release is named csi-helm-3

   Try following example to create a NAS volume on your VPSA:
   ...
   ```

5. Uninstall

   - Helm 2:
       ```
       $ helm delete zadara-csi-driver
       ```
   - Helm 3:
       ```
       $ helm uninstall zadara-csi-driver
       ```
    Replace `zadara-csi-driver` with your release name, as appears in `helm list`.

---

### Values explained

| key                   | description |
|-----------------------|-------------|
  `image.repository`    | image name on DockerHub
  `image.tag`           | image version on DockerHub
  `image.pullPolicy`    | `pullPolicy` of the image https://kubernetes.io/docs/concepts/containers/images/#updating-images
  `vpsa.url`            |  url or IP of VPSA provisioning Volumes, without `http://` or `https://` prefix
  `vpsa.https`          |  whether to use HTTPS or HTTP to access VPSA
  `vpsa.token`          |  token to access VPSA, e.g `FAKETOKEN1234567-123`
  `plugin.provisioner`  |  the name of CSI plugin, for use in StorageClass, e.g. `us-west.csi.zadara.com` or `on-prem.csi.zadara.com`
  `plugin.configDir`    |  directory on host FS, where the plugin will look for config, or create one if doesn't exist
  `plugin.configName`   |  name of dynamic config
  `plugin.iscsiMode`*    |  defines how the plugin will run `iscsiadm` commands on host. Allowed values: `rootfs` or `client-server`.
  `plugin.healthzPort`  |  healthzPort is an TCP ports for listening for HTTP requests of liveness probes, needs to be _unique for each plugin instance_ in a cluster.
  `plugin.autoExpandSupport`**  |  support for VPSA Volumes [auto-expand feature](http://guides.zadarastorage.com/release-notes/1908/whats-new.html#volume-auto-expand). Set to `false` to disable.
  `plugin.autoExpandSupport.schedule`  |  schedule for periodical sync of capacity between VPSA Volumes with auto-expand enabled and Persistent Volume Claims.
  `labels`              |  labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary `key: "value"` pairs

\* For more info about `plugin.iscsiMode` see Node iSCSI Connectivity section.
\** To enable auto-expand for CSI Volumes, you need to configure Storage Class `parameters.volumeOptions`.    Auto-expand requires VPSA version 19.08 or higher. When `plugin.autoExpandSupport` is enabled,
    periodical sync will be handled by a CronJob, running in the same namespace as CSI driver.


## Configuration

### Storage Class

| parameter | description | required  | examples |
|-----------|-------------|-----------|----------|
| `provisioner`       |  Identity of Zadara-CSI plugin. Important when you have multiple plugin instances | Yes | `all-flash.csi.zadara.com`, `us-west.csi.zadara.com` |
| `parameters.poolid` |  Id of a Storage Pool to provision volumes from | If VPSA has only 1 Storage Pool - can be omitted.<br> Otherwise - required. | `pool-00000001` |
| `parameters.volumeOptions` |  Additional options for creating Volumes, in JSON format. See `POST /api/volumes` documentation in http://vpsa-api.zadarastorage.com/#volumes for the full list*. | No | `'{"nfsanonuid":"65500", "nfsanongid":"65500"}'` |

If you are not sure what `provisioner` should be, it's value can be obtained after plugin deployment using:
- `kubectl get csidrivers.storage.k8s.io -l publisher=zadara -o yaml`.
  Look for label such as `provisioner: on-prem.csi.zadara.com`
- `helm status <release name>` will show an example of `StorageClass` with `provisioner` field.

Notes on `parameters.volumeOptions`:
- some options available in REST API documentation are not supported in StorageClass parameters.
Following parameters are set based on PVC: `name`, `capacity`, `pool`, `block`.
In addition, since CSI driver supports only NFS for NAS volumes, SMB parameters are not supported.

- VPSA Volumes [auto-expand feature](http://guides.zadarastorage.com/release-notes/1908/whats-new.html#volume-auto-expand)
requires an additional configuration to sync VPSA Volumes capacity with Persistent Volume Claims.
This part is explained in plugin deployment instructions.

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
  volumeOptions: '{"nfsanonuid":"65500", "nfsanongid":"65500"}'
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

Zadara-CSI plugin supports fine-grained configuration via ConfigMap. Changes in ConfigMap are monitored and updated live.

To update ConfigMap follow the example below:
```shell script
$ kubectl get cm -n zadara -l app=zadara-csi  # get ConfigMap name
NAME                          DATA   AGE
gilded-chimp-csi-config-map   1      7m34s
$ kubectl edit cm -n zadara gilded-chimp-csi-config-map
```

| variable | default | description |
|----------|---------|-------------|
| `vpsa.requestTimeoutSec`      | 180   | VPSA Requests timeout in seconds. See http://vpsa-api.zadarastorage.com/#timeouts
| `plugin.defaultVolumeSizeGiB` | 100   | Volume size [GiB] used when no `storage` specified in `PersistentVolumeClaim`
| `plugin.logLevel.<tag>`       | info  | Verbosity level for plugin logs. Allowed values: `panic`, `fatal`, `error`, `warn` or `warning`, `info`, `debug`
| `useLogColors`                | false | Use colored output in logs. Does not auto-detect pipes, redirection, or other non-interactive outputs.

Example config:
```yaml
vpsa:
  requestTimeoutSec: 180
plugin:
  defaultVolumeSizeGiB: 100
logLevel:
  general: "info"
  csi: "info"
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

