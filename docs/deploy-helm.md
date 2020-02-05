<!--- helm: 20 -->

## Deploying zadara-csi plugin using Helm charts

Currently Helm charts are only available locally, as part of this repository.

1. Copy `helm` directory from this repository to your current working directory.

2. Edit or create [values.yaml](../helm/zadara-csi/values.yaml) and set CSI driver version and VPSA credentials.

    ```yaml
    image:
      repository: zadara/csi-driver
      tag: 1.2.1
      pullPolicy: IfNotPresent
    vpsa:
      url: "example.zadaravpsa.com"
      https: true
      token: "FAKETOKEN1234567-123"
    plugin:
      provisioner: csi.zadara.com
      configDir: "/etc/csi"
      configName: "zadara-csi-config.yaml"
      iscsiMode: "rootfs"
      healthzPort: 9808
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
  `vpsa.https`          |  whether to use HTTPS or HTTP to access VPSA
  `vpsa.token`          |  token to access VPSA, e.g `FAKETOKEN1234567-123`
  `plugin.provisioner`  |  the name of CSI plugin, for use in StorageClass, e.g. `us-west.csi.zadara.com` or `on-prem.csi.zadara.com`
  `plugin.configDir`    |  directory on host FS, where the plugin will look for config, or create one if doesn't exist
  `plugin.configName`   |  name of dynamic config
  `plugin.iscsiMode`    |  defines how the plugin will run `iscsiadm` commands on host. Allowed values: `rootfs` or `client-server`.
  `plugin.healthzPort`  |  healthzPort is an TCP ports for listening for HTTP requests of liveness probes, needs to be _unique for each plugin instance_ in a cluster.
  `labels`              |  labels to attach to all Zadara-CSI objects, can be extended with any number of arbitrary `key: "value"` pairs

For more info about `plugin.iscsiMode` see [Node iSCSI Connectivity](README.md#node-iscsi-connectivity) section.

<!--- end -->
