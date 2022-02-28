# Extended configuration (ConfigMap)

Zadara-CSI plugin supports fine-grained configuration via ConfigMap. Changes in ConfigMap are monitored and updated live.

To update ConfigMap follow the example below:

```shell script
$ kubectl get configmap -n kube-system -l app=zadara-csi
NAME                    DATA   AGE
zadara-csi-config-map   1      4h38m

$ kubectl edit configmap -n kube-system zadara-csi-config-map
```

| variable                | default | description                                                                                                      |
|-------------------------|---------|------------------------------------------------------------------------------------------------------------------|
| `logFormat`             | "text"  | Log output format. Allowed values: `text` or `json`                                                              |
| `useLogColors`          | true    | Use colored output in logs. Does not auto-detect pipes, redirection, or other non-interactive outputs.           |
| `logLengthLimit`        | 512     | Trim long log messages (or long values in `json` mode) and reduce logs size. `0` disables the limit              |
| `plugin.logLevel.<tag>` | info    | Verbosity level for plugin logs. Allowed values: `panic`, `fatal`, `error`, `warn` or `warning`, `info`, `debug` |
| `logLevelOverride`      | info    | Set log level for all tags.                                                                                      |

Example config (only the contents, for readability):

```yaml
logFormat: text
useLogColors: false
logLengthLimit: 512
logLevel:
  allocator: info
  conversion: info
  csi: info
  csicommon: info
  ctrl: info
  events: info
  spi: info
  vpsaapi: info
  vsc: info
logLevelOverride: info
```

Complete ConfigMap looks like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: zadara-csi-config-map
  namespace: kube-system
data:
  config.yaml: |-
    ...
    contents
    ...
```
