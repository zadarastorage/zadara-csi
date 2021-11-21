## v1.3.9

### Enhancements
- Delete VolumeAttachments when `stonith` evacuates Pods.
  This decreases failover time of Pods using RWO volumes.

### Documentation

### Changes

### Bug Fixes

## v1.3.8

### Enhancements

### Documentation

### Changes

### Bug Fixes
- Fix arguments parsing in `stonith` container

## v1.3.7

Faster failover for stateful pods.

### Enhancements
- Additional `stonith` component to evacuate StatefulSet Pods from unreachable Nodes, for faster failover.
- Re-add support for `v1alpha1` VolumeSnapshots API (deprecated, use at your own risk)

### Documentation

### Changes

### Bug Fixes
- Fix iSCSI sessions teardown in IPv6 environment

## v1.3.6

Support for new CSI Snapshots API and Helm Chart repository.

### Enhancements
- Support `snapshot.storage.k8s.io/v1` [API](https://kubernetes.io/blog/2020/12/10/kubernetes-1.20-volume-snapshot-moves-to-ga/)
  - `v1beta1` is also supported for K8s <1.20 users
  - provide helm charts for common Snapshot Controller
- Support HTTPS insecure mode
- Allow [custom CA certificate](https://github.com/zadarastorage/zadara-csi/blob/release/docs/deploy-helm.md#adding-trusted-certificates) to be used for VPSA connectivity
- Publish helm charts repository
- Support [custom docker registry configuration](https://github.com/zadarastorage/zadara-csi/blob/release/docs/local-registry.md), including `pullImageSecrets`
- Make number of `zadara-csi-controller` replicas configurable

### Documentation
- Add [troubleshooting tips](https://github.com/zadarastorage/zadara-csi/blob/release/docs/troubleshooting.md)
- Improve and streamline [usage examples](https://github.com/zadarastorage/zadara-csi/blob/release/docs/examples.md), including storage+workload `one-pod-one-pool` example.
  - Add examples for [expanding PVC](https://github.com/zadarastorage/zadara-csi/blob/release/docs/examples.md#resize-persistent-volume-claim)
  - Clarify [configuring volume options](https://github.com/zadarastorage/zadara-csi/blob/release/docs/examples.md#configuring-volume-options)
- Update [installation instructions](https://github.com/zadarastorage/zadara-csi#snapshot-controller) for common `snapshot.storage.k8s.io/v1` API components
- More detailed [reference](https://github.com/zadarastorage/zadara-csi/blob/release/docs/deploy-helm.md#values-explained) for `values.yaml`
- Add more how-to-verify instructions

### Changes
- Update deprecated `v1beta1` K8s APIs
- Update sidecar container versions. [Full list](https://github.com/zadarastorage/zadara-csi/blob/release/helm/zadara-csi/values.yaml#L5)
- Remove Helm 2 support

### Bug Fixes
- Fix VPSA connectivity issues in IPv6 environment
- Fix  disabling `autoExpandSupport`
- Show capacity for VolumeSnapshots
- Remove repetitions from generated names

## v1.2.6

Zadara CSI Driver now [certified for RedHat OpenShift](https://catalog.redhat.com/software/containers/zadara/csi/5f0ef39369aea31642b7b0af)

### Enhancements
- Users can now specify additional Volume parameters (e.g `crypt`, `dedupe`, `compress`, `autoexpand`) in StorageClass
- Support volume auto-expand for NAS volumes (update PVC when VPSA volume has been resized)
- Add periodic VPSA health check running as CSI pod liveness probe
- Option to use colored output in logs

### Documentation
- Helm 3 installation instructions
- Added cleanup instructions for manual driver deployment
- Updated iSCSI services requirements

### Changes
- OCI image based on [UBI 8](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) instead of Ubuntu
- Use ConfigMap instead of node-local config file

### Bug Fixes
- Fixed compatibility issues with RHEL 8 and CoreOS 8
- Fix Persistent Volumes failing to delete when recycle bin is enabled on VPSA
- Fix ExpandVolume CSI API: after expansion volume should have new `capacity` instead of old+new
- Fix NodeGetVolumeStats CSI API: `used` capacity shows available capacity
