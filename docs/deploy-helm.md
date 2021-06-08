<!--- helm: 20 -->

## Deploying zadara-csi plugin using Helm charts

Currently Helm charts are only available locally, as part of this repository.

1. Copy `helm` directory from this repository to your current working directory.

2. Edit or create [values.yaml](../helm/zadara-csi/values.yaml) and set CSI driver version and VPSA credentials.

    ```yaml
    image:
      repository: zadara/csi-driver
      tag: 1.3.1
      pullPolicy: IfNotPresent
    vpsa:
      url: "example.zadaravpsa.com"
      useTLS: true
      verifyTLS: true
      token: "FAKETOKEN1234567-123"
    plugin:
      provisioner: csi.zadara.com
      iscsiMode: "rootfs"
      healthzPort: 9808
      autoExpandSupport:
        schedule: "*/10 * * * *"
    labels:
      stage: "production"
    ```
      If you intend to deploy multiple Zadara-CSI instances on the same cluster, set also `plugin.provisioner`
      (this is the same `provisioner` name you will use in StorageClass definition)
      to be unique for each instance. Some name describing underlying VPSA, like `all-flash.csi.zadara.com`,
      or `us-east.csi.zadara.com` will be a good choice.

3. Deploy

   - Helm 2:
       ```
       $ helm install helm/zadara-csi
       ```
       or with a different YAML for values, e.g. `my_values.yaml`:
       ```
       $ helm install -f my_values.yaml helm/zadara-csi
       ```

   - Helm 3 users need to specify release name, e.g. `zadara-csi-driver`, or use `--generate-name` flag:
       ```
       $ helm install zadara-csi-driver helm/zadara-csi
       $ helm install --generate-name   helm/zadara-csi

       $ helm install zadara-csi-driver -f my_values.yaml helm/zadara-csi
       $ helm install --generate-name   -f my_values.yaml helm/zadara-csi
       ```

   You can verify resulting YAML files by adding `--dry-run --debug` options to above commands.

4. Verify installation
   ```
   $ helm list
   NAME               NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
   zadara-csi-driver  default         1               2020-02-03 12:42:56.468379418 +0200 IST deployed        zadara-csi-1.1.0        1.2.0

   $ helm status zadara-csi-driver
   NAME: zadara-csi-driver
   LAST DEPLOYED: Mon Feb  3 12:42:56 2020
   NAMESPACE: default
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   ##############################################################################
   ####   Successfully installed Zadara-CSI                                  ####
   ##############################################################################
   Thank you for installing zadara-csi!
   Your release is named csi-helm-3

   Try following example to create a NAS volume on your VPSA:
   ...
   ```

5. Uninstall

   - Helm 2:
       ```
       $ helm delete zadara-csi-driver
       ```
   - Helm 3:
       ```
       $ helm uninstall zadara-csi-driver
       ```
    Replace `zadara-csi-driver` with your release name, as appears in `helm list`.

---

### Values explained

| key                   | description |
|-----------------------|-------------|
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
  `labels`              |  labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary `key: "value"` pairs
  `customTrustedCertificates` | additional [custom trusted certificates](#adding-trusted-certificates) to install in CSI pods
  `customTrustedCertificates.existingSecret` | name of an existing secret from the same namespace, each key containing a pem-encoded certificate
  `customTrustedCertificates.plainText` | create a new secret with the following contents

\* For more info about `plugin.iscsiMode` see [Node iSCSI Connectivity](README.md#node-iscsi-connectivity) section.

\** To enable auto-expand for CSI Volumes, you need to configure [Storage Class](README.md#storage-class) `parameters.volumeOptions`.
    Auto-expand requires VPSA version 19.08 or higher. When `plugin.autoExpandSupport` is enabled,
    periodical sync will be handled by a CronJob, running in the same namespace as CSI driver.

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
  plainText: -|
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
```

A Secret will be created during Chart installation.

<!--- end -->
