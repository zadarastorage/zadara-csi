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
