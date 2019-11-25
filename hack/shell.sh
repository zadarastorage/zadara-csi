#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR/..

# For non-standard distributions, like microk8s
KUBECTL='kubectl'

function print_usage_and_exit {
    echo "Open an interactive shell in Zadara-CSI Pod"
    echo "Usage: $0 <node|controller> [-n k8s-node] [-r helm-release-name]"
    echo "    k8s-node: Node name as appears in 'kubectl get nodes'"
    echo "              If not specified - show logs for the 1st node/controller pod in list"
    echo "    helm-release-name: helm release name as appears in 'helm list'"
    echo "              Required if you have multiple instances of CSI plugin"
    exit 1
}

if [ `whoami` = 'root' ]; then
  echo "Please, run as regular user (e.g. zadara)"
  exit 1
fi

if [ $# -eq 0 ]; then
  print_usage_and_exit
fi

WHAT=$1
shift
case $WHAT in
"node" | "controller")
    ;;
*)
    print_usage_and_exit
    ;;
esac

while getopts ":n:r:" opt; do
  case ${opt} in
    n ) NODE="${OPTARG}"
      ;;
    r ) RELEASE="${OPTARG}"-
      ;;
    * ) print_usage_and_exit
      ;;
  esac
done

if [ ! $NODE ]; then
  POD=$($KUBECTL get pods -n kube-system 2>&1 | grep "${RELEASE}"csi-zadara-$WHAT | grep -v "Evicted" | head -n1 | awk 'BEGIN{FS=" "} {print $1}')
else
  POD=$($KUBECTL get pods -n kube-system -o wide 2>&1 | grep "${RELEASE}"csi-zadara-$WHAT | grep -v "Evicted" | grep "${NODE}" | awk 'BEGIN{FS=" "} {print $1}')
fi

if [ ! $POD ]; then
  echo "Pod not found"
  exit 1
fi

$KUBECTL exec -n kube-system -it $POD -c csi-zadara-driver /bin/bash
