# Troubleshooting tips

In addition to this guide, it can be helpful to get familiar with the following guides:

- [Driver Components](components.md)
- [How it works](how_it_works.md)
- [Hack scripts](hack_scripts.md) (_these will make things a lot easier, we promise_)

## Helm Chart errors

For most common errors, you will be shown an error message after installing the chart. For example:

```
##############################################################################
####   ERROR: Missing required resources                                  ####
##############################################################################
Secret "my-custom-cerificate" not found in namespace "kube-system"
Please, check customTrustedCertificates.existingSecret in your values.yaml
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
- Bad indentation in `my_values.yaml`. Check that lines are indented with *2 spaces* (not tabs). It may be easier to
  start by pulling a default `values.yaml` from the chart:
  ```
  helm show values zadara-csi-helm/zadara-csi > my_values.yaml
  ```
  And then replacing defaults in `my_values.yaml`.

## VPSA in `Unreachable` state

```
$ kubectl get vpsa
NAME          STATUS        DISPLAY NAME   CAPACITY MODE   VSC                      AGE
vpsa-sample   Unreachable   Example VPSA   normal          vscstorageclass-sample   25h
```

Possible reasons:
- Invalid Hostname
- Network issues
- Invalid credentials
- TLS Certificate issues

Typically, you can see the reason in Events for VPSA Custom Resource, for example (see `Events` at the bottom):
```
$ kubectl describe vpsa vpsa-sample
Name:         vpsa-sample
Namespace:
Labels:       <none>
Annotations:  <none>
API Version:  storage.zadara.com/v1
Kind:         VPSA
Metadata:
  Creation Timestamp:  2022-02-23T11:50:05Z
  Finalizers:
    storage.zadara.com/vsc-delete-protection
  Generation:  2
  Resource Version:  35276860
  UID:               2fda23b6-27e7-4d0f-b511-57a60839cbbf
Spec:
  VSC Storage Class Name:  vscstorageclass-sample
  Description:             Demonstrates VPSA resource schema
  Display Name:            Example VPSA
  Hostname:                example.zadaravpsa.com
  Token:                   AES:2v2woQx2cHNhLXNhbXBsZfsBzaDORtEv4oAFGBDRPjTPWORJlYqDTw==
Status:
  Capacity:
    Available:  0
    Total:      0
  Counters:
    Pools:      0
    Snapshots:  0
    Volumes:    0
  State:        Unreachable
  Version:
Events:
  Type     Reason       Age                From        Message
  ----     ------       ----               ----        -------
  Warning  Unreachable  4s (x10 over 10s)  zadara-csi  internal error: REST API client error: Get "http://example.zadaravpsa.com:80/api/pools.json?timeout=180": dial tcp: lookup example.zadaravpsa.com on 10.96.0.10:53: no such host
```

### Reason: Invalid credentials

Example:
```
$ kubectl describe vpsa vpsa-sample
Name:         vpsa-sample
...
Events:
  Type     Reason       Age                     From        Message
  ----     ------       ----                    ----        -------
  Warning  Unreachable  8s (x3 over 11s)        zadara-csi  internal error: N/A (5): Invalid credentials.
```

Resolution: fix the credentials and `kubectl apply` the VPSA again.

### Reason: No connectivity to the VPSA

Example:

```
$ kubectl describe vpsa vpsa-sample
Name:         vpsa-sample
...

Events:
  Type     Reason       Age               From        Message
  ----     ------       ----              ----        -------
  Warning  Unreachable  1s (x5 over 13s)  zadara-csi  internal error: REST API client error: Get "http://10.10.10.10:80/api/pools.json?timeout=180": dial tcp 10.10.10.10:80: connect: no route to host
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

You may need `--insecure` flag, when using custom certificate (e.g, if the certificate is installed in Pods, but not on
host).

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

## Block volumes stuck in `iSCSILoginPending` state

```
$ kubectl get volumeattachment.storage.zadara.com -o wide
NAME                                                       STATUS              ISCSI          VOLUME                                     VSCNODE           AGE
pvc-5939c124-4133-4af7-a783-ec71779a5a40.k8s-base-master   ISCSILoginPending   Disconnected   pvc-5939c124-4133-4af7-a783-ec71779a5a40   k8s-base-master   3s
```

Block volumes require iSCSI connection from the Node to VPSA.
iSCSI sessions are established _after_ Zadara-CSI Controller _attaches_ the Volume to the Node,
and _before_ Zadara-CSI Node _mounts_ the Volume at the Node.

First, check `vscnode` custom resource (one for each k8s Node):

```
$ kubectl get vscnode
NAME          IP             IQN                                       AGE
k8s-master    10.10.100.61   iqn.2005-03.org.open-iscsi:e9c4f0d828cf   26h
k8s-worker1   10.10.100.62   iqn.2005-03.org.open-iscsi:dda6bf751196   26h
k8s-worker2   10.10.100.63   iqn.2005-03.org.open-iscsi:8f772c57be9e   26h
```

If IQN is missing, it usually means that iSCSI packages are  missing or misconfigured on that Node.

⚠ *Reinstall CSI driver after iSCSI configuration changes*.

### Reason: iSCSI packages missing

Check whether `iscsiadm` is present at `PATH`. Do this on each K8s Node:

```
$ which iscsiadm
/usr/bin/iscsiadm
```

To install iSCSI tools follow [the instructions](prerequisites.md#iscsi-initiator-tools)

### Reason: duplicate IQN

This can occur if you install iSCSI packages and then *clone VM image* for each K8s Node.

To check IQN (iSCSI Qualified Name) locally:

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

To check iSCSI connection locally:

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

A session should exist, with target name referring to your VPSA: `iqn.2011-04.com.zadarastorage:vsa-00000016:1` with
IP `10.10.12.2` in this example.

To clean up iSCSI configuration (command arguments follow the above example):

```
$ sudo iscsiadm -m session --logout
Logging out of session [sid: 1, target: iqn.2011-04.com.zadarastorage:vsa-00000016:1, portal: 10.10.12.2,3260]

$ sudo iscsiadm -m node -T iqn.2011-04.com.zadarastorage:vsa-00000016:1 -o delete

$ sudo iscsiadm -m iface -I zadara_10.10.12.2 -o delete
zadara_10.10.12.2 unbound and deleted.
```

## Application Pods or PVCs are in Pending state

TODO: check VolumeAttachments

The most common reason for `Pending` state is failure in Persistent Volume Claims provisioning.

First, make sure that all CSI Pods are up and running. If they are not, follow instructions in previous sections.

Check Pods status:

```
$ kubectl get pods -n kube-system -l app=zadara-csi
NAME                                              READY   STATUS      RESTARTS   AGE
zadara-csi-autoexpand-sync-27099910-vgtkc         0/1     Completed   0          9m25s
zadara-csi-controller-bd4c4858-stvwk              6/6     Running     23         25m
zadara-csi-node-6lvnx                             3/3     Running     4          25m
```

### Reason: StorageClass does not specify VSCStorageClass, and no default VSCStorageClass is defined

Check whether a default VSCStorageClass is present (`DEFAULT` is true):

```shell
$ kubectl get vscsc
NAME                     STATUS   DEFAULT   MEMBERS   CAPACITY MODE   AGE
vscstorageclass-sample   Ready    true      1         normal          20h
```

If no VSCStorageClass is set as default, you must explicitly set `parameters.VSCStorageClassName` in StorageClass.

See [Storage Class example](configuring_storage.md#storage-class) in docs.

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

## Troubleshooting tools

Check out our [Hack scripts](hack_scripts.md) aimed to facilitate diagnostics and debugging.

## General tips

Investigate the problem top-down, from the application level objects (Deployment, StatefulSet) to Pods, to PVCs and
other lower-level resources.

When you find a resource that is causing trouble, drill down: from `kubectl get` (`-o wide` or  `-o yaml` can also help)
, to `kubectl describe` and `kubectl logs` (for pods).

Zadara-CSI driver logs can often provide a directions for resolving the problem.

```
kubectl logs -n kube-system zadara-csi-controller-55df6f8ff6-dtkwt csi-zadara-driver
kubectl logs -n kube-system zadara-csi-node-65tsb                  csi-zadara-driver
```

Note container name: `csi-zadara-driver`, there are multiple containers in CSI pods.

## Contact developers

Submit an issue: https://github.com/zadarastorage/zadara-csi/issues
