
<!--- This file is auto-generated. Do not edit. -->
<!--- Some formatting options (e.g. '|' escaping) are not supported by all Markdown viewers. -->
<!--- Best viewed on Github, or https://dillinger.io/ -->

# CSI 2.0 Custom Resources
- [VSCStorageClass](#VSCStorageClass)
- [VPSA](#VPSA)
- [VSCNode](#VSCNode)
- [Volume](#Volume)
- [ExternalVolume](#ExternalVolume)
- [VolumeAttachment](#VolumeAttachment)
- [Snapshot](#Snapshot)
---


##  VSCStorageClass

VSCStorageClass is the Schema for the vscstorageclasses API
```shell script
kubectl get vscstorageclasses
kubectl get vscsc
```

#### Example YAML
```yaml
apiVersion: storage.zadara.com/v1
kind: VSCStorageClass
metadata:
  name: vscstorageclass-sample
spec:
  displayName: "Sample VSC Storage Class"
  description: "Demonstrates VSCStorageClass schema"
  isDefault: true
## status cannot be edited by user, shown here as a reference.
status:
  state: "Ready"
  capacity:
    available: 1.5Ti
    total: 2Ti
  counters:
    VPSA: 1
    volumes: 100
    pools: 1
    snapshots: 50

```

#### Spec
| Field                       | Type    | Description                                                                                                                                                                                  | Notes    |
|-----------------------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `spec`                      | object  | VSCStorageClassSpec defines the desired state of VSCStorageClass                                                                                                                             | Required |
| `spec.description`          | string  | Human-readable description.                                                                                                                                                                  |          |
| `spec.displayName`          | string  | Human-readable name.                                                                                                                                                                         |          |
| `spec.isDefault`            | boolean | Default VSCStorageClass will be used when VSCStorageClassName is not explicitly set in StorageClass `parameters`. This works similar to how you can omit storageClassName in PVC definition. |          |
| `spec.volumeFlags`          | object  | VolumeFlags are used when creating new Volumes.                                                                                                                                              |          |
| `spec.volumeFlags.compress` | boolean | Enable data compression (all-flash VPSA required)                                                                                                                                            | Required |
| `spec.volumeFlags.dedupe`   | boolean | Enable data deduplication (all-flash VPSA required)                                                                                                                                          | Required |
| `spec.volumeFlags.encrypt`  | boolean | Enable data encryption                                                                                                                                                                       | Required |
| `spec.volumeFlags.extra`    | object  | Additional Volume flags. See "Create Volume" in https://vpsa-api.zadarastorage.com/#volumes                                                                                                  |          |

#### Status
| Field                       | Type    | Description                                                                                                                                                                                                                                          | Notes                                                                       |
|-----------------------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| `status`                    | object  | VSCStorageClassStatus defines the observed state of VSCStorageClass                                                                                                                                                                                  |                                                                             |
| `status.state`              | string  | Status of the VSCStorageClass `Creating`: Exists in DB. `Ready`:    Ready for volume provisioning. `Failed`:   VUnhealthy, typically because of failed VPSA which are members of this VSCStorageClass. `Deleting`: VSCStorageClass is being deleted. | Required. Allowed values: `"Creating"`, `"Ready"`, `"Failed"`, `"Deleting"` |
| `status.capacity`           | object  | Capacity aggregates capacity of all member VPSAs.                                                                                                                                                                                                    |                                                                             |
| `status.capacity.available` |         | Available physical capacity of all Pools of all member VPSAs.                                                                                                                                                                                        | Required                                                                    |
| `status.capacity.mode`      | string  | Capacity mode: "normal", "alert", "protected" or "emergency". Capacity mode of theVSCStorageClass is the worst of the capacity modes of member VPSAs.                                                                                                |                                                                             |
| `status.capacity.total`     |         | Total physical capacity of all Pools of all member VPSAs.                                                                                                                                                                                            | Required                                                                    |
| `status.counters`           | object  | Counters aggregate counters of all member VPSAs.                                                                                                                                                                                                     |                                                                             |
| `status.counters.VPSA`      | integer | Number of member VPSAs                                                                                                                                                                                                                               | Required                                                                    |
| `status.counters.pools`     | integer | Number of VPSA Pools of all member VPSAs.                                                                                                                                                                                                            | Required                                                                    |
| `status.counters.snapshots` | integer | Number of VPSA Snapshots of all member VPSAs.                                                                                                                                                                                                        | Required                                                                    |
| `status.counters.volumes`   | integer | Number of VPSA Volumes of all member VPSAs.                                                                                                                                                                                                          | Required                                                                    |


##  VPSA

VPSA is the Schema for the vpsas API
```shell script
kubectl get vpsas
```

#### Example YAML
```yaml
apiVersion: storage.zadara.com/v1
kind: VPSA
metadata:
  name: vpsa-sample
spec:
  displayName: "Example VPSA"
  description: "Demonstrates VPSA resource schema"
  hostname: "example.zadaravpsa.com"
  token: "SUPER-SECRET-TOKEN-12345"
  VSCStorageClassName: "vscstorageclass-sample"
## status cannot be edited by user, shown here as a reference.
status:
  state: "Ready"
  capacity:
    available: 1.5Ti
    total: 2Ti
  counters:
    volumes: 100
    pools: 1
    snapshots: 50
  version:
    softwareVersion: "20.12-sp2"
  CHAPUser: "vpsa-user"
  CHAPSecret: "CHAPSECRET123"
  IQN: "iqn.2011-04.com.zadara:vsa-00000042:0123456789ABCDEF"

```

#### Spec
| Field                      | Type   | Description                                                                                         | Notes    |
|----------------------------|--------|-----------------------------------------------------------------------------------------------------|----------|
| `spec`                     | object | VPSASpec defines the desired state of VPSA                                                          | Required |
| `spec.VSCStorageClassName` | string | Name of the VSCStorageClass Custom Resource, setting the membership of a VPSA in a VSCStorageClass. | Required |
| `spec.description`         | string | Human-readable description.                                                                         |          |
| `spec.displayName`         | string | Human-readable name.                                                                                |          |
| `spec.hostname`            | string | Hostname (IP or DNS name) of the VPSA                                                               |          |
| `spec.token`               | string | API access token of the VPSA                                                                        |          |

#### Status
| Field                            | Type    | Description                                                                                                                                                                                                                                                                                                                                                                                                                         | Notes                                                                                                             |
|----------------------------------|---------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `status`                         | object  | VPSAStatus defines the observed state of VPSA                                                                                                                                                                                                                                                                                                                                                                                       |                                                                                                                   |
| `status.CHAPSecret`              | string  | Password for iSCSI authentication                                                                                                                                                                                                                                                                                                                                                                                                   |                                                                                                                   |
| `status.CHAPUser`                | string  | Username for iSCSI authentication                                                                                                                                                                                                                                                                                                                                                                                                   |                                                                                                                   |
| `status.ExternalManageToken`     | string  | API access token of the VPSA for external manage user                                                                                                                                                                                                                                                                                                                                                                               |                                                                                                                   |
| `status.IQN`                     | string  | IQN (iSCSI Qualified Name) of the VPSA (iSCSI target)                                                                                                                                                                                                                                                                                                                                                                               |                                                                                                                   |
| `status.LegacyVPSA`              | boolean | LegacyVPSA is true when vpsa version < 23.03, does not support set externally manage                                                                                                                                                                                                                                                                                                                                                |                                                                                                                   |
| `status.state`                   | string  | Status of the VPSA `Configuring`:  Exists in DB, validation and reconfiguring in progress. `Ready`:        Ready for volume provisioning `Incompatible`: Does not fit VSC requirements or not compatible with VSCStorageClass `Unreachable`:  Unreachable - state unknown (network, credentials or TLS issues). `Failed`:       Unhealthy (Pools, Drives, Volumes not healthy) `Deleting`:     VPSA is removed from VSCStorageClass | Required. Allowed values: `"Configuring"`, `"Ready"`, `"Incompatible"`, `"Unreachable"`, `"Failed"`, `"Deleting"` |
| `status.capacity`                | object  |                                                                                                                                                                                                                                                                                                                                                                                                                                     |                                                                                                                   |
| `status.capacity.available`      |         | Available physical capacity of all Pools                                                                                                                                                                                                                                                                                                                                                                                            | Required                                                                                                          |
| `status.capacity.mode`           | string  | Capacity mode: "normal", "alert", "protected" or "emergency"                                                                                                                                                                                                                                                                                                                                                                        |                                                                                                                   |
| `status.capacity.total`          |         | Total physical capacity of all Pools                                                                                                                                                                                                                                                                                                                                                                                                | Required                                                                                                          |
| `status.counters`                | object  |                                                                                                                                                                                                                                                                                                                                                                                                                                     |                                                                                                                   |
| `status.counters.pools`          | integer | Number of VPSA Pools                                                                                                                                                                                                                                                                                                                                                                                                                | Required                                                                                                          |
| `status.counters.snapshots`      | integer | Number of VPSA Snapshots                                                                                                                                                                                                                                                                                                                                                                                                            | Required                                                                                                          |
| `status.counters.volumes`        | integer | Number of VPSA Volumes                                                                                                                                                                                                                                                                                                                                                                                                              | Required                                                                                                          |
| `status.version`                 | object  |                                                                                                                                                                                                                                                                                                                                                                                                                                     |                                                                                                                   |
| `status.version.softwareVersion` | string  | VPSA software version, e.g, 22.06-sp1-123                                                                                                                                                                                                                                                                                                                                                                                           |                                                                                                                   |


##  VSCNode

VSCNode is the Schema for the VSCNodes API
```shell script
kubectl get vscnodes
```

#### Example YAML
```yaml
apiVersion: storage.zadara.com/v1
kind: VSCNode
metadata:
  name: vscnode-sample
spec:
  displayName: "Example VSC Node"
  description: "Demonstrates VSCNode schema"
  NAS:
    IP: 10.10.10.10
  block:
    IQN: "iqn.2005-03.org.open-iscsi:00c0ffee00"
## status cannot be edited by user, shown here as a reference.
status: {}

```

#### Spec
| Field              | Type   | Description                                              | Notes    |
|--------------------|--------|----------------------------------------------------------|----------|
| `spec`             | object | VSCNodeSpec defines the desired state of VSCNode         | Required |
| `spec.description` | string | Human-readable description.                              |          |
| `spec.displayName` | string | Human-readable name.                                     | Required |
| `spec.NAS`         | object | NAS-specific properties                                  |          |
| `spec.NAS.IP`      | string | Node IP                                                  | Required |
| `spec.block`       | object | Block-specific properties                                |          |
| `spec.block.IQN`   | string | IQN (iSCSI Qualified Name) of the Node (iSCSI initiator) | Required |

#### Status
| Field    | Type   | Description                                         | Notes |
|----------|--------|-----------------------------------------------------|-------|
| `status` | object | VSCNodeStatus defines the observed state of VSCNode |       |


##  Volume

Volume is the Schema for the volumes API
```shell script
kubectl get volumes
```

#### Example YAML
```yaml
apiVersion: storage.zadara.com/v1
kind: Volume
metadata:
  name: volume-sample
spec:
  displayName: "Example NAS Volume"
  description: "Demonstrates Volume schema"
  VSCStorageClassName: "vscstorageclass-sample"
  size: 100Gi
  volumeType: "NAS"
## status cannot be edited by user, shown here as a reference.
status:
  state: "Ready"
  VPSAID: "vpsa-sample"
  ID: "volume-00000001"
  CGID: "cg-00000001"
  poolID: "pool-00010003"
  ## NAS-specific fields:
  NAS:
    NFSExportPath: "10.10.10.10:/export/volume-sample"
    autoExpandEnabled: false
  ## Block-specific fields:
  # Block:
  #   target: "iqn.2005-03.org.open-iscsi:e9c4f0d828cf"

```

#### Spec
| Field                      | Type    | Description                                                                                               | Notes                                        |
|----------------------------|---------|-----------------------------------------------------------------------------------------------------------|----------------------------------------------|
| `spec`                     | object  | VolumeSpec defines the desired state of Volume                                                            | Required                                     |
| `spec.VSCStorageClassName` | string  | Name of the VSCStorageClass Custom Resource (i.e, a group of VPSAs), which handles Volume provisioning.   | Required                                     |
| `spec.description`         | string  | Human-readable description. Mapped to a Comment on VPSA                                                   |                                              |
| `spec.displayName`         | string  | Human-readable name. Mapped to display name of VPSA Volume.                                               | Required                                     |
| `spec.size`                |         | Provisioned capacity of a Volume.                                                                         | Required                                     |
| `spec.volumeType`          | string  |                                                                                                           | Required. Allowed values: `"NAS"`, `"Block"` |
| `spec.flags`               | object  | Additional flags used when creating a new Volume. VolumeFlags may override those defined in StorageClass. |                                              |
| `spec.flags.compress`      | boolean | Enable data compression (all-flash VPSA required)                                                         | Required                                     |
| `spec.flags.dedupe`        | boolean | Enable data deduplication (all-flash VPSA required)                                                       | Required                                     |
| `spec.flags.encrypt`       | boolean | Enable data encryption                                                                                    | Required                                     |
| `spec.flags.extra`         | object  | Additional Volume flags. See "Create Volume" in https://vpsa-api.zadarastorage.com/#volumes               |                                              |

#### Status
| Field                          | Type    | Description                                                                                                                                                                                                                                                                                                                                                                       | Notes    |
|--------------------------------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `status`                       | object  | VolumeStatus defines the observed state of Volume                                                                                                                                                                                                                                                                                                                                 |          |
| `status.Block`                 | object  | Block-specific properties                                                                                                                                                                                                                                                                                                                                                         |          |
| `status.CGID`                  | string  | Internal Consistency Group ID on the VPSA, e.g, cg-00000001                                                                                                                                                                                                                                                                                                                       | Required |
| `status.ID`                    | string  | Internal Volume ID on the VPSA, e.g, volume-00000001                                                                                                                                                                                                                                                                                                                              | Required |
| `status.VPSAID`                | string  | Name of the VPSA Custom Resource                                                                                                                                                                                                                                                                                                                                                  | Required |
| `status.poolID`                | string  | Internal Pool ID on the VPSA, e.g, pool-00000001                                                                                                                                                                                                                                                                                                                                  | Required |
| `status.state`                 | string  | Status of the Snapshot `Creating`:     Volume exists in DB. `Provisioning`: Creating a *new empty* Volume on VPSA. VPSAVolumeID is set. `Cloning`:      Creating a *cloned* Volume on VPSA. VPSAVolumeID may be empty, CGID is set. `Ready`:        Volume is ready to use `Deleting`:     Delete on VPSA is in progress. `Failed`:       Volume exists on VPSA, but in bad state | Required |
| `status.NAS`                   | object  | NAS-specific properties                                                                                                                                                                                                                                                                                                                                                           |          |
| `status.NAS.NFSExportPath`     | string  | NFS export path for `mount` commands                                                                                                                                                                                                                                                                                                                                              | Required |
| `status.NAS.autoExpandEnabled` | boolean | Automatic expansion when Volume is low on free capacity                                                                                                                                                                                                                                                                                                                           | Required |


##  ExternalVolume

ExternalVolume is the Schema for the externalvolumes API. It uses the same schema as Volume, but represents a Volume that is not managed by VSC (Volume Service Controller). Deleting ExternalVolume will not delete the underlying VPSA Volume.
```shell script
kubectl get externalvolumes
```

#### Example YAML
```yaml
apiVersion: storage.zadara.com/v1
kind: ExternalVolume
metadata:
  name: externalvolume-sample
spec:
  displayName: "Example of external NAS Volume"
  description: "Follows Volume schema"
  VSCStorageClassName: "vscstorageclass-sample"
  size: 100Gi
  volumeType: "NAS"
## status cannot be edited by user, shown here as a reference.
status:
  state: "Ready"
  VPSAID: "vpsa-sample"
  ID: "volume-00000001"
  CGID: "cg-00000001"
  poolID: "pool-00010003"
  ## NAS-specific fields:
  NAS:
    NFSExportPath: "10.10.10.10:/export/volume-sample"
    autoExpandEnabled: false
  ## Block-specific fields:
  # Block:
  #   target: "iqn.2005-03.org.open-iscsi:e9c4f0d828cf"

```

#### Spec
| Field                      | Type    | Description                                                                                               | Notes                                        |
|----------------------------|---------|-----------------------------------------------------------------------------------------------------------|----------------------------------------------|
| `spec`                     | object  | VolumeSpec defines the desired state of Volume                                                            | Required                                     |
| `spec.VSCStorageClassName` | string  | Name of the VSCStorageClass Custom Resource (i.e, a group of VPSAs), which handles Volume provisioning.   | Required                                     |
| `spec.description`         | string  | Human-readable description. Mapped to a Comment on VPSA                                                   |                                              |
| `spec.displayName`         | string  | Human-readable name. Mapped to display name of VPSA Volume.                                               | Required                                     |
| `spec.size`                |         | Provisioned capacity of a Volume.                                                                         | Required                                     |
| `spec.volumeType`          | string  |                                                                                                           | Required. Allowed values: `"NAS"`, `"Block"` |
| `spec.flags`               | object  | Additional flags used when creating a new Volume. VolumeFlags may override those defined in StorageClass. |                                              |
| `spec.flags.compress`      | boolean | Enable data compression (all-flash VPSA required)                                                         | Required                                     |
| `spec.flags.dedupe`        | boolean | Enable data deduplication (all-flash VPSA required)                                                       | Required                                     |
| `spec.flags.encrypt`       | boolean | Enable data encryption                                                                                    | Required                                     |
| `spec.flags.extra`         | object  | Additional Volume flags. See "Create Volume" in https://vpsa-api.zadarastorage.com/#volumes               |                                              |

#### Status
| Field                          | Type    | Description                                                                                                                                                                                                                                                                                                                                                                       | Notes    |
|--------------------------------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `status`                       | object  | VolumeStatus defines the observed state of Volume                                                                                                                                                                                                                                                                                                                                 |          |
| `status.Block`                 | object  | Block-specific properties                                                                                                                                                                                                                                                                                                                                                         |          |
| `status.CGID`                  | string  | Internal Consistency Group ID on the VPSA, e.g, cg-00000001                                                                                                                                                                                                                                                                                                                       | Required |
| `status.ID`                    | string  | Internal Volume ID on the VPSA, e.g, volume-00000001                                                                                                                                                                                                                                                                                                                              | Required |
| `status.VPSAID`                | string  | Name of the VPSA Custom Resource                                                                                                                                                                                                                                                                                                                                                  | Required |
| `status.poolID`                | string  | Internal Pool ID on the VPSA, e.g, pool-00000001                                                                                                                                                                                                                                                                                                                                  | Required |
| `status.state`                 | string  | Status of the Snapshot `Creating`:     Volume exists in DB. `Provisioning`: Creating a *new empty* Volume on VPSA. VPSAVolumeID is set. `Cloning`:      Creating a *cloned* Volume on VPSA. VPSAVolumeID may be empty, CGID is set. `Ready`:        Volume is ready to use `Deleting`:     Delete on VPSA is in progress. `Failed`:       Volume exists on VPSA, but in bad state | Required |
| `status.NAS`                   | object  | NAS-specific properties                                                                                                                                                                                                                                                                                                                                                           |          |
| `status.NAS.NFSExportPath`     | string  | NFS export path for `mount` commands                                                                                                                                                                                                                                                                                                                                              | Required |
| `status.NAS.autoExpandEnabled` | boolean | Automatic expansion when Volume is low on free capacity                                                                                                                                                                                                                                                                                                                           | Required |


##  VolumeAttachment

VolumeAttachment is the Schema for the volumeattachments API
```shell script
kubectl get volumeattachments
kubectl get vas
```

#### Example YAML
```yaml
apiVersion: storage.zadara.com/v1
kind: VolumeAttachment
metadata:
  name: volumeattachment-sample
spec:
  volumeName: "volume-sample"
  VSCNodeName: "vscnode-sample"
  attachType: "NFS"
  readOnly: false
## status cannot be edited by user, shown here as a reference.
status:
  state: "Ready"
  VPSAServerID: "srv-00000001"

```

#### Spec
| Field              | Type    | Description                                                        | Notes    |
|--------------------|---------|--------------------------------------------------------------------|----------|
| `spec`             | object  | VolumeAttachmentSpec defines the desired state of VolumeAttachment | Required |
| `spec.VSCNodeName` | string  | Name of the VSCNode Custom Resource                                | Required |
| `spec.attachType`  | string  | Attachment type: "NFS" or "ISCSI"                                  | Required |
| `spec.readOnly`    | boolean | Attach in read-only mode.                                          | Required |
| `spec.volumeName`  | string  | Name of the Volume Custom Resource                                 | Required |

#### Status
| Field                      | Type    | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Notes    |
|----------------------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `status`                   | object  | VolumeAttachmentStatus defines the observed state of VolumeAttachment                                                                                                                                                                                                                                                                                                                                                                                                                                                            |          |
| `status.NAS`               | object  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |          |
| `status.VPSAServerID`      | string  | Internal Server ID on the VPSA, e.g, srv-00000001. Note, that Servers are shared between VolumeAttachments on the same Node.                                                                                                                                                                                                                                                                                                                                                                                                     |          |
| `status.state`             | string  | Status of the VolumeAttachment `Creating`:          VolumeAttachment exists in DB. `Attaching`:         Server exists on Volume's VPSA, VPSAServerID is set. `ISCSILoginPending`: Volume is attached to Server on VPSA, waiting for Node to establish iSCSI connection (Block only). `Ready`:             Volume is attached and ready to mount. `Detaching`:         Detach requested. `Deleting`:          Volume detached from VPSA Server, try to delete VPSA Server. `Failed`:            VolumeAttachment is in bad state. | Required |
| `status.Block`             | object  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |          |
| `status.Block.ISCSIStatus` | string  | iSCSI connection status: for block Volumes it can be "Active" or "Disconnected".                                                                                                                                                                                                                                                                                                                                                                                                                                                 |          |
| `status.Block.lun`         | integer | Block device LUN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Required |
| `status.Block.target`      | string  | iSCSI target for iSCSI login                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Required |


##  Snapshot

Snapshot is the Schema for the snapshots API
```shell script
kubectl get snapshots
```

#### Example YAML
```yaml
apiVersion: storage.zadara.com/v1
kind: Snapshot
metadata:
  name: snapshot-sample
spec:
  displayName: "Example Snapshot"
  description: "Demonstrates Snapshot schema"
  volumeID: "volume-sample"
## status cannot be edited by user, shown here as a reference.
status:
  state: "Ready"
  size: 100Gi
  createdTimestamp: "2022-02-01T15:15:31+0200"
  VPSAID: "vpsa-sample"
  CGID: "cg-00000001"
  poolID: "pool-00010003"
  VPSAVolumeID: "volume-00000001"
  VPSASnapshotID: "snap-00000001"

```

#### Spec
| Field              | Type   | Description                                                                        | Notes    |
|--------------------|--------|------------------------------------------------------------------------------------|----------|
| `spec`             | object | SnapshotSpec defines the desired state of Snapshot                                 | Required |
| `spec.description` | string | Human-readable description. Mapped to a Comment on VPSA                            |          |
| `spec.displayName` | string | Human-readable name. Mapped to display name of VPSA Snapshot.                      | Required |
| `spec.volumeID`    | string | Name of the Volume Custom Resource, specifying the source Volume for the Snapshot. | Required |

#### Status
| Field                     | Type   | Description                                                                                                                                                                                                                                                                                                     | Notes             |
|---------------------------|--------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------|
| `status`                  | object | SnapshotStatus defines the observed state of Snapshot                                                                                                                                                                                                                                                           |                   |
| `status.CGID`             | string | Internal Consistency Group ID on the VPSA, e.g, cg-00000001                                                                                                                                                                                                                                                     |                   |
| `status.VPSAID`           | string | Name of the VPSA Custom Resource                                                                                                                                                                                                                                                                                |                   |
| `status.VPSASnapshotID`   | string | Internal Snapshot ID on the VPSA, e.g, snap-00000001                                                                                                                                                                                                                                                            |                   |
| `status.VPSAVolumeID`     | string | Internal Volume ID on the VPSA, e.g, volume-00000001                                                                                                                                                                                                                                                            |                   |
| `status.createdTimestamp` | string | CreatedTimestamp is the time of creating the snapshot on VPSA                                                                                                                                                                                                                                                   | Format: date-time |
| `status.poolID`           | string | Internal Pool ID on the VPSA, e.g, pool-00000001                                                                                                                                                                                                                                                                |                   |
| `status.size`             |        | Size is the size of source Volume at the time of creating Snapshot, and it also determines the size of cloned Volume.                                                                                                                                                                                           |                   |
| `status.state`            | string | Status of the Snapshot `Creating`:        Snapshot Exists in DB. `TakingSnapshot`:  Snapshot exists on VPSA, waiting for it to be ready. `Ready`:           Snapshot is ready to use. `Deleting`:        Snapshot in being deleted, delete on VPSA is in progress. `Failed`:          Snapshot is in bad state. |                   |

