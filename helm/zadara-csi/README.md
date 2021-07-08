<!--- This file is auto-generated. Do not edit. -->

## Description
The Zadara VPSA CSI provider implements an interface between the Container Storage Interface (CSI)
and Zadara VPSA Storage Array & VPSA All-Flash, for a dynamic provisioning of persistent Block and File volumes.


## Prerequisites

### Nodes requirements

#### Supported Linux distributions:
- Ubuntu 18.04 and later
- RHEL 7.X
- CentOS 7.X
- Amazon Linux

#### iSCSI initiator tools

- iSCSI initiator tools must be installed and running on K8s nodes.
    This must be done before installing CSI driver.

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

- IQN (iSCSI qualified name, defined in `/etc/iscsi/initiatorname.iscsi`) *must be unique* for each Node
    (you may have duplicate IQNs if you install iSCSI packages and then clone VM image for each K8s Node).
    If you change IQN, restart iSCSI service, using `systemctl restart iscsid`

#### Node iSCSI Connectivity

The plugin requires to be able to manage iSCSI connections _on host_ for proper functioning
(block volumes support and automatic Server creation on VPSA).
You can choose between 2 different approaches:

- `rootfs` (default): running iscsiadm directly on host
- `client-server`: using `run-on-host-server` service

###### Running iscsiadm directly on host (default)

This does not require any preparations to be done on Nodes (assuming you already have iSCSI initiator packages installed).

Node plugin container will run with bind mounted host root filesystem.


###### Installing run-on-host-server service
The plugin will communicate with host `iscsiadm` via Unix socket, exposed to Node plugin container.
This requires `run-on-host-server` service installed on host.

1. Copy `assets` from this repository to your working directory on a Node.

2. Run the run-on-host-server service installer
    ```
    ./assets/prepare_node.sh
    ```
    This will install `run-on-host-server` binary (currently available only for x64_64 systems) from `assets`
    and enable it as a system service (use `./assets/prepare_node.sh -u` to uninstall).

### VPSA Requirements

- Create at least one Storage Pool.
- Make sure you have connectivity between your cluster and the VPSA (using `ping` or [REST API](http://vpsa-api.zadarastorage.com/)).

### Cluster Requirements

#### Helm

CSI driver, Snapshot controller and usage examples are provided as Helm Charts.
[Helm 3](https://helm.sh/docs/intro/install/) is required.

#### Snapshot Controller
CSI Snapshots support requires installing Snapshot Controller and snapshots CRDs.
*If you do not intend to use CSI snapshots, you may skip this step.*

Both Snapshot Controller and CRDs are cluster-global and should be installed *once* for any number of CSI drivers.
In managed K8s clusters Snapshot Controller can be already present.

You can read more about new [Volume Snapshot API](https://kubernetes.io/blog/2020/12/10/kubernetes-1.20-volume-snapshot-moves-to-ga/)
and [Snapshot Controller](https://kubernetes-csi.github.io/docs/snapshot-controller.html#snapshot-controller) in K8s docs.

- Check whether you already have snapshots CRDs:
    ```
    $ kubectl api-resources --api-group=snapshot.storage.k8s.io
    NAME                     SHORTNAMES   APIVERSION                   NAMESPACED   KIND
    volumesnapshotclasses                 snapshot.storage.k8s.io/v1   false        VolumeSnapshotClass
    volumesnapshotcontents                snapshot.storage.k8s.io/v1   false        VolumeSnapshotContent
    volumesnapshots                       snapshot.storage.k8s.io/v1   true         VolumeSnapshot
    ```
    In this example the CRDs are installed. API Version can be `v1`, `v1beta1` or both.

    There's no universal way to check whether Snapshot Controller is running on your cluster.
    Yet typically, if the CRDs are present, then the controller is running as well.


- If CRDs are *not installed*, proceed to the following steps.


- Install Snapshot Controller and CRDs.

    For your convenience, we provide Helm Charts,
    based on [official K8s-CSI YAMLs](https://github.com/kubernetes-csi/external-snapshotter)

    - snapshots-v1 chart for K8s >=1.20
    - snapshots-v1beta1 chart for older versions
    We strongly advise not to use `v1beta1` with K8s 1.20+.

    Example for `v1`:
    ```
    $ helm install csi-snapshots-v1 ./helm/snapshots-v1

    NAME: csi-snapshots-v1
    LAST DEPLOYED: Mon Jul  5 16:45:23 2021
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Thank you for installing snapshots-v1-4.1.1-v1!

    ##############################################################################
    ####   Verify CRDs installation:                                          ####
    ##############################################################################

    $ kubectl api-resources --api-group=snapshot.storage.k8s.io
    NAME                     SHORTNAMES   APIVERSION                   NAMESPACED   KIND
    volumesnapshotclasses                 snapshot.storage.k8s.io/v1   false        VolumeSnapshotClass
    volumesnapshotcontents                snapshot.storage.k8s.io/v1   false        VolumeSnapshotContent
    volumesnapshots                       snapshot.storage.k8s.io/v1   true         VolumeSnapshot

    ##############################################################################
    ####   Verify Snapshot Controller:                                        ####
    ##############################################################################

    $ kubectl get pods -n kube-system -l app=snapshot-controller
    NAME                                  READY   STATUS    RESTARTS   AGE
    snapshot-controller-7485bfc5f-mqf79   1/1     Running   0          69s
    ```

- Optionally, you can install [Snapshot validation webhook](https://github.com/kubernetes/enhancements/tree/master/keps/sig-storage/1900-volume-snapshot-validation-webhook) (not included in helm charts).

    [Installation instructions and YAMLs](https://github.com/kubernetes-csi/external-snapshotter/tree/master/deploy/kubernetes/webhook-example)
    (OCI image is available at `k8s.gcr.io/sig-storage/snapshot-validation-webhook`)


## Deploying zadara-csi plugin using Helm charts

Currently, Helm charts are only available locally, in `helm/` subdirectory of this repository.

All examples assume the repository root as current working directory:
```
$ ls -F
CHANGELOG.md  assets/  deploy/  docs/  hack/  helm/
```

**Configure**

Create `my_values.yaml`, following values.yaml, and other optional parameters.
It is best not to edit values.yaml inside the chart. Instead, override default values with `-f FILE.yaml` or `--set PATH.TO.KEY=VALUE`.
- If you intend to deploy multiple Zadara-CSI instances on the same cluster, set also `plugin.provisioner`
(this is the same `provisioner` name you will use in StorageClass definition)
to be unique for each instance. Some name describing underlying VPSA, like `all-flash.csi.zadara.com`,
or `us-east.csi.zadara.com` will be a good choice.

- Note also `snapshots.apiVersion`, and choose a version that matches Snapshot Controller,    or set it to `auto`.

Minimal `my_values.yaml` would look like this:
```yaml
vpsa:
  url: "example.zadaravpsa.com"
  useTLS: true
  verifyTLS: true
  token: "FAKETOKEN1234567-123"
plugin:
  provisioner: csi.zadara.com
snapshots:
   apiVersion: v1
```

Full reference for `values.yaml` is here
**Deploy**

Specify release name, e.g. `zadara-csi`, or use `--generate-name` flag:
```
# use either one:
$ helm install zadara-csi      -f my_values.yaml ./helm/zadara-csi
$ helm install --generate-name -f my_values.yaml ./helm/zadara-csi
```

You can verify resulting YAML files by adding `--dry-run --debug` options to above commands.


**Verify installation**

Helm Chart status:
```
$ helm list
NAME             NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
zadara-csi       default         1               2021-07-04 11:29:08.023368123 +0300 IDT deployed        zadara-csi-2.0.0        1.3.2

$ helm status zadara-csi
NAME: zadara-csi
LAST DEPLOYED: Sun Jul  4 11:29:08 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
##############################################################################
####   Successfully installed Zadara-CSI                                  ####
##############################################################################
Thank you for installing zadara-csi!

# Verify installation:
kubectl get pods -n kube-system -l provisioner=csi.zadara.com

##############################################################################
####   Example: Create a NAS volume on your VPSA                          ####
##############################################################################
...
```

Pods status
```
$ kubectl get pods -n kube-system -l provisioner=csi.zadara.com
NAME                                                READY   STATUS      RESTARTS   AGE
zadara-csi-csi-autoexpand-sync-27091180-mk5hv       0/1     Completed   0          2m46s
zadara-csi-csi-zadara-controller-84c8884f5c-79v26   6/6     Running     0          6m3s
zadara-csi-csi-zadara-node-58mb6                    3/3     Running     0          6m3s
```

- `node` pods belong to a DaemonSet, meaning that one Pod will be created for each K8s Node
- `autoexpand-sync` pod belongs to a CronJob, and will appear only if `plugin.autoExpandSupport` is enabled.
- When all `node` pods have started, on VPSA side a *Server will be created for each K8s Node*.

**Uninstall**

Replace `zadara-csi` with your release name, as appears in `helm list`.
```
$ helm uninstall zadara-csi
```

Uninstalling CSI driver does not affect VPSA Volumes or K8s PVCs, Storage Classes, etc.

---

### Values explained

| key                   | description |
|-----------------------|-------------|
`namespace`           | namespace where all CSI pods will run
`image.repository`    | image name on DockerHub
`image.tag`           | image version on DockerHub
`image.pullPolicy`    | `pullPolicy` of the image https://kubernetes.io/docs/concepts/containers/images/#updating-images
`vpsa.url`            |  url or IP of VPSA provisioning Volumes, without `http://` or `https://` prefix
`vpsa.useTLS`         |  whether to use TLS (HTTPS) to access VPSA
`vpsa.verifyTLS`      |  whether to verify TLS certificate when using HTTPS
`vpsa.token`          |  token to access VPSA, e.g `FAKETOKEN1234567-123`
`plugin.provisioner`  |  the name of CSI plugin, for use in StorageClass, e.g. `us-west.csi.zadara.com` or `on-prem.csi.zadara.com`
`plugin.configDir`    |  directory on host FS, where the plugin will look for config, or create one if doesn't exist
`plugin.configName`   |  name of dynamic config
`plugin.iscsiMode`*    |  defines how the plugin will run `iscsiadm` commands on host. Allowed values: `rootfs` or `client-server`.
`plugin.healthzPort`  |  healthzPort is an TCP ports for listening for HTTP requests of liveness probes, needs to be _unique for each plugin instance_ in a cluster.
`plugin.autoExpandSupport`**  |  support for VPSA Volumes [auto-expand feature](http://guides.zadarastorage.com/release-notes/1908/whats-new.html#volume-auto-expand). Set to `false` to disable.
`plugin.autoExpandSupport.schedule`  |  schedule for periodical sync of capacity between VPSA Volumes with auto-expand enabled and Persistent Volume Claims.
`snapshots.apiVersion`*** | apiVersion for CSI Snapshots: `v1beta1`, `v1` (requires K8s >=1.20) or `auto`
`labels`              |  labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary `key: "value"` pairs
`customTrustedCertificates` | additional custom trusted certificates to install in CSI pods`customTrustedCertificates.existingSecret` | name of an existing secret from the same namespace, each key containing a pem-encoded certificate
`customTrustedCertificates.plainText` | create a new secret with the following contents

\* For more info about `plugin.iscsiMode` see Node iSCSI Connectivity section.
\** To enable auto-expand for CSI Volumes, you need to configure Storage Class `parameters.volumeOptions`.Auto-expand requires VPSA version 19.08 or higher. When `plugin.autoExpandSupport` is enabled,
periodical sync will be handled by a CronJob, running in the same namespace as CSI driver.

\*** `auto` option: if CSI Snapshots CRDs are installed, the chart will use API version of CRDs.
If CRDs are not installed, the chart will use `v1` for K8s 1.20+, and `v1beta1` otherwise.

### Adding trusted certificates

CSI Driver can be configured to use HTTPS with custom certificate (e.g. self-signed).

You can either reference a Secret, or provide a certificate directly in `values.yaml` (a Secret will be created automatically).

#### Using existing Secret

1. Create a Secret with certificates to install. Use the same namespace (typically `kube-system`) where the CSI driver is deployed.
   A Secret may contain any number of certificates.
   The following command will create a Secret named `custom-ca-certs` in namespace `kube-system`, containing certificates from files `CA1.crt` and `CA2.crt`.
```
kubectl create secret -n kube-system generic custom-ca-certs --from-file=CA1.crt --from-file=CA2.crt
```

2. Set `customTrustedCertificates.existingSecret` in `values.yaml`
```
customTrustedCertificates:
  existingSecret: custom-ca-certs
```

#### Provide a certificate directly

Paste `.crt` contents into `customTrustedCertificates.plainText` in  `values.yaml` (contents omitted).

```
customTrustedCertificates:
  plainText: |-
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
```

A Secret will be created during Chart installation.


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
$ kubectl get cm -n kube-system -l app=zadara-csi  # get ConfigMap name
NAME                          DATA   AGE
gilded-chimp-csi-config-map   1      7m34s
$ kubectl edit cm -n kube-system gilded-chimp-csi-config-map
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

