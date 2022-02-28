# Adding custom trusted certificates

CSI Driver can be configured to use HTTPS with custom certificate (e.g. self-signed).

You can either reference a Secret, or provide a certificate directly in `values.yaml` (a Secret will be created
automatically).

Before proceeding, please make sure that `X509v3 Basic Constraints: CA: TRUE` is present for at least one certificate in
the chain.

<details>
<summary>Click to see how</summary>

To decode a certificate chain you can run:

```
openssl crl2pkcs7 -nocrl -certfile <CERTIFICATE> | openssl pkcs7 -print_certs -text -noout
```

For example:

```
$ openssl crl2pkcs7 -nocrl -certfile CA.crt | openssl pkcs7 -print_certs -text -noout | grep -e 'X509v3 Basic Constraints' -e 'CA:'
            X509v3 Basic Constraints:
                CA:TRUE
```

To verify, check `csi-zadara-driver` container logs (in any CSI pod), for example:

```
$ kubectl logs -n kube-system zadara-csi-controller-bd4c4858-z8jkd csi-zadara-driver
Jul 11 10:22:18 [INFO] Executing pre-start actions...
Jul 11 10:22:18 [INFO] Add trusted CA certificates:
zadara-csi-tls.crt
Jul 11 10:22:18 [INFO] Installed trusted certificates:
pkcs11:id=%D8%53%1E%C7%82%D1%BC%25%FB%CC%25%DC%1A%F7%70%5F%FB%3A%66%3F;type=cert
    type: certificate
    label: zadaravpsa.com
    trust: anchor
    category: authority
```

---
</details>

## Using existing Secret

1. Create a Secret with certificates to install. Use the same namespace (typically `kube-system`) where the CSI driver
   is deployed. A Secret may contain any number of certificates. The following command will create a Secret
   named `custom-ca-certs` in namespace `kube-system`, containing certificates from files `CA1.crt` and `CA2.crt`.

```
kubectl create secret -n kube-system generic custom-ca-certs --from-file=CA1.crt --from-file=CA2.crt
```

2. Set `customTrustedCertificates.existingSecret` in `values.yaml`

```
customTrustedCertificates:
  existingSecret: custom-ca-certs
```

## Provide a certificate directly

Paste `.crt` contents into `customTrustedCertificates.plainText` in  `values.yaml` (contents omitted).

```
customTrustedCertificates:
  plainText: |-
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
```

A Secret will be created during Chart installation.
