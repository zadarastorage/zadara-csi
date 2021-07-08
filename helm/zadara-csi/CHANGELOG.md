## Pre-release:

### before 0.2.0

Plugin version 0.13.0

#### Features

- Support multiple plugin instances (with different `provisioner` name)

- Use `iscsi-recv` service to run `iscsiadm` on host

#### Fixes

- lint YAMLs

- fix Expand Volume support

- use Helm naming conventions for chart name

#### Other


---


### 0.2.0 to 0.3.0

Plugin version 0.13.0

#### Features

- Add NOTES.txt (post-installation instructions) with either usage example or error message

- Add liveness probes to Node and Controller

- Add README to the chart

- Add labels to zadara-csi resources

#### Fixes

#### Other

- Controller plugin now runs as Deployment

---

### 0.3.0 to 0.4.0

Plugin version 0.14.0

#### Features

- Support 2 options to manage iSCSI connections on host: `rootfs` or `client-server`

#### Fixes

#### Other

---

### 0.4.0 to 0.5.0

Plugin version 0.14.0

#### Features

- Allow to add arbitrary labels to zadara-csi resources

#### Fixes

#### Other

