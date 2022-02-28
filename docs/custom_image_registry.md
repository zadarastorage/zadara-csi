# Using custom image registry

All Helm charts we provide can work with a local image registry.

To configure, replace all `image.NAME.repository` fields in `my_values.yaml`.

For example, here is an excerpt of `my_values.yaml` for [zadara-csi Chart](../helm/zadara-csi),
assuming the registry is running at `my.registry.com:5000`:
```
image:
  csiDriver:
    repository: "my.registry.com:5000/zadara/csi-driver"
  provisioner:
    repository: "my.registry.com:5000/sig-storage/csi-provisioner"
  attacher:
    repository: "my.registry.com:5000/sig-storage/csi-attacher"
  resizer:
    repository: "my.registry.com:5000/sig-storage/csi-resizer"
  livenessProbe:
    repository: "my.registry.com:5000/sig-storage/livenessprobe"
  nodeDriverRegistrar:
    repository: "my.registry.com:5000/sig-storage/csi-node-driver-registrar"
  snapshotter:
    repository: "my.registry.com:5000/sig-storage/csi-snapshotter"
```

## Authentication with a registry

In this example, we will use `imagePullSecrets` to access a *private* image registry.
The registry is running at `my.registry.com:5000`, username `admin` and password `password`.

You can use registry REST API to check that all required images are available:

List repositories:
```
$ curl --silent admin:password@my.registry.com:5000/v2/_catalog | jq
{
  "repositories": [
    "snapshot-controller"
  ]
}
```

List repository tags:
```
$ # /v2/<REPOSITORY>/tags/list
$ curl --silent admin:password@my.registry.com:5000/v2/snapshot-controller/tags/list | jq
{
  "name": "snapshot-controller",
  "tags": [
    "v4.1.1"
  ]
}
```

### Create Secrets

See also [examples in K8s documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

First, login into the local registry to create `.docker/config.json` file that holds an authorization token:
```
$ docker login my.registry.com:5000
Username: admin
Password:
WARNING! Your password will be stored unencrypted in /home/$USER/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

Create a Secret, containing registry credentials.
The Secret must be created in the same Namespace where CSI driver is deployed (typicaly `kube-system`):
```
$ kubectl create secret --namespace kube-system generic my-registry-com --from-file=.dockerconfigjson=/home/$USER/.docker/config.json --type=kubernetes.io/dockerconfigjson
secret/my-registry-com created
```

Verify Secret creation:
```
$ kubectl get secrets -n kube-system my-registry-com --output=yaml
apiVersion: v1
data:
  .dockerconfigjson: ewoJImF1dGhzIjogewoJCSJteS5yZWdpc3RyeS5jb206NTAwMCI6IHsKCQkJImF1dGgiOiAiWVdSdGFXNDZjR0Z6YzNkdmNtUT0iCgkJfQoJfQp9
kind: Secret
metadata:
  creationTimestamp: "2021-07-11T11:32:04Z"
  name: my-registry-com
  namespace: kube-system
  resourceVersion: "3989046"
  uid: a09dafac-11be-4cb0-abdd-e6c5d30d4f50
type: kubernetes.io/dockerconfigjson
```

---

## Use imagePullSecrets

Now you are ready to install the Helm Chart.
The following example shows how to configure`values.yaml` for [snapshots-v1 Chart](../helm/snapshots-v1).
Same instructions apply to other Charts.

Create `my_values.yaml` for the Helm Chart.
In this example we override `snapshotController.image` with a reference to a private registry `my.registry.com:5000`.
Credentials for the registry are passed in Secret `my-registry-com` that we have created earlier.
```
$ cat my_values.yaml

snapshotController:
  image: my.registry.com:5000/snapshot-controller:v4.1.1

imagePullSecrets:
  - "my-registry-com"
```

Install the chart:

```
$ helm install csi-snapshots-v1 -f ./my_values.yaml zadara-csi-helm/snapshots-v1
```


