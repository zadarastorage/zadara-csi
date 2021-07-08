<!--- helm: 20 -->

## Deploying zadara-csi plugin using Helm charts

Currently, Helm charts are only available locally, in `helm/` subdirectory of this repository.

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
zadara-csi       default         1               2021-07-04 11:29:08.023368123 +0300 IDT deployed        zadara-csi-2.0.0        1.3.2

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
NAME                                                READY   STATUS      RESTARTS   AGE
zadara-csi-csi-autoexpand-sync-27091180-mk5hv       0/1     Completed   0          2m46s
zadara-csi-csi-zadara-controller-84c8884f5c-79v26   6/6     Running     0          6m3s
zadara-csi-csi-zadara-node-58mb6                    3/3     Running     0          6m3s
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

| key                   | description |
|-----------------------|-------------|
`namespace`           | namespace where all CSI pods will run
`image.repository`    | image name on DockerHub
`image.tag`           | image version on DockerHub
`image.pullPolicy`    | `pullPolicy` of the image https://kubernetes.io/docs/concepts/containers/images/#updating-images
`vpsa.url`            |  url or IP of VPSA provisioning Volumes, without `http://` or `https://` prefix
`vpsa.useTLS`         |  whether to use TLS (HTTPS) to access VPSA
`vpsa.verifyTLS`      |  whether to verify TLS certificate when using HTTPS
`vpsa.token`          |  token to access VPSA, e.g `FAKETOKEN1234567-123`
`plugin.provisioner`  |  the name of CSI plugin, for use in StorageClass, e.g. `us-west.csi.zadara.com` or `on-prem.csi.zadara.com`
`plugin.configDir`    |  directory on host FS, where the plugin will look for config, or create one if doesn't exist
`plugin.configName`   |  name of dynamic config
`plugin.iscsiMode`*    |  defines how the plugin will run `iscsiadm` commands on host. Allowed values: `rootfs` or `client-server`.
`plugin.healthzPort`  |  healthzPort is an TCP ports for listening for HTTP requests of liveness probes, needs to be _unique for each plugin instance_ in a cluster.
`plugin.autoExpandSupport`**  |  support for VPSA Volumes [auto-expand feature](http://guides.zadarastorage.com/release-notes/1908/whats-new.html#volume-auto-expand). Set to `false` to disable.
`plugin.autoExpandSupport.schedule`  |  schedule for periodical sync of capacity between VPSA Volumes with auto-expand enabled and Persistent Volume Claims.
`snapshots.apiVersion`*** | apiVersion for CSI Snapshots: `v1beta1`, `v1` (requires K8s >=1.20) or `auto`
`labels`              |  labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary `key: "value"` pairs
`customTrustedCertificates` | additional [custom trusted certificates](#adding-trusted-certificates) to install in CSI pods
`customTrustedCertificates.existingSecret` | name of an existing secret from the same namespace, each key containing a pem-encoded certificate
`customTrustedCertificates.plainText` | create a new secret with the following contents

\* For more info about `plugin.iscsiMode` see [Node iSCSI Connectivity](README.md#node-iscsi-connectivity) section.

\** To enable auto-expand for CSI Volumes, you need to configure [Storage Class](README.md#storage-class) `parameters.volumeOptions`.
Auto-expand requires VPSA version 19.08 or higher. When `plugin.autoExpandSupport` is enabled,
periodical sync will be handled by a CronJob, running in the same namespace as CSI driver.

\*** `auto` option: if CSI Snapshots CRDs are installed, the chart will use API version of CRDs.
If CRDs are not installed, the chart will use `v1` for K8s 1.20+, and `v1beta1` otherwise.

### Adding trusted certificates

CSI Driver can be configured to use HTTPS with custom certificate (e.g. self-signed).

You can either reference a Secret, or provide a certificate directly in `values.yaml` (a Secret will be created automatically).

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

<!--- end -->
