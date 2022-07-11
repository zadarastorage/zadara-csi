# Description

The Zadara VPSA CSI provider implements an interface between the Container Storage Interface (CSI)
and Zadara VPSA Storage Array & VPSA All-Flash, for a dynamic provisioning of persistent Block and File volumes.

## Versioning

- `release` branch (the default) and tags `release-v[version]` refer to stable versions.
- `master` contains the latest changes, some of which may be still not fully tested.

## 2.0 Release

Zadara CSI Driver 2.0 introduces a major change in management of underlying VPSAs and nested resources. Now a single CSI
driver supports multiple VPSAs. Check out the [Changelog](../changelogs/CHANGELOG-v2.md) for more details.

All user guides are updated with examples for the new functionality.

🛈 CSI 1._x.y_ users are required to perform a [migration](migration.md).

### Volume Service Controller (VSC)

A new component, built-in in the CSI Driver deployment.

It introduces a notion of **VSC Storage Class**: a set of VPSAs used for Volume provisioning.

- VPSAs can be added or removed dynamically.
- VSC decides which VPSA in will be used for Volume provisioning.

### Custom Resources

Volume Service Controller (VSC) entities are persisted
as [Kubernetes Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/).

Configuration of CSI driver is done via _VSCStorageClass_ and _VPSA_ Custom
Resources ([full reference](custom_resources_generated.md)).

## Commonly used abbreviations

- `VSC`: Volume Service Controller: a new component, built-in in the CSI Driver deployment. It aggregates multiple VPSAs and takes Volume scheduling decisions.
- `PVC`: [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#introduction)
- `PV`: [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#introduction)
- `SC`: [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- `CRD`: [Custom Resource Definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)

---

# Plugin deployment

- [Migration from CSI 1.x.y](migration.md)
- [Get the repository](get_repo.md)
- [Prerequisites](prerequisites.md)
- [Deploying Zadara CSI Helm Chart](helm_deploy.md). *Looking for `helm install`?*
- [Quickstart tutorial](quickstart.md)

Advanced topics:

- [Using custom image registry](custom_image_registry.md)
- [Adding custom trusted certificates](custom_certificates.md)
- [Troubleshooting tips](troubleshooting.md)
- [Hack scripts](hack_scripts.md) to help with management and debugging

# Configuration

- [VSC configuration](configuring_vsc.md) Adding VSC StorageClasses and VPSAs.
- [Kubernetes Storage configuration](configuring_storage.md). StorageClasses and PersistentVolumeClaims.
- [Extended configuration (ConfigMap)](configmap.md)

# Usage examples and tutorials

- [Example workload for NAS or Block volumes](example_workload.md)
- [Creating Snapshots and Clones](example_snapshots.md)
- [Expand Persistent Volume Claim](example_volume_expand.md)
- [Using pre-provisioning Volumes](example_preprovisioning.md) import existing VPSA Volumes into k8s.

# Architecture and design

- [Driver Components](components.md)
- [How it works](how_it_works.md)

# References

- [Volume Service Controller (VSC) Custom Resources](custom_resources_generated.md)
- [Kubernetes Snapshots API](snapshots_api_generated.md)
