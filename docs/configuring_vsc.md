# VSC Configuration

## Volume allocator

The first and the most important part of VSC configuration is to select Volume allocator, which determines how VSC will
choose VPSA when creating a new Volume.

In `values.yaml`:

```yaml
plugin:
  allocator: "mostAvailableCapacity"
```

### Available Volume allocators

- `mostAvailableCapacity` (default): prefer VPSA with the most Available Capacity in Storage Pool.
- `linear` use a VPSA until exhausted, then proceed to the next one, in the same order that VPSAs have been added to a
  VSC Storage Class.
- `even` even distribution i.e, prefer VPSA with minimum *number of Volumes* (regardless of total Volumes size).

All algorithms will only consider VPSAs that:

- have `Ready` state in VSC.
- have `normal` capacity mode.
- have sufficient Available Capacity in Storage Pool.

## Create VSC StorageClass

For Volume Provisioning, you need to create at least one VSC Storage Class.
One CSI driver instance can manage any number of VSC Storage Classes. For example, one could create

K8s StorageClass may reference VSC Storage Class in `parameters.VSCStorageClassName`, see [example](configuring_storage.md#storage-class).

🛈 [Full reference](custom_resources_generated.md#VSCStorageClass)

### Examples

```yaml
kind: VSCStorageClass
metadata:
  name: vscstorageclass-sample
spec:
  displayName: "Sample VSC Storage Class"
  description: "Demonstrates VSCStorageClass schema"
  isDefault: true
```

This file is also available in `deploy/examples`:
```
$ kubectl apply -f ./deploy/examples/storage_v1_vscstorageclass.yaml
vscstorageclass.storage.zadara.com/vscstorageclass-sample created
```

```shell
$ kubectl get vscstorageclasses -o wide
NAME                     STATUS   DEFAULT   MEMBERS   CAPACITY MODE   TOTAL   AVAILABLE   AGE
vscstorageclass-sample   Ready    true      0         normal          0       0           57s
```

### Default VSC StorageClass

You may create a VSC Storage Class with `isDefault: true`, and it will be used when VSC Storage Class is
not explicitly set (similar to how you can omit StorageClass in PVC definition).

⚠ Default VSC Storage Class cannot be deleted.

To delete it, update `isDefault` by using `kubectl edit vscsc`, or `kubectl patch`:

```
$ kubectl patch vscsc vscstorageclass-sample --patch '{"spec":{"isDefault":false}}' --type=merge
vscstorageclass.storage.zadara.com/vscstorageclass-sample patched

$ kubectl get vscstorageclasses -o wide
NAME                     STATUS   DEFAULT   MEMBERS   CAPACITY MODE   TOTAL   AVAILABLE   AGE
vscstorageclass-sample   Ready              0         normal          0       0           7m1s
```

## Add VPSA to VSC StorageClass

VPSA Custom Resource includes VPSA credentials,
and a reference to a VSC Storage Class in `spec.VSCStorageClassName`.

🛈 [Full reference](custom_resources_generated.md#VSCStorageClass)

### Examples

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
```

This file is also available in `deploy/examples` (replace `spec.hostname` and `spec.token` with your VPSA credentials):
```shell
$ kubectl apply -f ./deploy/examples/storage_v1_vpsa.yaml
vscstorageclass.storage.zadara.com/vscstorageclass-sample created
```

```shell
$ kubectl get vpsa -o wide
NAME          STATUS   DISPLAY NAME   HOSTNAME                                 VERSION         CAPACITY MODE   TOTAL      AVAILABLE   VSC                      AGE
vpsa-sample   Ready    Example VPSA   vsa-0000028d-zadara-qa.zadaravpsa.com    20.12-sp2-240   normal          743296Mi   743152Mi    vscstorageclass-sample   45s
```

At this point, _VSC Storage Class_ will be updated with aggregated status and capacity:

```shell
$ kubectl get vscstorageclasses -o wide
NAME                     STATUS   DEFAULT   MEMBERS   CAPACITY MODE   TOTAL      AVAILABLE   AGE
vscstorageclass-sample   Ready    true      1         normal          743296Mi   743152Mi    52m
```
