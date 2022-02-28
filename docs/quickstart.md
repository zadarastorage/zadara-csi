# Quickstart

### Get the repo

```
git clone https://github.com/zadarastorage/zadara-csi.git
cd zadara-csi
```

### Install zadara-csi Chart

```
helm upgrade --install zadara-csi ./helm/zadara-csi
```

### Create VSCStorageClass

```
kubectl apply -f ./deploy/examples/vscstorageclass.yaml
```

### Add a VPSA

⚠ Edit `./deploy/examples/vpsa.yaml` and set VPSA credentials.

<details>
<summary>Or, you can use sed</summary>

Edit the following commands with your credentials instead of a placeholders `YOUR_VPSA_HOSTNAME_HERE`
and `YOUR_VPSA_TOKEN_HERE`.

```
sed -i 's|example.zadaravpsa.com|YOUR_VPSA_HOSTNAME_HERE|' ./deploy/examples/vpsa.yaml
sed -i 's|SUPER-SECRET-TOKEN-12345|YOUR_VPSA_TOKEN_HERE|' ./deploy/examples/vpsa.yaml
```

</details>



Add a VPSA

```
kubectl apply -f ./deploy/examples/vpsa.yaml
```

<details>
<summary>Example output</summary>

```
NAME          STATUS   DISPLAY NAME   CAPACITY MODE   VSC                      AGE
vpsa-sample   Ready    Example VPSA   normal          vscstorageclass-sample   3m18s
```

</details>

Check VPSA status, make sure it's `Ready`:

```
kubectl get vpsa
```

### Test I/O

Install example-workload Chart with I/O on NAS volumes

```
helm install io-test ./helm/example-workload --set blockVolumes.enabled=false
```

Check Zadara Custom Resources status, make sure all statuses are `Ready`:

```
./hack/k8dig.py crd zadara
```

<details>
<summary>Example output</summary>

```
volumeattachment.storage.zadara.com
  NAME                                                       STATUS   ISCSI       VOLUME                                     VSCNODE           AGE
  pvc-6bf22e36-7ba2-49c0-adb1-91f6ad825abc.k8s-base-master   Ready    N/A (NAS)   pvc-6bf22e36-7ba2-49c0-adb1-91f6ad825abc   k8s-base-master   94s
  pvc-aaaf41c8-3417-481f-bd8f-235b8b244362.k8s-base-master   Ready    N/A (NAS)   pvc-aaaf41c8-3417-481f-bd8f-235b8b244362   k8s-base-master   109s

volume.storage.zadara.com
  NAME                                       STATUS   TYPE   CAPACITY   VPSA          AGE
  pvc-6bf22e36-7ba2-49c0-adb1-91f6ad825abc   Ready    NAS    50Gi       vpsa-sample   96s
  pvc-aaaf41c8-3417-481f-bd8f-235b8b244362   Ready    NAS    50Gi       vpsa-sample   111s

vpsa.storage.zadara.com
  NAME          STATUS   DISPLAY NAME   HOSTNAME                                 VERSION      CAPACITY MODE   TOTAL      AVAILABLE   VSC                      AGE
  vpsa-sample   Ready    Example VPSA   vsa-0000028d-zadara-qa9.zadaravpsa.com   22.06-1000   normal          743296Mi   722252Mi    vscstorageclass-sample   4m47s

vscnode.storage.zadara.com
  NAME              IP             IQN                                       AGE
  k8s-base-master   10.10.100.61   iqn.2005-03.org.open-iscsi:e9c4f0d828cf   12m

vscstorageclass.storage.zadara.com
  NAME                     STATUS   DEFAULT   MEMBERS   CAPACITY MODE   TOTAL      AVAILABLE   AGE
  vscstorageclass-sample   Ready    true      1         normal          743296Mi   722252Mi    10m
```

</details>

Watch I/O in Pod logs:

```
kubectl logs io-test-0 --follow
```

<details>
<summary>Example output</summary>

```
Wed Feb 23 14:12:27 UTC 2022 Write to NAS Volume: /mnt/csi
996+4 records in
996+4 records out
1046769280 bytes (998.3MB) copied, 10.498774 seconds, 95.1MB/s
Wed Feb 23 14:12:42 UTC 2022 Write to NAS Volume: /mnt/csi
1000+0 records in
1000+0 records out
1048576000 bytes (1000.0MB) copied, 13.818688 seconds, 72.4MB/s
Wed Feb 23 14:13:01 UTC 2022 Write to NAS Volume: /mnt/csi
1000+0 records in
1000+0 records out
1048576000 bytes (1000.0MB) copied, 11.081654 seconds, 90.2MB/s
Wed Feb 23 14:13:17 UTC 2022 Write to NAS Volume: /mnt/csi
1000+0 records in
1000+0 records out
1048576000 bytes (1000.0MB) copied, 10.495841 seconds, 95.3MB/s
Wed Feb 23 14:13:33 UTC 2022 Write to NAS Volume: /mnt/csi
1000+0 records in
1000+0 records out
1048576000 bytes (1000.0MB) copied, 12.172426 seconds, 82.2MB/s
Wed Feb 23 14:13:50 UTC 2022 Write to NAS Volume: /mnt/csi
1000+0 records in
1000+0 records out
```

</details>

### Add more VPSAs

```
cp ./deploy/examples/vpsa.yaml ./deploy/examples/vpsa-2.yaml
```

⚠ Edit `./deploy/examples/vpsa-2.yaml` and set VPSA credentials.

```
kubectl apply -f ./deploy/examples/vpsa-2.yaml
```

### Scale workload

```
kubectl scale statefulset io-test --replicas=3
kubectl get pods -l app=io-test --watch
```

### Uninstall workload

```
helm uninstall io-test
```

All `io-test` resources will be eventually deleted.

```
./hack/k8dig.py crd zadara
```

<details>
<summary>Example output</summary>

```
vpsa.storage.zadara.com
  NAME          STATUS   DISPLAY NAME   HOSTNAME                                 VERSION      CAPACITY MODE   TOTAL      AVAILABLE   VSC                      AGE
  vpsa-other    Ready    Another VPSA   vsa-0000029d-zadara-qa9.zadaravpsa.com   22.06-1000   normal          9210Gi     9418093Mi   vscstorageclass-sample   2m38s
  vpsa-sample   Ready    Example VPSA   vsa-0000028d-zadara-qa9.zadaravpsa.com   22.06-1000   normal          743296Mi   722252Mi    vscstorageclass-sample   17m

vscnode.storage.zadara.com
  NAME              IP             IQN                                       AGE
  k8s-base-master   10.10.100.61   iqn.2005-03.org.open-iscsi:e9c4f0d828cf   25m

vscstorageclass.storage.zadara.com
  NAME                     STATUS   DEFAULT   MEMBERS   CAPACITY MODE   TOTAL        AVAILABLE    AGE
  vscstorageclass-sample   Ready    true      2         normal          10174336Mi   10140345Mi   23m
```

</details>
