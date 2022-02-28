# Prerequisites

## Nodes requirements

### Supported Linux distributions
- Ubuntu 18.04 and later
- RHEL 7, 8
- CentOS 7, 8
- Amazon Linux

### Additional requirements for block volumes

If you plan to use CSI Driver with only NAS Volumes, you may skip this section.

<details>
<summary>Click to see requirements</summary>

#### iSCSI initiator tools

- iSCSI initiator tools must be installed and running on all K8s nodes.
    This must be done before installing CSI driver.

    On Ubuntu and other Debian-based:
    ```
    sudo apt-get install open-iscsi
    sudo systemctl enable iscsid
    sudo systemctl start iscsid
    ```

    On RedHat-based distribution:
    ```
    sudo yum install iscsi-initiator-utils
    sudo systemctl enable iscsid
    sudo systemctl start iscsid
    sudo systemctl enable iscsi
    sudo systemctl start iscsi
    ```

- IQN (iSCSI qualified name, defined in `/etc/iscsi/initiatorname.iscsi`) *must be unique* for each Node
    (you may have duplicate IQNs if you install iSCSI packages and then clone VM image for each K8s Node).
    Check out our [troubleshooting tips](troubleshooting.md) to see how this can be fixed.

#### Node iSCSI Connectivity

The plugin requires to be able to manage iSCSI connections _on host_ for block volumes support.

Node container will run with bind-mounted host root filesystem.
This is done automatically, and does not require any preparations.

---
</details>

## VPSA Requirements

- VPSA 20.12-sp2 and later
- *Exactly one* Storage Pool.
- Make sure you have connectivity between your cluster and the VPSA (using `ping` or [REST API](http://vpsa-api.zadarastorage.com/)).

## Cluster Requirements

### Kubernetes versions

Minimal supported K8s version: 1.20

### Helm

CSI driver, Snapshot controller and usage examples are provided as Helm Charts.
[Helm 3](https://helm.sh/docs/intro/install/) is required.

### ⚠ Snapshot Controller ⚠
CSI Snapshots support requires installing Snapshot Controller and snapshots CRDs.
*If you do not intend to use CSI snapshots, you may skip this step.*

<details>
<summary>Click to see instructions</summary>

🛈 To proceed with this guide you will need to [get the repository](get_repo.md), if you have not already done so.

Both Snapshot Controller and CRDs are cluster-global and should be installed *once* for any number of CSI drivers.
In managed K8s clusters Snapshot Controller may be already present.

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

- _Optional step_: use custom image registry

    See [instructions for configuring Helm Chart to use local image registry](./custom_image_registry.md)

- Install Snapshot Controller and CRDs.

    For your convenience, we provide Helm Charts,
    based on [official K8s-CSI YAMLs](https://github.com/kubernetes-csi/external-snapshotter)

    - [snapshots-v1 chart](#helm/snapshots-v1) for K8s 1.20+

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
</details>

## Next steps

[Deploy Zadara CSI Helm Chart](helm_deploy.md). *Looking for `helm install`?*
