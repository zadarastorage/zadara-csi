

## Description
The Zadara VPSA CSI provider implements an interface between the Container Storage Interface (CSI)
and Zadara VPSA Storage Array & VPSA All-Flash, for a dynamic provisioning of persistent Block and File volumes.


### Versioning

- `release` branch (the default) and tags `release-v[version]` refer to stable versions.
- `master` contains the latest changes, some of which may be still not fully tested.

## Table of contents

- [Prerequisites](#prerequisites)
    - [Nodes requirements](#nodes-requirements)
        - [Supported Linux distributions](#supported-linux-distributions)
        - [iSCSI initiator tools](#iscsi-initiator-tools)
        - [Node iSCSI Connectivity](#node-iscsi-connectivity)
            - [Running iscsiadm directly on host (default)](#running-iscsiadm-directly-on-host-default)
            - [Installing run-on-host-server service](#installing-run-on-host-server-service)
    - [VPSA Requirements](#vpsa-requirements)
    - [Cluster Requirements](#cluster-requirements)
        - [Helm](#helm)
        - [Snapshot Controller](#snapshot-controller)
- [Plugin deployment](#plugin-deployment)
    - [Troubleshooting](#troubleshooting)
- [Configuration](#configuration)
    - [Storage Class](#storage-class)
    - [Persistent Volume Claim (PVC)](#persistent-volume-claim-pvc)
    - [Extended configuration](#extended-configuration)
    - [Notes](#notes)
        - [Pods using block devices](#pods-using-block-devices)
- [Usage Examples](#usage-examples)


## Prerequisites

### Nodes requirements

#### Supported Linux distributions
- Ubuntu 18.04 and later
- RHEL 7, 8
- CentOS 7, 8
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

#### Kubernetes versions

Minimal supported K8s version: 1.18

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

- Optional step: use custom image registry

    See [instructions for configuring Helm Chart to use local image registry](./local-registry.md)

- Install Snapshot Controller and CRDs.

    For your convenience, we provide Helm Charts,
    based on [official K8s-CSI YAMLs](https://github.com/kubernetes-csi/external-snapshotter)

    - [snapshots-v1 chart](#helm/snapshots-v1) for K8s >=1.20

    - [snapshots-v1beta1 chart](#helm/snapshots-v1beta1) for older versions

    We strongly advise not to use `v1beta1` with K8s 1.20+.

    Example for `v1`:
    ```
    $ helm install csi-snapshots-v1 zadara-csi-helm/snapshots-v1

    NAME: csi-snapshots-v1
    LAST DEPLOYED: Mon Jul  5 16:45:23 2021
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Thank you for installing snapshots-v1-4.1.1+zadara.1!

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


---

## Plugin deployment

[Deploy Zadara CSI using Helm Chart](deploy-helm.md)

[Using custom image registry](local-registry.md)

After successful deployment you will see a Server created on your VPSA for each active K8s node.

Server records and volumes attachments are managed dynamically by the CSI provider, do not change or delete them manually.
In case a manual configuration cleanup is required, disconnect the active iSCSI sessions to the VPSA before spinning up a new instance of the provider.

### Troubleshooting

[Troubleshooting guide](troubleshooting.md)

The most common problems:
- Invalid VPSA credentials (url, token).
- VPSA is not accessible (network problems)
- iSCSI is not configured properly:
    - initiator utils (e.g. `open-iscsi`) are not installed on K8s nodes
    - `run-on-host-server` service is not installed  (when using `client-server` iSCSI mode), or is disabled
    - IQN in `/etc/initiatorname.iscsi` is not unique for each node


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

Read more about StorageClass configuration in [Usage Examples](examples.md#configuring-volume-options)

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


___

## Usage Examples

We provide [examples and instruction for NAS and Block volumes](examples.md).
These include:
- example application with a convenient Helm chart
- dynamic Volume provisioning
- creating Snapshots
- cloning Snapshots
- cloning Persistent Volume Claims
