## v2.0.0

### Main features

- **Multiple VPSA support** in one CSI driver
- VPSAs are managed using Kubernetes Custom Resources
- Custom resources report Events (e.g. if VPSA is failed, this will be posted as k8s Event, and also shown
  in `kubectl describe vpsa`).
- Notion of VSC (Volume Service Controller) Storage Class: a pool of VPSAs used to provision volumes.

### Improvements

- Fully automatic management of VPSA Servers and iSCSI sessions
- iSCSI packages are not required to be installed on Nodes if Block volumes are not used
- Option for JSON logs (e.g, for ELK and other log collectors)
- Support for scaling Controller and Stonith deployments, with leader election
- Restructured documentation
- Updated usage examples with convenient `example-workload` Chart (previously `one-pod-one-pool`) for I/O test
- Support for mount options for NAS volumes

### Fixes

- Fix Helm Chart compatibility with k8s pre-release versions (like `1.21.0-pre1+deadbeef`)
- In some cases, block volumes were not unmounted properly, leaving pods in `Terminating` state.
- Fixed issue with failing Helm upgrade due to immutable `selector`

### Removals

- support for deprecated `v1alpha1` CSI snapshots API
- support for propagating volume expansion _from_ VPSA _to_ K8s (i.e, the opposite of updating PVC size in K8s, which
  expands a VPSA volume)
- `run-on-host` iSCSI mode
- support for multiple instances of CSI driver

## v2.0.1

Most of the changes are focused on improving migration from CSI v1 to v2.
No significant changes in the driver itself.

### Enhancements

- CSI v2 will attempt to clean up unused iSCSI sessions that might remain from CSI v1.
- `k8snap` helper script is [now available in bash](../hack/k8snap.sh), for environments that do not have Python
  installed.
- Support existing StorageClass in [example-workload Chart](../docs/example_workload.md).
- Migration tool now supports multiple CSI v1 instances.

### Documentation

- Improved [documentation for CSI v1 to v2 migration](../docs/migration.md).

### Changes

### Bug Fixes

## v2.1.0

### Enhancements

- Add new [ExternalVolume](../docs/custom_resources_generated.md#externalvolume)
  Custom Resource for importing existing (pre-provisioned) VPSA Volumes into k8s.

### Documentation

- Add instructions for [Using pre-provisioning Volumes](../docs/example_preprovisioning.md)

### Changes

- `kubectl get volumes -o wide` will show VPSA Volume ID.
  Note: Helm does not update CRDs upon `helm upgrade`.
  If the changes are not applied, update CRDs manually:
  ```
  $ kubectl apply --recursive -f ./deploy/helm/zadara-csi/crds/
  ```
  Alternatively, using GitHub instead of local files:
  ```
  $ kubectl apply -f https://raw.githubusercontent.com/zadarastorage/zadara-csi/release/deploy/helm/zadara-csi/crds/storage.zadara.com_volumes.yaml
  $ kubectl apply -f https://raw.githubusercontent.com/zadarastorage/zadara-csi/release/deploy/helm/zadara-csi/crds/storage.zadara.com_externalvolumes.yaml
  ```

### Bug Fixes

- Fixed issue with renaming VPSA Volumes (updating displayName in Volume custom resource).
- Fixed custom trusted certificate issue in [CSI v1 to v2 migration](../docs/migration.md).
