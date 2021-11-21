
## Deploying zadara-csi plugin using Helm charts

Add Helm repository:
```
$ helm repo add zadara-csi-helm https://raw.githubusercontent.com/zadarastorage/zadara-csi/release/helm
$ helm repo update
```

```
$ helm search repo
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
zadara-csi-helm/one-pod-one-pool        0.1.0                           Example deployment using Zadara-CSI NAS & Block...
zadara-csi-helm/snapshots-v1            4.1.1+zadara.1  4.1.1           Common infrastructure for v1 CSI Snapshots. Inc...
zadara-csi-helm/snapshots-v1beta1       3.3.0+zadara.1  3.3.0           Common infrastructure for v1beta1 CSI Snapshots...
zadara-csi-helm/zadara-csi              2.3.2           1.3.9           Container Storage Interface (CSI) driver for Za...
```

Alternatively, Helm charts are available locally, in `helm/` subdirectory of this repository
(replace `zadara-csi-helm/` with `./helm/` in Helm commands).
Or you can add a repo for a specific version (if available):
```
$ helm repo add zadara-csi-helm https://raw.githubusercontent.com/zadarastorage/zadara-csi/master/helm
$ helm repo add zadara-csi-helm https://raw.githubusercontent.com/zadarastorage/zadara-csi/release-v1.3.9/helm
```

All examples assume the repository root as current working directory:
```
$ ls -F
CHANGELOG.md  assets/  deploy/  docs/  hack/  helm/
```

**Configure**

Create `my_values.yaml`, following [values.yaml](../helm/zadara-csi/values.yaml) example, set VPSA credentials (required), and other optional parameters.

It is best not to edit [values.yaml](../helm/zadara-csi/values.yaml) inside the chart. Instead, override default values with `-f FILE.yaml` or `--set PATH.TO.KEY=VALUE`.

- If you intend to deploy multiple Zadara-CSI instances on the same cluster, set also `plugin.provisioner`
(this is the same `provisioner` name you will use in StorageClass definition)
to be unique for each instance. Some name describing underlying VPSA, like `all-flash.csi.zadara.com`,
or `us-east.csi.zadara.com` will be a good choice.

- Note also `snapshots.apiVersion`, and choose a version that matches [Snapshot Controller](README.md#snapshot-controller),
    or set it to `auto`.

Minimal `my_values.yaml` would look like this:
```yaml
vpsa:
  url: "example.zadaravpsa.com"
  useTLS: true
  verifyTLS: true
  token: "FAKETOKEN1234567-123"
plugin:
  provisioner: csi.zadara.com
snapshots:
   apiVersion: v1
```

Full reference for `values.yaml` is [here](#values-explained)

**Deploy**

Specify release name, e.g. `zadara-csi`, or use `--generate-name` flag:
```
# use either one:
$ helm install zadara-csi      -f my_values.yaml ./helm/zadara-csi
$ helm install --generate-name -f my_values.yaml ./helm/zadara-csi
```

You can verify resulting YAML files by adding `--dry-run --debug` options to above commands.

**Verify installation**

Helm Chart status:
```
$ helm list
NAME             NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
zadara-csi       default         1               2021-07-04 11:29:08.023368123 +0300 IDT deployed        zadara-csi-2.3.2        1.3.9

$ helm status zadara-csi
NAME: zadara-csi
LAST DEPLOYED: Sun Jul  4 11:29:08 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
##############################################################################
####   Successfully installed Zadara-CSI                                  ####
##############################################################################
Thank you for installing zadara-csi!

# Verify installation:
kubectl get pods -n kube-system -l provisioner=csi.zadara.com

##############################################################################
####   Example: Create a NAS volume on your VPSA                          ####
##############################################################################
...
```

Pods status
```
$ kubectl get pods -n kube-system -l provisioner=csi.zadara.com
NAME                                            READY   STATUS      RESTARTS   AGE
zadara-csi-autoexpand-sync-27091180-mk5hv       0/1     Completed   0          2m46s
zadara-csi-controller-84c8884f5c-79v26          6/6     Running     0          6m3s
zadara-csi-node-58mb6                           3/3     Running     0          6m3s
```

- `node` pods belong to a DaemonSet, meaning that one Pod will be created for each K8s Node
- `autoexpand-sync` pod belongs to a CronJob, and will appear only if `plugin.autoExpandSupport` is enabled.
- When all `node` pods have started, on VPSA side a *Server will be created for each K8s Node*.

**Uninstall**

Replace `zadara-csi` with your release name, as appears in `helm list`.
```
$ helm uninstall zadara-csi
```

Uninstalling CSI driver does not affect VPSA Volumes or K8s PVCs, Storage Classes, etc.

---

### Values explained

<!--- Auto-generated from values.yaml -->
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| namespace | string | `"kube-system"` | namespace where all CSI pods will run |
| image.csiDriver | object | `{"repository":"zadara/csi-driver","tag":"1.3.9"}` | csiDriver is the main CSI container, provided by Zadara. `repository` and `tag` are used similarly for all images below. |
| image.csiDriver.repository | string | `"zadara/csi-driver"` | repository to pull image from, Dockerhub by default. Also available at `registry.connect.redhat.com/zadara/csi` |
| image.csiDriver.tag | string | `"1.3.9"` | image tag. Modifying tags is not recommended and may cause compatibility issues. |
| image.provisioner.repository | string | `"k8s.gcr.io/sig-storage/csi-provisioner"` |  |
| image.provisioner.tag | string | `"v2.2.2"` | last tag that supports restoring DEPRECATED v1alpha1 snapshots is v1.4.0 |
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
| image.snapshotter.tagV1Alpha1 | string | `"v1.2.2"` | DEPRECATED: `tagV1Alpha1` will be used with `snapshots.apiVersion` `v1alpha1`. |
| imagePullSecrets | list | `[]` | imagePullSecrets: credentials for private registry. A list of names of Secrets in the same namespace. Create `imagePullSecrets`: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| imagePullPolicy | string | `"IfNotPresent"` | imagePullPolicy *for all images* used by this chart |
| vpsa.url | string | `"example.zadaravpsa.com"` | url or IP of VPSA provisioning Volumes, without "http(s)://" prefix |
| vpsa.useTLS | bool | `true` | useTLS defines whether to use TLS (HTTPS) to access VPSA |
| vpsa.verifyTLS | bool | `true` | verifyTLS defines whether to verify TLS certificate when using HTTPS |
| vpsa.token | string | `"FAKETOKEN1234567-123"` | token to access VPSA |
| plugin.controllerReplicas | int | `1` | controllerReplicas is number of replicas of Controller Deployment (responsible for provisioning and attaching volumes) |
| plugin.provisioner | string | `"csi.zadara.com"` | provisioner is the name of CSI plugin, for use in StorageClass, e.g. `us-west.csi.zadara.com`, `on-prem.csi.zadara.com` |
| plugin.iscsiMode | string | `"rootfs"` | iscsiMode (`rootfs` or `client-server`) allows to chose a way for the plugin to reach iscsiadm on host |
| plugin.healthzPort | int | `9808` | healthzPort is used for Node liveness probe, needs to be unique for each plugin instance in a cluster (Node pod requires `hostNetwork` for iSCSI support, thus using ports on the Node). |
| plugin.autoExpandSupport.enable | bool | `true` | enable or disable autoExpandSupport: will create a CronJob for periodical capacity sync between VPSA Volumes and K8s PVCs |
| plugin.autoExpandSupport.schedule | string | `"*/10 * * * *"` | schedule for periodical capacity sync in cron format |
| plugin.stonith.enable | bool | `true` | enable or disable STONITH for fast failover for stateful Pods. Limited to Pods using Persistent Volume Claims provisioned by this CSI driver. |
| plugin.stonith.probePeriod | string | `"2s"` | When Node is not ready, STONITH will probe it with this interval. Format: [time.Duration](https://pkg.go.dev/time#ParseDuration) e.g. 10s, 1m, 500ms |
| plugin.stonith.probeTimeout | string | `"15s"` | STONITH will start evacuating pods if Node is still not ready after this timeout.  Format: [time.Duration](https://pkg.go.dev/time#ParseDuration) e.g. 10s, 1m, 500ms |
| plugin.stonith.selfEvacuateTimeoutSeconds | int | `15` | selfEvacuateTimeoutSeconds determines `tolerations` timeouts for STONITH's own Pod. |
| snapshots | object | `{"apiVersion":"auto"}` | snapshots support: requires common one-per-cluster snapshots controller. Install from `helm/snapshots-v1[beta1]` chart in this repo. More info: https://kubernetes.io/blog/2020/12/10/kubernetes-1.20-volume-snapshot-moves-to-ga/ |
| snapshots.apiVersion | string | `"auto"` | apiVersion for CSI Snapshots: `v1beta1`, `v1` (requires K8s >=1.20) or "auto" (based on installed CRDs and k8s version) Deprecated option: `v1alpha1`, requires `RemoveSelfLink=false` feature gate. |
| labels | object | `{"stage":"production"}` | labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary 'key: "value"' pairs |
| customTrustedCertificates | object | `{}` | additional customTrustedCertificates to install in CSI pods. Use either `existingSecret` or `plainText`. |

- `plugin.iscsiMode`: For more info see [Node iSCSI Connectivity](README.md#node-iscsi-connectivity) section.

- `plugin.autoExpandSupport` To enable auto-expand for CSI Volumes, you need to configure [Storage Class](README.md#storage-class) `parameters.volumeOptions`.
Auto-expand requires VPSA version 19.08 or higher. When `plugin.autoExpandSupport` is enabled,
periodical sync will be handled by a CronJob, running in the same namespace as CSI driver.

- `snapshots.apiVersion: auto`: if CSI Snapshots CRDs are installed, the chart will use API version of CRDs.
If CRDs are not installed, the chart will use `v1` for K8s 1.20+, and `v1beta1` otherwise.

### Adding trusted certificates

CSI Driver can be configured to use HTTPS with custom certificate (e.g. self-signed).

You can either reference a Secret, or provide a certificate directly in `values.yaml` (a Secret will be created automatically).

Before proceeding, please make sure that `X509v3 Basic Constraints: CA: TRUE` is present for at least one certificate in the chain.
To decode a certificate chain you can run:
```
openssl crl2pkcs7 -nocrl -certfile <CERTIFICATE> | openssl pkcs7 -print_certs -text -noout
```
For example:
```
$ openssl crl2pkcs7 -nocrl -certfile CA.crt | openssl pkcs7 -print_certs -text -noout | grep -e 'X509v3 Basic Constraints' -e 'CA:'
            X509v3 Basic Constraints:
                CA:TRUE
```

To verify, check `csi-zadara-driver` container logs (in any CSI pod), for example:

```
$ kubectl logs -n kube-system zadara-csi-controller-bd4c4858-z8jkd csi-zadara-driver
Jul 11 10:22:18 [INFO] Executing pre-start actions...
Jul 11 10:22:18 [INFO] Add trusted CA certificates:
zadara-csi-tls.crt
Jul 11 10:22:18 [INFO] Installed trusted certificates:
pkcs11:id=%D8%53%1E%C7%82%D1%BC%25%FB%CC%25%DC%1A%F7%70%5F%FB%3A%66%3F;type=cert
    type: certificate
    label: zadaravpsa.com
    trust: anchor
    category: authority
```

#### Using existing Secret

1. Create a Secret with certificates to install. Use the same namespace (typically `kube-system`) where the CSI driver is deployed.
   A Secret may contain any number of certificates.
   The following command will create a Secret named `custom-ca-certs` in namespace `kube-system`, containing certificates from files `CA1.crt` and `CA2.crt`.
```
kubectl create secret -n kube-system generic custom-ca-certs --from-file=CA1.crt --from-file=CA2.crt
```

2. Set `customTrustedCertificates.existingSecret` in `values.yaml`
```
customTrustedCertificates:
  existingSecret: custom-ca-certs
```

#### Provide a certificate directly

Paste `.crt` contents into `customTrustedCertificates.plainText` in  `values.yaml` (contents omitted).

```
customTrustedCertificates:
  plainText: |-
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
```

A Secret will be created during Chart installation.

