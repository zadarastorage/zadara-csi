# Get Zadara-CSI

You may add a Helm Chart repository from GitHub, or clone this repo and use a local Chart directory.

## Using Helm repository

```
$ helm repo add zadara-csi-helm https://raw.githubusercontent.com/zadarastorage/zadara-csi/release/zadara-csi-helm
"zadara-csi-helm" has been added to your repositories
```

Show repo contents:

```
$ helm search repo
NAME                                            CHART VERSION   APP VERSION     DESCRIPTION
zadara-csi-helm/example-workload                0.1.0                           Example workload using Zadara-CSI NAS & Block v...
zadara-csi-helm/snapshots-v1                    4.1.1+zadara.1  4.1.1           Common infrastructure for v1 CSI Snapshots. Inc...
zadara-csi-helm/snapshots-v1beta1               3.3.0+zadara.1  3.3.0           Common infrastructure for v1beta1 CSI Snapshots...
zadara-csi-helm/zadara-csi                      3.0.0           2.0.0           Container Storage Interface (CSI) driver for Za...
```

You can also add a repo for a specific version:

<details>
<summary>Click for examples</summary>

- `master` branch
    ```
    $ helm repo add zadara-csi-helm https://raw.githubusercontent.com/zadarastorage/zadara-csi/master/zadara-csi-helm
    ```
- `release-v1.3.10` tag
    ```
    $ helm repo add zadara-csi-helm https://raw.githubusercontent.com/zadarastorage/zadara-csi/release-v1.3.10/zadara-csi-helm
    ```

---
</details>

## Clone GitHub repository

All Helm charts are available locally, in `helm/` subdirectory of this repository.

```shell
$ git clone https://github.com/zadarastorage/zadara-csi.git
$ cd zadara-csi
```

To use a specific version:

<details>
<summary>Click for examples</summary>

- `master` branch
    ```
    $ git checkout master
    ```
- `release-v1.3.10` tag
    ```
    $ git checkout release-v1.3.10
    ```

---
</details>

Replace `zadara-csi-helm/` with `./deploy/helm/` in Helm commands

🛈 In addition to Helm charts, GitHub repository also provides _example YAMLs_ and _helper scripts_ for troubleshooting.
