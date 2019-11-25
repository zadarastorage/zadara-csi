## Example workloads

### Basic example

We provide one, but very flexible Helm chart example to test Zadara-CSI plugin.
This example will allow you to run a single Pod, with an arbitrary container, and NAS or Block volume (or both).
The configuration can be easily changed using custom Helm values file.

The chart can be found in [helm/one-pod-one-pool](../helm/one-pod-one-pool) in this repository.

In all following examples proceed as following:
1.  Get release name of CSI plugin (`fuzzy-grasshopper` in this example).
    ```
    $ helm list
    NAME                    REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    fuzzy-grasshopper       1               Thu Nov 21 12:15:55 2019        DEPLOYED        zadara-csi-0.5.0        0.14.0          default
    ```
2. Get `provisioner` name of plugin
    ```
    $ helm status fuzzy-grasshopper | grep 'provisioner:'
    provisioner: qa8.csi.zadara.com
    ```
3. Create `my_values.yaml` with contents as shown in example, set `provisioner` field.
Alternatively, you can edit `helm/one-pod-one-pool/values.yaml`.

4. Run `helm install -f my_values.yaml helm/one-pod-one-pool`

#### Simple IO test

Here, we create a Pod with an ubuntu container, running IO with `dd` against a volume,
provisioned by CSI driver `qa.csi.zadara.com`.

##### NAS

```yaml
pod:
  name: dd-to-nas-pod
  container:
    name: dd-to-nas-container
  image: ubuntu:bionic
  args: ["dd", "if=/dev/urandom", "of=/mnt/csi/test_file", "bs=1M", "count=10000"]
  env: []
storageClass:
  reclaimPolicy: Delete
  provisioner: qa.csi.zadara.com
nas:
  name: nas-pvc
  accessMode: ReadWriteMany
  readOnly: false
  capacity: 50Gi
  mountPath: "/mnt/csi"
block: false
```

##### Block

```yaml
pod:
  name: dd-to-nas-pod
  container:
    name: dd-to-nas-container
  image: ubuntu:bionic
  args: ["dd", "if=/dev/urandom", "of=/dev/sdx", "bs=1M", "count=10000", "oflag=direct"]
  env: []
storageClass:
  reclaimPolicy: Delete
  provisioner: qa.csi.zadara.com
nas: false
block:
  name: block-pvc
  accessMode: ReadWriteOnce
  readOnly: false
  capacity: 50Gi
  devicePath: "/dev/sdx"
```
