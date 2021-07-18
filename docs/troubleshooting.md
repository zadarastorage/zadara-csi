
# Common problems resolution

## Helm Chart errors

For most common errors, you will be shown an error message after installing the chart.
For example:
```
##############################################################################
####   ERROR: Missing required values                                     ####
##############################################################################
It appears that VPSA credentials are not set.
Zadara-CSI Plugin will not be able to reach your VPSA.
To fix:
- Set VPSA credentials. You can use the following example:
cat << EOF > my_values.yaml
---
vpsa:
  url: "example.zadaravpsa.com"
  https: true
  token: "FAKETOKEN1234567-123"
EOF
```

```
##############################################################################
####   WARNING: Missing storage.k8s.io CRDs                               ####
##############################################################################
Chart is configured with snapshots.apiVersion: auto [v1],
but "snapshot.storage.k8s.io/v1" CRDs are not installed.
Volume provisioning functionality is not affected, but you will not be able to create Snapshots.

To install: https://github.com/zadarastorage/zadara-csi/tree/release/helm
Recommended versions:
    K8s >=1.20: snapshot.storage.k8s.io/v1
    K8s  <1.20: snapshot.storage.k8s.io/v1beta1
We strongly advise not to use storage.k8s.io/v1beta1 with K8s 1.20+.
```

Other common problems are:
- Using Helm 2: upgrade to Helm 3.
- Bad indentation in `my_values.yaml`. Check that lines are indented with *2 spaces* (not tabs).
  It may be easier to start by pulling a default `values.yaml` from the chart:
  ```
  helm show values zadara-csi-helm/zadara-csi > my_values.yaml
  ```
  And then replacing defaults in `my_values.yaml`.

## All CSI pods are failing

### Reason: Invalid credentials

Example logs:
```
$ kubectl logs -n kube-system zadara-csi-node-2xxrk csi-zadara-driver
  Jul  5 12:18:14.198122 [csi] [INFO]                   zcsi.(*Plugin).connectToVPSA[ 132] Connecting to VPSA "vsa-00000012-zadara-qa12.zadaravpsa.com"
  Jul  5 12:18:14.200861 [csi] [INFO]       csicommon.(*nonBlockingGRPCServer).serve[ 107] Listening for connections on address: &net.UnixAddr{Name:"//csi/csi.sock", Net:"unix"}
  Jul  5 12:18:14.329167 [general] [ERRO]                       zrestapi.parseHeaderImpl[ 471] received an erroneous JSON response: {"status":5,"message":"Invalid credentials."}
  Jul  5 12:18:14.329742 [general] [WARN]                       zrestapi.parseHeaderImpl[ 487] received an erroneous JSON response: {"status":5,"message":"Invalid credentials."}
  Jul  5 12:18:14.329931 [csi] [ERRO]                             zcsi.(*Plugin).Run[ 105] Failed to connect to VPSA: failed to check whether Node k8s-base-master is configured as VPSA Server: N/A (5): Invalid credentials.
  Jul  5 12:18:25.964241 [csi] [ERRO]                              csicommon.logGRPC[ 126] GRPC error: rpc error: code = FailedPrecondition desc = Failed to connect to VPSA: failed to check whether Node k8s-base-master is configured as VPSA Server: N/A (5): Invalid credentials.
```

Resolution: fix the credentials and reinstall the Helm Chart.

### Reason: No connectivity to the VPSA

Example logs:
```
$ kubectl logs -n kube-system zadara-csi-controller-68f4585cb4-r9stg csi-zadara-driver
  Jul 18 09:16:53.068878 [csi] [ERRO]                 zcsi.(*Plugin).healthCheckVPSA[ 117] Failed to check VPSA health: REST API client error: Get "https://abcd.zadaravpsa.com:443/api/pools.json?timeout=180": dial tcp: lookup abcd.zadaravpsa.com on 10.96.0.10:53: no such host
  Jul 18 09:16:53.068998 [csi] [ERRO]                              csicommon.logGRPC[ 126] GRPC error: rpc error: code = FailedPrecondition desc = Failed to check VPSA health: REST API client error: Get "https://abcd.zadaravpsa.com:443/api/pools.json?timeout=180": dial tcp: lookup abcd.zadaravpsa.com on 10.96.0.10:53: no such host
  Jul 18 09:16:54.622126 [csi] [ERRO]                 zcsi.(*Plugin).healthCheckVPSA[ 117] Failed to check VPSA health: REST API client error: Get "https://abcd.zadaravpsa.com:443/api/pools.json?timeout=180": dial tcp: lookup abcd.zadaravpsa.com on 10.96.0.10:53: no such host
  Jul 18 09:16:54.622565 [csi] [ERRO]                              csicommon.logGRPC[ 126] GRPC error: rpc error: code = FailedPrecondition desc = Failed to check VPSA health: REST API client error: Get "https://abcd.zadaravpsa.com:443/api/pools.json?timeout=180": dial tcp: lookup abcd.zadaravpsa.com on 10.96.0.10:53: no such host
```

Use `ping` or `curl` to test connection to the VPSA from K8s Nodes.

```
$ ping vsa-00000016-zadara-qa.zadaravpsa.com
PING vsa-00000016-zadara-qa.zadaravpsa.com (10.10.12.2) 56(84) bytes of data.
64 bytes from vsa-00000016-zadara-qa.zadaravpsa.com (10.10.12.2): icmp_seq=1 ttl=64 time=0.373 ms
64 bytes from vsa-00000016-zadara-qa.zadaravpsa.com (10.10.12.2): icmp_seq=2 ttl=64 time=0.373 ms
```

```
$ curl --insecure https://vsa-00000016-zadara-qa.zadaravpsa.com
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />

    ...
```
You may need `--insecure` flag, when using custom certificate (e.g if the certificate is installed in Pods, but not on host).

### Reason: Certificate issues

Example logs:
```
$ kubectl logs -n kube-system zadara-csi-controller-bd4c4858-stvwk csi-zadara-driver
  Jul 11 08:56:09.015771 [csi] [ERRO]                 zcsi.(*Plugin).healthCheckVPSA[ 117] Failed to check VPSA health: REST API client error: Get "https://vsa-00000016-zadara-qa12.zadaravpsa.com:443/api/pools.json?timeout=180": x509: certificate signed by unknown authority (possibly because of "x509: invalid signature: parent certificate cannot sign this kind of certificate" while trying to verify candidate authority certificate "zadaravpsa.com")
  Jul 11 08:56:09.015867 [csi] [ERRO]                              csicommon.logGRPC[ 126] GRPC error: rpc error: code = FailedPrecondition desc = Failed to check VPSA health: REST API client error: Get "https://vsa-00000016-zadara-qa12.zadaravpsa.com:443/api/pools.json?timeout=180": x509: certificate signed by unknown authority (possibly because of "x509: invalid signature: parent certificate cannot sign this kind of certificate" while trying to verify candidate authority certificate "zadaravpsa.com")
  Jul 11 08:56:09.379625 [csi] [ERRO]                 zcsi.(*Plugin).healthCheckVPSA[ 117] Failed to check VPSA health: REST API client error: Get "https://vsa-00000016-zadara-qa12.zadaravpsa.com:443/api/pools.json?timeout=180": x509: certificate signed by unknown authority (possibly because of "x509: invalid signature: parent certificate cannot sign this kind of certificate" while trying to verify candidate authority certificate "zadaravpsa.com")
```

#### Troubleshooting custom trusted certificate

Check that certificate is present in `csi-zadara-driver` (you can choose any CSI Pod to `exec` this):
```
$ kubectl exec -n kube-system zadara-csi-controller-bd4c4858-stvwk -c csi-zadara-driver -- ls /etc/pki/ca-trust/source/anchors/
zadara-csi-tls.crt
```
Certificate file (or files) is expected to be present in `/etc/pki/ca-trust/source/anchors/`

Check that the certificate is recognized correctly (best with `head`, it's a very long list):
```
$ kubectl exec -n kube-system zadara-csi-controller-bd4c4858-stvwk -c csi-zadara-driver -- bash -c 'trust list | head -n 12'
pkcs11:id=%D8%53%1E%C7%82%D1%BC%25%FB%CC%25%DC%1A%F7%70%5F%FB%3A%66%3F;type=cert
    type: certificate
    label: zadaravpsa.com
    trust: anchor
    category: authority

pkcs11:id=%D2%87%B4%E3%DF%37%27%93%55%F6%56%EA%81%E5%36%CC%8C%1E%3F%BD;type=cert
    type: certificate
    label: ACCVRAIZ1
    trust: anchor
    category: authority
```

Your certificate should appear at the top, and should have `category: authority`.

## CSI Controller pod is failing

### Reason: VPSA health check failed

`csi-zadara-driver` container in CSI *Controller* pod is responsible to check VPSA health periodically,
triggered by K8s liveness probe.

It uses VPSA REST API to check that:
- VPSA has at least one storage pool (required prerequisite)
- all storage pools are in `Normal' state

Example logs:
```
  Jul 18 09:21:33.786818 [csi] [ERRO]                 zcsi.(*Plugin).healthCheckVPSA[ 120] VPSA not ready for Volume provisioning: no pools found
  Jul 18 09:21:33.786951 [csi] [ERRO]                              csicommon.logGRPC[ 126] GRPC error: rpc error: code = FailedPrecondition desc = VPSA not ready for Volume provisioning: no pools found
  Jul 18 09:21:34.852034 [csi] [ERRO]                 zcsi.(*Plugin).healthCheckVPSA[ 120] VPSA not ready for Volume provisioning: no pools found
  Jul 18 09:21:34.852156 [csi] [ERRO]                              csicommon.logGRPC[ 126] GRPC error: rpc error: code = FailedPrecondition desc = VPSA not ready for Volume provisioning: no pools found

  Jul 18 09:22:23.222382 [csi] [ERRO]                 zcsi.(*Plugin).healthCheckVPSA[ 124] VPSA not ready for Volume provisioning: pool pool-00010002 (P2) in "creating" state
  Jul 18 09:22:23.222512 [csi] [ERRO]                              csicommon.logGRPC[ 126] GRPC error: rpc error: code = FailedPrecondition desc = VPSA not ready for Volume provisioning: pool pool-00010002 (P2) in "creating" state
```


## CSI Node pods are failing

CSI Node component runs as a DaemonSet, i.e. one Pod on each Node.

* If all Node pods are failing: check Node pods logs.
  Typically, this is caused by iSCSI configuration issues or network problems.


* Some specific pods are failing: check the problematic Node (iSCSI packages, connectivity).
You can use `-o wide` option to see on which Node the Pod is running:
    ```
    $ kubectl get pods -n kube-system -l provisioner=csi.zadara.com -l app.kubernetes.io/component=node -o wide
    NAME                    READY   STATUS    RESTARTS   AGE   IP             NODE              NOMINATED NODE   READINESS GATES
    zadara-csi-node-6lvnx   3/3     Running   4          18m   10.10.100.34   k8s-base-master   <none>           <none>
    ```

Resolution guidelines are the same as in the [following section](#servers-are-not-created-on-vpsa)

## Servers are not created on VPSA

- No Servers at all: iSCSI packages missing or misconfigured

- Less Servers than expected:
  - iSCSI packages missing or misconfigured on some Nodes
  - some Nodes have duplicate IQN

iSCSI-related commands can be executed either on a Node (requires root permissions), or in `zadara-csi-driver` container of CSI Node Pod (without `sudo`).
You can use `hack/shell.sh node` for this.

It's recommended to *uninstall CSI driver before applying iSCSI changes*.

### Reason: iSCSI packages missing

Check whether `iscsiadm` is present at `PATH`:
```
$ which iscsiadm
/usr/bin/iscsiadm
```

To install iSCSI tools follow [the instructions](README.md#iscsi-initiator-tools)

### Reason: duplicate IQN

This can occur if you install iSCSI packages and then *clone VM image* for each K8s Node.

To check IQN (iSCSI Qualified Name):
```
$ sudo cat /etc/iscsi/initiatorname.iscsi
InitiatorName=iqn.1993-08.org.debian:01:458917df7e2f
```

To change IQN:
```
# Generate new name
sudo iscsi-iname > /etc/iscsi/initiatorname.iscsi

# Restart iSCSI to apply changes
systemctl restart iscsid
```


### Reason: iSCSI misconfigured

To test iSCSI connection:
```
$ sudo iscsiadm -m session
tcp: [1] 10.10.12.2:3260,1 iqn.2011-04.com.zadarastorage:vsa-00000016:1 (non-flash)

$ sudo iscsiadm -m node
10.10.12.2:3260,-1 iqn.2011-04.com.zadarastorage:vsa-00000016:1

$ sudo iscsiadm -m iface
default tcp,<empty>,<empty>,<empty>,<empty>
iser iser,<empty>,<empty>,<empty>,<empty>
zadara_10.10.12.2 tcp,<empty>,<empty>,<empty>,<empty>
```

A session should exist, with target name referring to your VPSA: `iqn.2011-04.com.zadarastorage:vsa-00000016:1` with IP `10.10.12.2` in this example.

To cleanup iSCSI configuration (command arguments follow the above example):
```
$ sudo iscsiadm -m session --logout
Logging out of session [sid: 1, target: iqn.2011-04.com.zadarastorage:vsa-00000016:1, portal: 10.10.12.2,3260]

$ sudo iscsiadm -m node -T iqn.2011-04.com.zadarastorage:vsa-00000016:1 -o delete

$ sudo iscsiadm -m iface -I zadara_10.10.12.2 -o delete
zadara_10.10.12.2 unbound and deleted.
```

## Application Pods or PVCs are in Pending state

The most common reason for `Pending` state is failure in Persistent Volume Claims provisioning.

First, make sure that all CSI Pods are up and running.
If they are not, follow instructions in previous sections.

Check Pods status:
```
$ kubectl get pods -n kube-system -l provisioner=csi.zadara.com
NAME                                              READY   STATUS      RESTARTS   AGE
zadara-csi-autoexpand-sync-27099910-vgtkc         0/1     Completed   0          9m25s
zadara-csi-controller-bd4c4858-stvwk              6/6     Running     23         25m
zadara-csi-node-6lvnx                             3/3     Running     4          25m
```

### Reason: Storage pool ID is missing

If your VPSA has multiple Storage Pools, it is required to specify `poolid` in StorageClass `parameters`

```
  Jul 18 09:58:12.762766 [csi] [WARN]         zcsi.(*ControllerServer).resolvePoolId[ 373] Storage Pool Id is missing and VPSA has multiple storage pools: ['pool-00010001', 'pool-00010002'] - driver cannot decide which to use. Please provide Pool Id.
```

See [Storage Class example](README.md#storage-class) in docs.

### Reason: PVC does not specify `storageClass`, and no default StorageClass is defined

```
$ kubectl describe pvc my-pvc
Name:          my-pvc
Namespace:     default
StorageClass:
Status:        Pending
Volume:
Labels:        <none>
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason         Age   From                         Message
  ----    ------         ----  ----                         -------
  Normal  FailedBinding  10s   persistentvolume-controller  no persistent volumes available for this claim and no storage class is set
```

Here, we have one StorageClass, and it is not defined as default:
```
$ kubectl get sc
NAME          PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
io-test-nas   csi.zadara.com   Delete          Immediate           true                   8m33s
```

Replace `NEW_DEFAULT_SC` with StorageClass name, such as `io-test-nas`:
```
$ kubectl patch sc NEW_DEFAULT_SC -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Now it appears as default:
```
$ kubectl get sc
NAME                    PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
io-test-nas (default)   csi.zadara.com   Delete          Immediate           true                   15m
```


# Troubleshooting tips and tools

## General tips

Investigate the problem top-down, from the application level objects (Deployment, StatefulSet) to Pods,
to PVCs and other lower-level resources.

When you find a resource that is causing trouble, drill down: from `kubectl get` (`-o wide` or  `-o yaml` can also help),
to `kubectl describe` and `kubectl logs` (for pods).

Zadara-CSI driver logs can often provide a directions for resolving the problem.
```
kubectl logs -n kube-system zadara-csi-controller-55df6f8ff6-dtkwt csi-zadara-driver
kubectl logs -n kube-system zadara-csi-node-65tsb                  csi-zadara-driver
```
Note container name: `csi-zadara-driver`, there are multiple containers in CSI pods.

## Tools
In this repo you can find [helper scripts](https://github.com/zadarastorage/zadara-csi/tree/release/hack)
for troubleshooting:

```
$ ./hack/logs.sh -h
Display logs of a Zadara-CSI Pod
Usage: ./hack/logs.sh <node|controller> [-l] [-f] [-n k8s-node] [-r helm-release-name]
    -l:                   Pipe to 'less' (can be combined with -f)
    -f:                   Use 'follow' option
    -n k8s-node:          Node name as appears in 'kubectl get nodes', or IP
                          If not specified - show logs for the 1st node/controller pod in list
    -r helm-release-name: Helm release name as appears in 'helm list'
                          Required if you have multiple instances of CSI plugin
Examples:
  ./hack/logs.sh controller -f
  ./hack/logs.sh controller -r warped-seahorse
  ./hack/logs.sh node -n 192.168.0.12 -r warped-seahorse
  ./hack/logs.sh node -n worker0 -lf
```


```
$ ./hack/shell.sh -h
Open an interactive shell in Zadara-CSI Pod
Usage: ./hack/shell.sh <node|controller> [-n k8s-node] [-r helm-release-name]
    -n k8s-node:          Node name as appears in 'kubectl get nodes', or IP
                          If not specified - show logs for the 1st node/controller pod in list
    -r helm-release-name: Helm release name as appears in 'helm list'
                          Required if you have multiple instances of CSI plugin
```

## Contact developers

Submit an issue: https://github.com/zadarastorage/zadara-csi/issues
