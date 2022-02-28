# How it works

What happens behind the scenes, and what to expect.

We mark in *italic* terms that are referring to CSI (to be more specific, VSC) *custom resources*
(i.e, k8s representation of a physical resource), where this distinction is important.

## Startup

CSI driver will start periodic health check for all *VSC Storage Classes* and their members (*VPSAs*). Of course, this
health check will do nothing, if there are no *VPSAs*.

CSI Node component will create a *Node*, containing information of k8s Node. *Node* custom resource is used as a
template for creating Server records on VPSA.

## Continuous operation

Even when no user-triggered actions are in progress, CSI driver periodically synchronizes status of resources. This
includes:

- VPSA health, capacity, objects counters (Volumes, Snapshots, etc)
- *VSC Storage Class* status (aggregation of member *VPSA* statuses)

## Create VSC Storage Class custom resource

*VSC Storage Class* can be created without any VPSAs. Empty *VSC Storage Class* should be in `Ready` state.

## Create VPSA custom resource

*VPSA* is added as a member of *VSC Storage Class*, according to `VSCStorageClassName` field in *VPSA* Spec.

Then CSI driver will proceed with the following steps:

- check whether the VPSA fits CSI requirements. If not - the VPSA will move to `Incompatible` state
- check VPSA settings and update them if needed (`Configuring` state)
- import existing VPSA Volumes and Snapshots into K8s (`Importing` state)
- when finished, *VPSA* will move to `Ready` state, and can start provisioning *Volumes*.

If at any point the CSI driver fails to call VPSA REST API (e.g, network issues, invalid credentials, bad certificates),
*VPSA* will move to `Unreachable` state.

## Create PVC

Creating Persistent Volume Claim (PVC) will trigger Volume creation on VPSA.

For StatefulSets, PVCs are created automatically before Pods start.

First, CSI driver will choose a suitable VPSA for Volume provisioning, among all members of *VSC Storage Class*. At
least one VPSA in *VSC Storage Class* must be healthy and with enough available capacity.

Upon success, *Volume* will move to `Ready` state, and PVC will appear as `Bound`.

Internally, CSI Controller component creates *Volume* custom resource to keep track of Volume location (VPSA, Pool) and
status.

## Create Pod consuming PVC

To make Volume available in a container, the following steps are performed:

- CSI Controller component creates a Server record on VPSA for the Node, where the Pod is scheduled
- CSI Controller component attaches Volume to a Node by attaching it to the corresponding Server on
  VPSA (`ControllerPublishVolume` in CSI spec)
- CSI Node component mounts the Volume on a Node (`NodeStageVolume` in CSI spec)
    - For block volumes, iSCSI connection is established from the Node to the VPSA, before the Volume is mounted.
- CSI Node component mounts the Volume at the requested path in the container (`NodePublishVolume` in CSI spec).

Failure at any of those steps will cause the Pod to stuck in `Pending` state.

Internally, CSI Controller component creates *VolumeAttachment* custom resource to keep track of attachment status (Node
ID, Server on VPSA, iSCSI connectivity)

## Uninstalling CSI Driver

Uninstalling CSI Driver does not delete any CRDs or other managed resources (Volumes, VolumeAttachments, VPSAs, etc).
I/O on existing volumes also continues uninterrupted.
This means that it is safe to reinstall or upgrade CSI driver (e.g, to change some of the `values.yaml`).

However, if you intend to delete managed resources, you should do so before uninstalling the driver.
The reason is that most of the resources have a [finalizer](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/)
that prevents accidental deletion of a custom resource without the necessary cleanup by CSI and VSC.
For example, VSC needs to delete Volumes on VPSA when you delete a PVC or a Volume custom resource,
if this succeeds - the finalizer is removed, and the resource is deleted from k8s.

Some resources are not deleted automatically:
- VSCNode (one for each k8s Node)
- Secret with the encryption key for VPSA secrets (token, CHAP)
