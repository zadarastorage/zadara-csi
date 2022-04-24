## v2.0.0

### Main features

- **Multiple VPSA support** in one CSI driver
- VPSAs are managed using Kubernetes Custom Resources
- Custom resources report Events (e.g. if VPSA is failed, this will be posted as k8s Event, and also shown in `kubectl describe vpsa`).
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
- support for propagating volume expansion _from_ VPSA _to_ K8s (i.e, the opposite of updating PVC size in K8s, which expands a VPSA volume)
- `run-on-host` iSCSI mode
- support for multiple instances of CSI driver
