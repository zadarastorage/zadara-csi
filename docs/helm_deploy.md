
<!--- Auto-generated by https://github.com/norwoodj/helm-docs DO NOT EDIT --->

# Deploying zadara-csi Helm Chart

🛈 To proceed with this guide you will need to [get the repository](get_repo.md), if you have not already done so.

## Quickstart

You can deploy CSI driver right away, without any mandatory configuration in Chart's `values.yaml`.

From Helm repo:
```
$ helm install zadara-csi zadara-csi-helm/zadara-csi
```
Or, from a local clone:
```
$ helm install zadara-csi ./deploy/helm/zadara-csi
```

🛈 We recommend using `zadara-csi` as release name, to be consistent with other examples in this documentation.

## Configuring Chart

Many configuration options are available in `values.yaml` of `zadara-csi` Helm Chart. Most common:

- Choosing [Volume allocator](configuring_vsc.md#volume-allocator)
- [Using custom image registry](custom_image_registry.md)
- [Adding custom trusted certificates](custom_certificates.md)

Create `my_values.yaml`, following [values.yaml](../deploy/helm/zadara-csi/values.yaml) example.

You can write `my_values.yaml` with only necessary changes, e.g:

```yaml
plugin:
  allocator: "even"
  logFormat: "json"
```

An equivalent to the above example, using `--set` command-line argument:

```
$ helm install zadara-csi zadara-csi-helm/zadara-csi --set plugin.allocator="even" --set plugin.logFormat="json"
```

<details>
<summary>Click for instructions for Helm repo</summary>

You can pull the default values from the repo:

```
$ helm show values zadara-csi-helm/zadara-csi > ./my_values.yaml
```

Install:

```
$ helm install zadara-csi -f my_values.yaml zadara-csi-helm/zadara-csi
```

Using `--set` command-line argument:

```
$ helm install zadara-csi zadara-csi-helm/zadara-csi --set plugin.allocator="even" --set logFormat="json"
```

------
</details>

<details>
<summary>Click for instructions for local repo</summary>

⚠ It is best not to edit `values.yaml` inside the local Chart directory.

To copy default values from the local Chart:

```
$ cp ./deploy/helm/zadara-csi/values.yaml ./my_values.yaml
```

Install:

```
$ helm install zadara-csi -f my_values.yaml ./deploy/helm/zadara-csi
```

Using `--set` command-line argument:

```
$ helm install zadara-csi ./deploy/helm/zadara-csi --set plugin.allocator="even" --set logFormat="json"
```

---
</details>

You can verify resulting YAML files without installing, by adding `--dry-run --debug` options to `helm install` command.

## Values reference

<!--- Auto-generated from values.yaml -->
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.csiDriver | object | `{"repository":"zadara/csi-driver","tag":"2.0.0"}` | csiDriver is the main CSI container, provided by Zadara. `repository` and `tag` are used similarly for all images below. |
| image.csiDriver.repository | string | `"zadara/csi-driver"` | repository to pull image from, Dockerhub by default. |
| image.csiDriver.tag | string | `"2.0.0"` | image tag. Modifying tags is not recommended and may cause compatibility issues. |
| image.provisioner.repository | string | `"k8s.gcr.io/sig-storage/csi-provisioner"` |  |
| image.provisioner.tag | string | `"v2.2.2"` |  |
| image.attacher.repository | string | `"k8s.gcr.io/sig-storage/csi-attacher"` |  |
| image.attacher.tag | string | `"v3.2.1"` |  |
| image.resizer.repository | string | `"k8s.gcr.io/sig-storage/csi-resizer"` |  |
| image.resizer.tag | string | `"v1.2.0"` |  |
| image.livenessProbe.repository | string | `"k8s.gcr.io/sig-storage/livenessprobe"` |  |
| image.livenessProbe.tag | string | `"v2.3.0"` |  |
| image.nodeDriverRegistrar.repository | string | `"k8s.gcr.io/sig-storage/csi-node-driver-registrar"` |  |
| image.nodeDriverRegistrar.tag | string | `"v2.2.0"` |  |
| image.snapshotter.repository | string | `"k8s.gcr.io/sig-storage/csi-snapshotter"` |  |
| image.snapshotter.tagV1 | string | `"v4.1.1"` | `tagV1` will be used with `snapshots.apiVersion` `v1` (or when `auto` resolves to `v1`) |
| image.snapshotter.tagV1Beta1 | string | `"v3.0.3"` | `tagV1Beta1` will be used with `snapshots.apiVersion` `v1beta1` (or when `auto` resolves to `v1beta1`) |
| imagePullSecrets | list | `[]` | imagePullSecrets: credentials for private registry. A list of names of Secrets in the same namespace. Create `imagePullSecrets`: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| imagePullPolicy | string | `"IfNotPresent"` | imagePullPolicy *for all images* used by this chart |
| vpsa.useTLS | bool | `true` | useTLS defines whether to use TLS (HTTPS) to access VPSA |
| vpsa.verifyTLS | bool | `true` | verifyTLS defines whether to verify TLS certificate when using HTTPS |
| vpsa.monitorInterval | string | `"50s"` | monitorInterval defines interval for periodic health and capacity check of VPSA and VSC Storage Class. Format: time.Duration (e.g 10s, 1m30s) Interval value is a trade-off between responsiveness and performance. |
| vpsa.requestTimeout | string | `"3m0s"` | requestTimeout should be long enough to accommodate the majority of VPSA requests (create or delete Volume, Snapshot, etc). Format: time.Duration (e.g 10s, 1m30s) |
| plugin.allocator | string | `"weighted"` | allocator configures VSC Volume allocation algorithm (i.e, which VPSA will be chosen for Volume provisioning) Allowed values: weighted, mostAvailableCapacity, even, linear |
| plugin.controllerReplicas | int | `1` | controllerReplicas is number of replicas of Controller Deployment (responsible for provisioning and attaching volumes) |
| plugin.provisioner | string | `"csi.zadara.com"` | provisioner is the name of CSI plugin, for use in StorageClass. We do not recommend changing this. |
| plugin.healthzPort | int | `9808` | healthzPort is used for Node liveness probe, needs to be unique for each plugin instance in a cluster (Node pod requires `hostNetwork` for iSCSI support, thus using ports on the Node). |
| plugin.logLevelOverride | string | `"info"` | logLevelOverride sets log level globally. More fine-grained settings are available in ConfigMap (can be updated at runtime). Allowed values: panic, fatal, error, warning, info, debug |
| plugin.logFormat | string | `"text"` | logFormat can be "text" or "json" |
| plugin.stonith.enable | bool | `true` | enable or disable STONITH for fast failover for stateful Pods. Limited to Pods using Persistent Volume Claims provisioned by this CSI driver. |
| plugin.stonith.replicas | int | `1` | number of replicas of STONITH Deployment |
| plugin.stonith.probePeriod | string | `"2s"` | When Node is not ready, STONITH will probe it with this interval. Format: [time.Duration](https://pkg.go.dev/time#ParseDuration) e.g. 10s, 1m, 500ms |
| plugin.stonith.probeTimeout | string | `"15s"` | STONITH will start evacuating pods if Node is still not ready after this timeout.  Format: [time.Duration](https://pkg.go.dev/time#ParseDuration) e.g. 10s, 1m, 500ms |
| plugin.stonith.selfEvacuateTimeoutSeconds | int | `15` | selfEvacuateTimeoutSeconds determines `tolerations` timeouts for STONITH's own Pod. |
| snapshots | object | `{"apiVersion":"auto"}` | snapshots support: requires common one-per-cluster snapshots controller. Install from `helm/snapshots-v1[beta1]` chart in this repo. More info: https://kubernetes.io/blog/2020/12/10/kubernetes-1.20-volume-snapshot-moves-to-ga/ |
| snapshots.apiVersion | string | `"auto"` | apiVersion for CSI Snapshots: `v1beta1`, `v1` (requires K8s >=1.20) or "auto" (based on installed CRDs and k8s version) |
| namespace | string | `"kube-system"` | namespace where all CSI pods will run. We intentionally do not use value of `helm install --namespace=...`, it is recommended to deploy CSI drivers in `kube-system` namespace. |
| labels | object | `{"stage":"production"}` | labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary 'key: "value"' pairs |
| customTrustedCertificates | object | `{}` | additional customTrustedCertificates to install in CSI pods. Use either `existingSecret` or `plainText`. |

- `snapshots.apiVersion: auto`: if CSI Snapshots CRDs are installed, the chart will use API version of CRDs. If CRDs are
  not installed, the chart will use `v1` for K8s 1.20+, and `v1beta1` otherwise.

## Verify installation

Helm Chart status:

```shell
$ helm list
NAME             NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
zadara-csi       default         1               2021-07-04 11:29:08.023368123 +0300 IDT deployed        zadara-csi-2.3.3        1.3.10
```

```shell
$ helm status zadara-csi
NAME: zadara-csi
LAST DEPLOYED: Mon Feb  7 18:32:37 2022
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
##############################################################################
####   Successfully installed Zadara-CSI                                  ####
##############################################################################
Thank you for installing zadara-csi!
Snapshots API version: snapshot.storage.k8s.io/v1

# Verify installation:
kubectl get pods -n kube-system -l app="zadara-csi"

...
```

Pods status

```
$ kubectl get pods -n kube-system -l app=zadara-csi
NAME                                     READY   STATUS    RESTARTS   AGE
zadara-csi-controller-5f4b9fbc7c-wnxb7   6/6     Running   0          4m48s
zadara-csi-node-bmjcf                    3/3     Running   0          4m49s
zadara-csi-stonith-844855c488-lvbb9      1/1     Running   0          4m48s
```

- `node` pods belong to a DaemonSet, meaning that one Pod will be created for each K8s Node

## Next steps

Start with [VSC configuration](configuring_vsc.md): adding VSC StorageClasses and VPSAs.

Try [Example workload for NAS or Block volumes](example_workload.md)

## Uninstall

If needed, replace `zadara-csi` with your release name, as appears in `helm list`.

```
$ helm uninstall zadara-csi
```

Uninstalling or upgrading CSI driver *does not affect* I/O, VPSA Volumes or K8s PVCs, Storage Classes, etc.