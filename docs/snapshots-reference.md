
<!--- This file is auto-generated. Do not edit. -->
<!--- Some formatting options (e.g. '|' escaping) are not supported by all Markdown viewers. -->
<!--- Best viewed on Github, or https://dillinger.io/ -->

# CSI Snapshots Custom Resources
- [VolumeSnapshot](#VolumeSnapshot)
- [VolumeSnapshotClass](#VolumeSnapshotClass)
- [VolumeSnapshotContent](#VolumeSnapshotContent)
---


##  VolumeSnapshot

VolumeSnapshot is a user's request for either creating a point-in-time snapshot of a persistent volume, or binding to a pre-existing snapshot.
```shell script
kubectl get volumesnapshots
```

#### Example YAML
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: nas-snapshot-test
spec:
  volumeSnapshotClassName: zadara-csi-snapclass
  # source: exactly one of:
  # - persistentVolumeClaimName (for new snapshots)
  # - volumeSnapshotContentName (for importing existing snapshots into k8s)
  source:
    persistentVolumeClaimName: zadara-nas-pvc

```

#### Spec
Field | Description | Notes
------|-------------|------
`spec` | spec defines the desired characteristics of a snapshot requested by a user. More info: https://kubernetes.io/docs/concepts/storage/volume-snapshots#volumesnapshots Required. |
`spec.volumeSnapshotClassName` | VolumeSnapshotClassName is the name of the VolumeSnapshotClass requested by the VolumeSnapshot. VolumeSnapshotClassName may be left nil to indicate that the default SnapshotClass should be used. A given cluster may have multiple default Volume SnapshotClasses: one default per CSI Driver. If a VolumeSnapshot does not specify a SnapshotClass, VolumeSnapshotSource will be checked to figure out what the associated CSI Driver is, and the default VolumeSnapshotClass associated with that CSI Driver will be used. If more than one VolumeSnapshotClass exist for a given CSI Driver and more than one have been marked as default, CreateSnapshot will fail and generate an event. Empty string is not allowed for this field. |
`spec.source` | source specifies where a snapshot will be created from. This field is immutable after creation. Required. | Required
`spec.source.persistentVolumeClaimName` | persistentVolumeClaimName specifies the name of the PersistentVolumeClaim object representing the volume from which a snapshot should be created. This PVC is assumed to be in the same namespace as the VolumeSnapshot object. This field should be set if the snapshot does not exists, and needs to be created. This field is immutable. |
`spec.source.volumeSnapshotContentName` | volumeSnapshotContentName specifies the name of a pre-existing VolumeSnapshotContent object representing an existing volume snapshot. This field should be set if the snapshot already exists and only needs a representation in Kubernetes. This field is immutable. |

#### Status
Field | Description | Notes
------|-------------|------
`status` | status represents the current information of a snapshot. Consumers must verify binding between VolumeSnapshot and VolumeSnapshotContent objects is successful (by validating that both VolumeSnapshot and VolumeSnapshotContent point at each other) before using this object. |
`status.boundVolumeSnapshotContentName` | boundVolumeSnapshotContentName is the name of the VolumeSnapshotContent object to which this VolumeSnapshot object intends to bind to. If not specified, it indicates that the VolumeSnapshot object has not been successfully bound to a VolumeSnapshotContent object yet. NOTE: To avoid possible security issues, consumers must verify binding between VolumeSnapshot and VolumeSnapshotContent objects is successful (by validating that both VolumeSnapshot and VolumeSnapshotContent point at each other) before using this object. |
`status.creationTime` | creationTime is the timestamp when the point-in-time snapshot is taken by the underlying storage system. In dynamic snapshot creation case, this field will be filled in by the snapshot controller with the "creation_time" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "creation_time" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. If not specified, it may indicate that the creation time of the snapshot is unknown. |
`status.readyToUse` | readyToUse indicates if the snapshot is ready to be used to restore a volume. In dynamic snapshot creation case, this field will be filled in by the snapshot controller with the "ready_to_use" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "ready_to_use" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it, otherwise, this field will be set to "True". If not specified, it means the readiness of a snapshot is unknown. |
`status.restoreSize` | restoreSize represents the minimum size of volume required to create a volume from this snapshot. In dynamic snapshot creation case, this field will be filled in by the snapshot controller with the "size_bytes" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "size_bytes" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. When restoring a volume from this snapshot, the size of the volume MUST NOT be smaller than the restoreSize if it is specified, otherwise the restoration will fail. If not specified, it indicates that the size is unknown. |
`status.error` | error is the last observed error during snapshot creation, if any. This field could be helpful to upper level controllers(i.e., application controller) to decide whether they should continue on waiting for the snapshot to be created based on the type of error reported. The snapshot controller will keep retrying when an error occurrs during the snapshot creation. Upon success, this error field will be cleared. |
`status.error.message` | message is a string detailing the encountered error during snapshot creation if specified. NOTE: message may be logged, and it should not contain sensitive information. |
`status.error.time` | time is the timestamp when the error was encountered. |

##  VolumeSnapshotClass

VolumeSnapshotClass specifies parameters that a underlying storage system uses when creating a volume snapshot. A specific VolumeSnapshotClass is used by specifying its name in a VolumeSnapshot object. VolumeSnapshotClasses are non-namespaced
```shell script
kubectl get volumesnapshotclasses
```

#### Example YAML
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: zadara-csi-snapclass
deletionPolicy: Delete
driver: csi.zadara.com
# # parameters are opaque key-values pairs passed to the CSI driver (similar to those of StorageClass)
# parameters:

```

#### Properties
Field | Description | Notes
------|-------------|------
`deletionPolicy` | deletionPolicy determines whether a VolumeSnapshotContent created through the VolumeSnapshotClass should be deleted when its bound VolumeSnapshot is deleted. Supported values are "Retain" and "Delete". "Retain" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept. "Delete" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted. Required. | Allowed values: `"Delete"`, `"Retain"`
`driver` | driver is the name of the storage driver that handles this VolumeSnapshotClass. Required. |
`kind` | Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds |
`parameters` | parameters is a key-value map with storage driver specific parameters for creating snapshots. These values are opaque to Kubernetes. |
`apiVersion` | APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources |

##  VolumeSnapshotContent

VolumeSnapshotContent represents the actual "on-disk" snapshot object in the underlying storage system
```shell script
kubectl get volumesnapshotcontents
```

#### Example YAML
```yaml
# VolumeSnapshotContent is created automatically for VolumeSnapshot
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotContent
metadata:
  name: snapcontent-5bc677bc-5296-4ee6-b1c2-f54eb812db93
spec:
  deletionPolicy: Delete
  driver: csi.zadara.com
  source:
    volumeHandle: volume-0000001e
  volumeSnapshotClassName: zadara-csi-snapclass
  volumeSnapshotRef:
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshot
    name: nas-snapshot-test
    namespace: default

```

#### Spec
Field | Description | Notes
------|-------------|------
`spec` | spec defines properties of a VolumeSnapshotContent created by the underlying storage system. Required. |
`spec.deletionPolicy` | deletionPolicy determines whether this VolumeSnapshotContent and its physical snapshot on the underlying storage system should be deleted when its bound VolumeSnapshot is deleted. Supported values are "Retain" and "Delete". "Retain" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept. "Delete" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted. For dynamically provisioned snapshots, this field will automatically be filled in by the CSI snapshotter sidecar with the "DeletionPolicy" field defined in the corresponding VolumeSnapshotClass. For pre-existing snapshots, users MUST specify this field when creating the  VolumeSnapshotContent object. Required. | Required. Allowed values: `"Delete"`, `"Retain"`
`spec.driver` | driver is the name of the CSI driver used to create the physical snapshot on the underlying storage system. This MUST be the same as the name returned by the CSI GetPluginName() call for that driver. Required. | Required
`spec.volumeSnapshotClassName` | name of the VolumeSnapshotClass from which this snapshot was (or will be) created. Note that after provisioning, the VolumeSnapshotClass may be deleted or recreated with different set of values, and as such, should not be referenced post-snapshot creation. |
`spec.source` | source specifies whether the snapshot is (or should be) dynamically provisioned or already exists, and just requires a Kubernetes object representation. This field is immutable after creation. Required. | Required
`spec.source.snapshotHandle` | snapshotHandle specifies the CSI "snapshot_id" of a pre-existing snapshot on the underlying storage system for which a Kubernetes object representation was (or should be) created. This field is immutable. |
`spec.source.volumeHandle` | volumeHandle specifies the CSI "volume_id" of the volume from which a snapshot should be dynamically taken from. This field is immutable. |
`spec.volumeSnapshotRef` | volumeSnapshotRef specifies the VolumeSnapshot object to which this VolumeSnapshotContent object is bound. VolumeSnapshot.Spec.VolumeSnapshotContentName field must reference to this VolumeSnapshotContent's name for the bidirectional binding to be valid. For a pre-existing VolumeSnapshotContent object, name and namespace of the VolumeSnapshot object MUST be provided for binding to happen. This field is immutable after creation. Required. | Required
`spec.volumeSnapshotRef.apiVersion` | API version of the referent. |
`spec.volumeSnapshotRef.fieldPath` | If referring to a piece of an object instead of an entire object, this string should contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2]. For example, if the object reference is to a container within a pod, this would take on a value like: "spec.containers{name}" (where "name" refers to the name of the container that triggered the event) or if no container name is specified "spec.containers[2]" (container with index 2 in this pod). This syntax is chosen only to have some well-defined way of referencing a part of an object. TODO: this design is not final and this field is subject to change in the future. |
`spec.volumeSnapshotRef.kind` | Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds |
`spec.volumeSnapshotRef.name` | Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names |
`spec.volumeSnapshotRef.namespace` | Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/ |
`spec.volumeSnapshotRef.resourceVersion` | Specific resourceVersion to which this reference is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency |
`spec.volumeSnapshotRef.uid` | UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids |

#### Status
Field | Description | Notes
------|-------------|------
`status` | status represents the current information of a snapshot. |
`status.creationTime` | creationTime is the timestamp when the point-in-time snapshot is taken by the underlying storage system. In dynamic snapshot creation case, this field will be filled in by the CSI snapshotter sidecar with the "creation_time" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "creation_time" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. If not specified, it indicates the creation time is unknown. The format of this field is a Unix nanoseconds time encoded as an int64. On Unix, the command `date +%s%N` returns the current time in nanoseconds since 1970-01-01 00:00:00 UTC. |
`status.readyToUse` | readyToUse indicates if a snapshot is ready to be used to restore a volume. In dynamic snapshot creation case, this field will be filled in by the CSI snapshotter sidecar with the "ready_to_use" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "ready_to_use" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it, otherwise, this field will be set to "True". If not specified, it means the readiness of a snapshot is unknown. |
`status.restoreSize` | restoreSize represents the complete size of the snapshot in bytes. In dynamic snapshot creation case, this field will be filled in by the CSI snapshotter sidecar with the "size_bytes" value returned from CSI "CreateSnapshot" gRPC call. For a pre-existing snapshot, this field will be filled with the "size_bytes" value returned from the CSI "ListSnapshots" gRPC call if the driver supports it. When restoring a volume from this snapshot, the size of the volume MUST NOT be smaller than the restoreSize if it is specified, otherwise the restoration will fail. If not specified, it indicates that the size is unknown. |
`status.snapshotHandle` | snapshotHandle is the CSI "snapshot_id" of a snapshot on the underlying storage system. If not specified, it indicates that dynamic snapshot creation has either failed or it is still in progress. |
`status.error` | error is the last observed error during snapshot creation, if any. Upon success after retry, this error field will be cleared. |
`status.error.message` | message is a string detailing the encountered error during snapshot creation if specified. NOTE: message may be logged, and it should not contain sensitive information. |
`status.error.time` | time is the timestamp when the error was encountered. |
