# Expand Persistent Volume Claim

VPSA supports online Volume expansion for block and NAS volumes.

Resizing of a PVC can be done *with no downtime*: no need to stop IO or restart application Pods.

- For NAS volumes additional capacity is available immediately.

- Block volumes may require some extra configuration to add capacity to the file system (if present).
  [Example for ext4](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/storage_administration_guide/ext4grow).
  Typically, this can be done online as well.

### Requirements and limitations:
- To allow Persistent Volume Claims to be expanded, a StorageClass must be defined with `allowVolumeExpansion: true`.
- Capacity cannot be decreased

### Example

We will show how to add capacity to PVC `nas-io-test-0` from [Example workload](example_workload.md):
```
$ kubectl get pvc
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
block-io-test-0   Bound    pvc-9c5c9956-9c13-4755-9745-9ae65045c946   50Gi       RWO            io-test-sc     40m
block-io-test-1   Bound    pvc-69c03928-c2cf-4bba-9224-88423b6f116e   50Gi       RWO            io-test-sc     40m
nas-io-test-0     Bound    pvc-31967f56-f67b-48f1-82de-01af350bd357   50Gi       RWX            io-test-sc     40m
nas-io-test-1     Bound    pvc-fefe3b4d-112a-4779-a004-6cce36c4e380   50Gi       RWX            io-test-sc     40m
```

Check that `ALLOWVOLUMEEXPANSION` is enabled for the StorageClass:
```
$ kubectl get sc
NAME                        PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
io-test-sc                  csi.zadara.com        Delete          Immediate              true                   41m
```

Update the PVC: set capacity to `150Gi`:
```
$ kubectl patch pvc nas-io-test-0 -p '{"spec":{"resources":{"requests":{"storage": "150Gi"}}}}'
persistentvolumeclaim/nas-io-test-0 patched
```

You can also run `kubectl edit pvc nas-io-test-0` and update capacity interactively.

Capacity is updated:
```
$ kubectl get pvc nas-io-test-0
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
nas-io-test-0         Bound    pvc-4e5f9b7c-6e68-4476-95d4-6db0057ba839   150Gi      RWX            io-test-nas         2m7s
```

You can also check available capacity from inside the Pod.
We use Pod `io-test-0` from [Example workload](example_workload.md):
```
$ kubectl get pods
NAME        READY   STATUS    RESTARTS   AGE
io-test-0   1/1     Running   0          49m
io-test-1   1/1     Running   0          49m
```

Check capacity (only PVC volume shown):
```
$ kubectl exec io-test-0 -- df -h
Filesystem                Size      Used Available Use% Mounted on
...
10.10.10.10:/export/pvc-3e8b25af-ef90-4267-bd46-2be9672cbbca
                        150.0G    190.0M    149.8G   0% /mnt/csi
...
```
