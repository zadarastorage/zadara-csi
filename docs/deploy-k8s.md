## Deploying zadara-csi plugin on Kubernetes

### Choose your version

Directory `deploy` contains YAML files organized by K8s versions.

For each version, we provide two options of plugin deployment with different approaches to manage iSCSI connectivity
(see [Node iSCSI Connectivity](README.md#node-iscsi-connectivity) section),
 available in `deploy/<k8s-version-dir>/rootfs` and `deploy/<k8s-version-dir>/client-server`.

For more convenience, we suggest creating a symlink to a directory of your choice:
```shell script
ln -sfT  <k8s-version-dir>/<rootfs|client-server>  deploy/current
# Example:
ln -sfT  k8s-1.16/client-server  deploy/current
```
Or to skip Node iSCSI Connectivity part and choose default:
```shell script
ln -sfT  <k8s-version-dir>/  deploy/current
# Example:
ln -sfT  k8s-1.16  deploy/current
```

---

### Configuration

#### Secrets management

Before deploying Zadara-CSI plugin, edit `deploy/current/secrets.yaml` and set VPSA credentials.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vpsa-access-token
  namespace: zadara
stringData:
  access-token: "FAKETOKEN1234567-123"
```

- Get access token from VPSA, and paste into `access-token`.
- Run `kubectl create -f deploy/current/secrets.yaml`. This will create a Secret object in Kubernetes.
- To verify, run `kubectl --namespace zadara get secrets`, `vpsa-access-token` should appear in output.
- Remove `secrets.yaml`, to keep your secrets safe.

#### Plugin arguments

Edit following parameters in `controller.yaml` and `node.yaml`.
In most cases, only `hostname`, and `secure` need to be changed.

| parameter | description | required | examples |
|-----------|-----------|-----------|----------|
| `hostname` | VPSA hostname, or IP  | Yes | `example.zadaravpsa.com`, `10.0.10.1`
| `secure` | Whether or not to use HTTPS | No. Defaults to `true` | `true`, `false`, `0`, `1`. <br>Pass as `--secure=false`
|`name` | Plugin name, to identify plugin instance and use in `provisioner` field of StorageClass  | No. Defaults to `csi.zadara.com` | `us-west.csi.zadara.com`, `on-prem.csi.zadara.com`, `all-flash.csi.zadara.com`
|`nodeid` | Kubernetes Node id | No. Defaults to hostname of a current node, as returned by `uname -n` | `VM-001`, `node42`

Plugin arguments appear in `controller.yaml` and `node.yaml` similar to the following snippet:
```yaml
    - name: csi-zadara-driver
      image: "zadara/csi-driver:1.2.2"
      imagePullPolicy: "IfNotPresent"
      args:
        - "--hostname=example.zadaravpsa.com"
        - "--secure=true"
        - "--name=csi.zadara.com"
```

#### Volume auto-expand support

To enable support for [VPSA auto-expand feature](http://guides.zadarastorage.com/release-notes/1908/whats-new.html#volume-auto-expand),
edit `expander.yaml` and set `hostname`, and `secure` parameters, as explained [above](#plugin-arguments).
Optionally, other CronJob parameters, like `schedule`, `successfulJobsHistoryLimit`, `failedJobsHistoryLimit` can be configured.

To enable auto-expand for CSI Volumes, you need to configure [Storage Class](README.md#storage-class) `parameters.volumeOptions`.
Auto-expand requires VPSA version 19.08 or higher. When `plugin.autoExpandSupport` is enabled,
periodical sync will be handled by a CronJob, running in the same namespace as CSI driver.

---

### Deployment

1. Create [secrets](#secrets-management)
2. Update [plugin arguments](#plugin-arguments)
3. Deploy CSI Driver components:
    ```shell script
    kubectl create -f deploy/current/csi-driver.yaml
    kubectl create -f deploy/current/csi-configmap.yaml
    kubectl create -f deploy/current/node.yaml
    kubectl create -f deploy/current/controller.yaml
    ```
4. Optional: [auto-expand support](#volume-auto-expand-support)
    ```shell script
    kubectl create -f deploy/current/expander.yaml
    ```

### Cleanup

To delete CSI Driver and all related resources:
```shell script
kubectl delete cronjob        -n zadara -l app=zadara-csi
kubectl delete daemonset      -n zadara -l app=zadara-csi
kubectl delete deployment     -n zadara -l app=zadara-csi
kubectl delete configmap      -n zadara -l app=zadara-csi
kubectl delete secret         -n zadara -l app=zadara-csi
kubectl delete serviceaccount -n zadara -l app=zadara-csi
kubectl delete clusterrolebinding -l app=zadara-csi
kubectl delete clusterrole        -l app=zadara-csi
kubectl delete csidriver          -l app=zadara-csi
```
