#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR/..

# For non-standard distributions, like microk8s. Use enviroment variable, or default.
if [ ! $KUBECTL ]; then
  KUBECTL='kubectl'
fi
if [ ! `which $KUBECTL` ]; then
  echo "Error: cannot find kubectl (Now set to $KUBECTL)."
  echo "For non-standard distributions use 'export KUBECTL=<kubectl name>'"
  echo "Example: 'export KUBECTL=microk8s.kubectl'"
  exit 1
fi

function print_usage_and_exit {
    echo "Open an interactive shell in Zadara-CSI Pod"
    echo "Usage: $0 <node|controller|stonith> [-n <K8S_NODE>]"
    echo "    -n k8s-node:          Node name as appears in 'kubectl get nodes', or IP"
    echo "                          If not specified - show logs for the 1st node/controller pod in list"
    exit 1
}

if [ $# -eq 0 ]; then
  print_usage_and_exit
fi

WHAT=$1
shift
case $WHAT in
"node" | "controller")
	  CONTAINER_ARG="-c csi-zadara-driver"
    ;;
"stonith")
    ;;
*)
    print_usage_and_exit
    ;;
esac

while getopts ":n:" opt; do
  case ${opt} in
    n ) NODE="${OPTARG}"
      ;;
    * ) print_usage_and_exit
      ;;
  esac
done

SELECTOR="-l publisher=zadara -l app.kubernetes.io/component=$WHAT"

if [ ! "$NODE" ]; then
  NS_POD=$($KUBECTL get pods --all-namespaces $SELECTOR 2>&1 | tail -n +2 | grep -v "Evicted" | head -n1 | awk '{print $1, $2}')
else
  NS_POD=$($KUBECTL get pods --all-namespaces $SELECTOR -o wide 2>&1 | tail -n +2 | grep -v "Evicted" | grep "${NODE}" | awk '{print $1, $2}')
fi

if [ ! "$NS_POD" ]; then
  echo "Pod not found"
  exit 1
fi

echo $KUBECTL exec -it -n $NS_POD $CONTAINER_ARG -- /bin/bash
$KUBECTL exec -it -n $NS_POD $CONTAINER_ARG -- /bin/bash
