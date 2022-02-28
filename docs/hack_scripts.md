# Hack scripts

In this repo you can find [helper scripts](https://github.com/zadarastorage/zadara-csi/tree/release/hack)
for troubleshooting:

🛈 It is [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes/tree/master/hack) convention to use `./hack` as a direcotry for all development, CI/CD and debugging scripts.

## K8Dig - generic diagnostics script

```
$ ./hack/k8dig.py --help
usage: k8dig.py [-h] {all,pods,po,pod,storage,crd,crds} ...

Diagnostic tool for k8s application

optional arguments:
  -h, --help            show this help message and exit

Commands:
  {all,pods,po,pod,storage,crd,crds}
    all                 Overview of all resources
    pods (po, pod)      Pod utils
    storage             Storage utils
    crd (crds)          CRD utils
```

- The script requires `kubectl` with a proper `kubeconfig` to reach your cluster
- Python 3 is required
- Without any arguments the script will show failed pods and containers (if any).

### List all Zadara Custom Resources

⚠ Something does not work, not sure where to look? Run this:

```
$ ./hack/k8dig.py crd zadara -v
```

- `zadara` is an optional filter to show only Custom Resources with "zadara"
  in CRD name (as seen in `kubectl get crd`).
- `-v` prints `kubectl` commands.

Example output:
```
snapshot.storage.zadara.com
$ kubectl get snapshot.storage.zadara.com -o wide
  NAME                                            STATUS   VOLUME                                     AGE
  snapshot-95730c4a-d78b-4ca3-a6d2-9b91eeb20877   Ready    pvc-6643b234-7d69-4ace-977a-24e762831fbf   22h

volumeattachment.storage.zadara.com
$ kubectl get volumeattachment.storage.zadara.com -o wide
  NAME                                                       STATUS   ISCSI       VOLUME                                     VSCNODE           AGE
  pvc-6643b234-7d69-4ace-977a-24e762831fbf.k8s-base-master   Ready    N/A (NAS)   pvc-6643b234-7d69-4ace-977a-24e762831fbf   k8s-base-master   22h
  pvc-7273e587-77f0-4a53-a739-69050721c94f.k8s-base-master   Ready    Active      pvc-7273e587-77f0-4a53-a739-69050721c94f   k8s-base-master   22h
  pvc-c6562fbf-2957-4042-abff-0f191997c7e7.k8s-base-master   Ready    N/A (NAS)   pvc-c6562fbf-2957-4042-abff-0f191997c7e7   k8s-base-master   22h
  pvc-d7616222-3c6a-4d4c-9c74-45f107e85e3a.k8s-base-master   Ready    Active      pvc-d7616222-3c6a-4d4c-9c74-45f107e85e3a   k8s-base-master   22h

volume.storage.zadara.com
$ kubectl get volume.storage.zadara.com -o wide
  NAME                                       STATUS   TYPE    CAPACITY   VPSA          AGE
  pvc-6643b234-7d69-4ace-977a-24e762831fbf   Ready    NAS     50Gi       vpsa-sample   22h
  pvc-7273e587-77f0-4a53-a739-69050721c94f   Ready    Block   50Gi       vpsa-sample   22h
  pvc-8ae82eb0-31f3-48ee-936f-e7583d80e281   Ready    NAS     50Gi       vpsa-sample   22h
  pvc-bec1dd14-5689-4179-99a1-1075b88eeef2   Ready    NAS     50Gi       vpsa-sample   22h
  pvc-c6562fbf-2957-4042-abff-0f191997c7e7   Ready    NAS     50Gi       vpsa-sample   22h
  pvc-d7616222-3c6a-4d4c-9c74-45f107e85e3a   Ready    Block   50Gi       vpsa-sample   22h

vpsa.storage.zadara.com
$ kubectl get vpsa.storage.zadara.com -o wide
  NAME          STATUS   DISPLAY NAME   HOSTNAME                                 VERSION      CAPACITY MODE   TOTAL      AVAILABLE   VSC                      AGE
  vpsa-other    Ready    Another VPSA   vsa-0000029d-zadara-qa9.zadaravpsa.com   22.06-1000   normal          9210Gi     9418093Mi   vscstorageclass-sample   23h
  vpsa-sample   Ready    Example VPSA   vsa-0000028d-zadara-qa9.zadaravpsa.com   22.06-1000   normal          743296Mi   723256Mi    vscstorageclass-sample   23h

vscnode.storage.zadara.com
$ kubectl get vscnode.storage.zadara.com -o wide
  NAME              IP             IQN                                       AGE
  k8s-base-master   10.10.100.61   iqn.2005-03.org.open-iscsi:e9c4f0d828cf   23h

vscstorageclass.storage.zadara.com
$ kubectl get vscstorageclass.storage.zadara.com -o wide
  NAME                     STATUS   DEFAULT   MEMBERS   CAPACITY MODE   TOTAL        AVAILABLE    AGE
  vscstorageclass-sample   Ready    true      2         normal          10174336Mi   10141349Mi   23h
```

### Dig pods

`./hack/k8dig.py pods` helps to find which containers are failing in Pods, and help to inspect them further.

```
$ ./hack/k8dig.py pods --help
usage: k8dig.py pods [-h] [-v] [--all] [-n NAMESPACE] [--logs] [--tail TAIL]
                     [pod_pattern]

positional arguments:
  pod_pattern           Name of Pod (partial names allowed)

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         Show kubectl commands to dig even deeper
  --all                 Show all pods (by default only unhealthy are shown)
  -n NAMESPACE, --namespace NAMESPACE
                        Namespace
  --logs                Print container logs
  --tail TAIL           How much logs to show (default: 16)
```

#### Pods and container readiness status

```
$ ./hack/k8dig.py pods zadara -v --all
```

- `zadara` in the following example is an optional filter to show only pods with "zadara" in the name.
- `-v` prints `kubectl` commands for pods and their owners (e.g, Deployments, StatefulSets or Jobs).
- `--all` will show all matching pods (by default only unhealthy are shown)

<details>
<summary>Click to show example output:</summary>

```
POD [OK]: kube-system/zadara-csi-controller-5f4b9fbc7c-kp4jh | Owners: [ReplicaSet kube-system/zadara-csi-controller-5f4b9fbc7c]
  $ kubectl describe deployment -n kube-system zadara-csi-controller
  $ kubectl describe replicaset -n kube-system zadara-csi-controller-5f4b9fbc7c
  $ kubectl describe pod -n kube-system zadara-csi-controller-5f4b9fbc7c-kp4jh
    csi-attacher                  : Ready
    csi-provisioner               : Ready
    csi-resizer                   : Ready
    csi-snapshotter               : Ready
    csi-zadara-driver             : Ready
    liveness-probe                : Ready
POD [OK]: kube-system/zadara-csi-node-2sv8p | Owners: [DaemonSet kube-system/zadara-csi-node]
  $ kubectl describe daemonset -n kube-system zadara-csi-node
  $ kubectl describe pod -n kube-system zadara-csi-node-2sv8p
    csi-node-driver-registrar     : Ready
    csi-zadara-driver             : Ready
    liveness-probe                : Ready
POD [OK]: kube-system/zadara-csi-stonith-844855c488-hdm4h | Owners: [ReplicaSet kube-system/zadara-csi-stonith-844855c488]
  $ kubectl describe deployment -n kube-system zadara-csi-stonith
  $ kubectl describe replicaset -n kube-system zadara-csi-stonith-844855c488
  $ kubectl describe pod -n kube-system zadara-csi-stonith-844855c488-hdm4h
    csi-zadara-stonith            : Ready
```

</details>

#### Pods and containers with logs

```
$ ./hack/k8dig.py pods -v --logs --tail 10
```

The following example shows a case when `zadara-csi-controller-5f4b9fbc7c-kp4jh` Pod is failing (note that we do not use `--all` option)

<details>
<summary>Click to show example output:</summary>

```
POD [ERR]: kube-system/zadara-csi-controller-5f4b9fbc7c-kp4jh | Owners: [ReplicaSet kube-system/zadara-csi-controller-5f4b9fbc7c]
  $ kubectl describe deployment -n kube-system zadara-csi-controller
  $ kubectl describe replicaset -n kube-system zadara-csi-controller-5f4b9fbc7c
  $ kubectl describe pod -n kube-system zadara-csi-controller-5f4b9fbc7c-kp4jh
    csi-attacher                  : Not ready
        $ kubectl logs -n kube-system -c csi-attacher zadara-csi-controller-5f4b9fbc7c-kp4jh
        I0223 12:01:39.647322       1 main.go:96] Version: v3.2.1
        W0223 12:01:49.682296       1 connection.go:172] Still connecting to unix:///csi/csi.sock

    csi-provisioner               : Not ready
        $ kubectl logs -n kube-system -c csi-provisioner zadara-csi-controller-5f4b9fbc7c-kp4jh
        I0223 12:01:39.234267       1 feature_gate.go:243] feature gates: &{map[]}
        I0223 12:01:39.234365       1 csi-provisioner.go:138] Version: v2.2.2
        I0223 12:01:39.234397       1 csi-provisioner.go:161] Building kube configs for running in cluster...
        W0223 12:01:49.262578       1 connection.go:172] Still connecting to unix:///csi/csi.sock

    csi-resizer                   : Not ready
        $ kubectl logs -n kube-system -c csi-resizer zadara-csi-controller-5f4b9fbc7c-kp4jh
        I0223 12:01:37.027850       1 main.go:90] Version : v1.2.0
        I0223 12:01:37.027981       1 feature_gate.go:243] feature gates: &{map[]}
        W0223 12:01:47.034192       1 connection.go:172] Still connecting to unix:///csi/csi.sock
        W0223 12:01:57.034375       1 connection.go:172] Still connecting to unix:///csi/csi.sock

    csi-snapshotter               : Not ready
        $ kubectl logs -n kube-system -c csi-snapshotter zadara-csi-controller-5f4b9fbc7c-kp4jh
        I0223 12:01:40.179856       1 main.go:90] Version: v4.1.1
        I0223 12:01:40.193473       1 connection.go:153] Connecting to unix:///csi/csi.sock
        W0223 12:01:50.194253       1 connection.go:172] Still connecting to unix:///csi/csi.sock

    csi-zadara-driver             : Not ready
        $ kubectl logs -n kube-system -c csi-zadara-driver zadara-csi-controller-5f4b9fbc7c-kp4jh
          Feb 23 12:03:57.926858 [spi] [393] [DEBU]                        spi.(*SPI).UpdateStatus[  43] UpdateStatus | Volume: pvc-6643b234-7d69-4ace-977a-24e762831fbf (pvc-6643b234-7d69-4ace-977a-24e762831fbf), err: <nil>
          Feb 23 12:03:57.927909 [vsc] [393] [DEBU]               domain.(*VSCImpl).unlockResource[  67] Unlock resource | Volume: pvc-6643b234-7d69-4ace-977a-24e762831fbf (pvc-6643b234-7d69-4ace-977a-24e762831fbf)
          Feb 23 12:03:57.928961 [ctrl] [393] [ERRO]                   controllers.reconcileGeneric[  67] failed to update VSC object | Volume: pvc-6643b234-7d69-4ace-977a-24e762831fbf, err: N/A (5): Invalid credentials.
          Feb 23 12:03:57.929273 [volume] [393] [ERRO]      controller.(*Controller).reconcileHandler[ 317] Reconciler error | err: N/A (5): Invalid credentials.
          Feb 23 12:04:06.344108 [vsc] [3513] [DEBU]           domain.(*VSCImpl).ListStorageClasses[ 214] List StorageClasses | options: <nil>
          Feb 23 12:04:06.344569 [spi] [3513] [DEBU]                                spi.(*SPI).List[  76] List | err: <nil>, resources: StorageClass
          Feb 23 12:04:06.344805 [csi] [3513] [DEBU]         zcsi.(*IdentityServer).controllerProbe[  84] StorageClass is unhealthy | state: Failed, StorageClass: vscstorageclass-sample (Sample VSC Storage Class)
          Feb 23 12:04:06.383252 [vscMonitor] [1] [INFO]                     monitor.(*Monitor).StopAll[  72] Stop all monitor tasks |
          Feb 23 12:04:06.383444 [vscMonitor] [220] [WARN]                      monitor.(*Monitor).worker[  85] Monitor task aborted: requested shutdown | task: health-and-capacity-sync
          Feb 23 12:04:06.383528 [vscMonitor] [1] [INFO]                     monitor.(*Monitor).StopAll[  75] All monitor tasks stopped |
```

</details>

### List all storage-related resources

```
$ ./hack/k8dig.py storage -v
```

<details>
<summary>Click to show example output:</summary>

```
csidriver.storage.k8s.io
$ kubectl get csidriver.storage.k8s.io -o wide
  NAME                  ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES                  AGE
  csi.zadara.com        true             true             false             <unset>         false               Persistent             23h
  hostpath.csi.k8s.io   true             true             false             <unset>         false               Persistent,Ephemeral   201d

storageclass.storage.k8s.io
$ kubectl get storageclass.storage.k8s.io -o wide
  NAME                        PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
  csi-hostpath-sc (default)   hostpath.csi.k8s.io   Delete          WaitForFirstConsumer   false                  201d
  io-test-sc                  csi.zadara.com        Delete          Immediate              true                   22h

persistentvolumeclaim
$ kubectl get persistentvolumeclaim -o wide
  NAME                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
  block-io-test-0                Bound    pvc-7273e587-77f0-4a53-a739-69050721c94f   50Gi       RWO            io-test-sc     22h   Block
  block-io-test-1                Bound    pvc-d7616222-3c6a-4d4c-9c74-45f107e85e3a   50Gi       RWO            io-test-sc     22h   Block
  nas-io-test-0                  Bound    pvc-6643b234-7d69-4ace-977a-24e762831fbf   50Gi       RWX            io-test-sc     22h   Filesystem
  nas-io-test-0-clone            Bound    pvc-8ae82eb0-31f3-48ee-936f-e7583d80e281   50Gi       RWX            io-test-sc     22h   Filesystem
  nas-io-test-0-snapshot-clone   Bound    pvc-bec1dd14-5689-4179-99a1-1075b88eeef2   50Gi       RWO            io-test-sc     22h   Filesystem
  nas-io-test-1                  Bound    pvc-c6562fbf-2957-4042-abff-0f191997c7e7   50Gi       RWX            io-test-sc     22h   Filesystem

persistentvolume
$ kubectl get persistentvolume -o wide
  NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                  STORAGECLASS   REASON   AGE   VOLUMEMODE
  pvc-6643b234-7d69-4ace-977a-24e762831fbf   50Gi       RWX            Delete           Bound    zcenter/nas-io-test-0                  io-test-sc              22h   Filesystem
  pvc-7273e587-77f0-4a53-a739-69050721c94f   50Gi       RWO            Delete           Bound    zcenter/block-io-test-0                io-test-sc              22h   Block
  pvc-8ae82eb0-31f3-48ee-936f-e7583d80e281   50Gi       RWX            Delete           Bound    zcenter/nas-io-test-0-clone            io-test-sc              22h   Filesystem
  pvc-bec1dd14-5689-4179-99a1-1075b88eeef2   50Gi       RWO            Delete           Bound    zcenter/nas-io-test-0-snapshot-clone   io-test-sc              22h   Filesystem
  pvc-c6562fbf-2957-4042-abff-0f191997c7e7   50Gi       RWX            Delete           Bound    zcenter/nas-io-test-1                  io-test-sc              22h   Filesystem
  pvc-d7616222-3c6a-4d4c-9c74-45f107e85e3a   50Gi       RWO            Delete           Bound    zcenter/block-io-test-1                io-test-sc              22h   Block

volumeattachment.storage.k8s.io
$ kubectl get volumeattachment.storage.k8s.io -o wide
  NAME                                                                   ATTACHER         PV                                         NODE              ATTACHED   AGE
  csi-557a370864bc921e0bf87c7552a481d5d0d76275a552eeb5d9321b979ae96c3c   csi.zadara.com   pvc-6643b234-7d69-4ace-977a-24e762831fbf   k8s-base-master   true       22h
  csi-99286be487559636998a6a39c846ec0602d79c49edb9be328f772c57be9e678d   csi.zadara.com   pvc-7273e587-77f0-4a53-a739-69050721c94f   k8s-base-master   true       22h
  csi-a8efdabc6cbb3f4e6a86380dda6bf751196b6846ae53cdc2ede0fca84697d8df   csi.zadara.com   pvc-d7616222-3c6a-4d4c-9c74-45f107e85e3a   k8s-base-master   true       22h
  csi-f169caec17e4634b735aa7465c49f028724318a45b1ffc31fd619e2bf8844577   csi.zadara.com   pvc-c6562fbf-2957-4042-abff-0f191997c7e7   k8s-base-master   true       22h

volumesnapshotclass.snapshot.storage.k8s.io
$ kubectl get volumesnapshotclass.snapshot.storage.k8s.io
  NAME                         DRIVER                DELETIONPOLICY   AGE
  csi-hostpath-snapclass       hostpath.csi.k8s.io   Delete           201d
  volumesnapshotclass-sample   csi.zadara.com        Delete           2d
  zadara-csi-snapshot-class    csi.zadara.com        Delete           22h

volumesnapshot.snapshot.storage.k8s.io
$ kubectl get volumesnapshot.snapshot.storage.k8s.io
  NAME                     READYTOUSE   SOURCEPVC       SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS               SNAPSHOTCONTENT                                    CREATIONTIME   AGE
  nas-io-test-0-snapshot   true         nas-io-test-0                           50Gi          zadara-csi-snapshot-class   snapcontent-95730c4a-d78b-4ca3-a6d2-9b91eeb20877   22h            22h

volumesnapshotcontent.snapshot.storage.k8s.io
$ kubectl get volumesnapshotcontent.snapshot.storage.k8s.io
  NAME                                               READYTOUSE   RESTORESIZE   DELETIONPOLICY   DRIVER           VOLUMESNAPSHOTCLASS         VOLUMESNAPSHOT           AGE
  snapcontent-95730c4a-d78b-4ca3-a6d2-9b91eeb20877   true         53687091200   Delete           csi.zadara.com   zadara-csi-snapshot-class   nas-io-test-0-snapshot   22h
```

</details>

## Logs

```
$ ./hack/logs.sh -h
Display logs of a Zadara-CSI Pod
Usage: ./hack/logs.sh <node|controller|stonith> [-l] [-f] [-t <N>] [-n <K8S_NODE>]
    -l:                   Pipe to 'less' (can be combined with -f)
    -f:                   Use 'follow' option
    -n <K8S_NODE>:        Node name as appears in 'kubectl get nodes', or IP
                          If not specified - show logs for the 1st node/controller pod in list
    -t <N>:               Tail last N lines
Examples:
  ./hack/logs.sh controller -f
  ./hack/logs.sh controller -t 100 -lf
  ./hack/logs.sh node -t 100
  ./hack/logs.sh node -n 192.168.0.12
  ./hack/logs.sh node -n worker0 -lf
```

## Shell

```
$ ./hack/shell.sh -h
Open an interactive shell in Zadara-CSI Pod
Usage: ./hack/shell.sh <node|controller|stonith> [-n <K8S_NODE>]
    -n k8s-node:          Node name as appears in 'kubectl get nodes', or IP
                          If not specified - show logs for the 1st node/controller pod in list
```
