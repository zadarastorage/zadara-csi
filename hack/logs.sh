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
    echo "Display logs of a Zadara-CSI Pod"
    echo "Usage: $0 <node|controller> [-l] [-f] [-n k8s-node] [-r helm-release-name]"
    echo "    -l:                   Pipe to 'less' (can be combined with -f)"
    echo "    -f:                   Use 'follow' option"
    echo "    -n k8s-node:          Node name as appears in 'kubectl get nodes', or IP"
    echo "                          If not specified - show logs for the 1st node/controller pod in list"
    echo "    -r helm-release-name: Helm release name as appears in 'helm list'"
    echo "                          Required if you have multiple instances of CSI plugin"
    echo "    -t N:                 Tail last N lines"
    echo "Examples:"
    echo "  $0 controller -f"
    echo "  $0 controller -r warped-seahorse"
    echo "  $0 node -t 100"
    echo "  $0 node -n 192.168.0.12 -r warped-seahorse"
    echo "  $0 node -n worker0 -lf"
    exit 1
}

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

while getopts ":n:r:t:lf" opt; do
  case ${opt} in
    l ) LESS=true
      ;;
    f ) FOLLOW_KUBECTL="-f"
        FOLLOW_LESS="+F"
      ;;
    n ) NODE="${OPTARG}"
      ;;
    r ) RELEASE="${OPTARG}"-
      ;;
    t ) TAIL="${OPTARG}"
      ;;
    * ) print_usage_and_exit
      ;;
  esac
done

SELECTOR="-l publisher=zadara -l app.kubernetes.io/component=$WHAT"
if [ "$RELEASE" ]; then
	SELECTOR="$SELECTOR -l release=$RELEASE"
fi

if [ "$TAIL" ]; then
	TAIL_ARG="--tail $TAIL"
fi

if [ ! "$NODE" ]; then
  NS_POD=$($KUBECTL get pods --all-namespaces $SELECTOR 2>&1 | tail -n +2 | grep -v "Evicted" | head -n1 | awk '{print $1, $2}')
else
  NS_POD=$($KUBECTL get pods --all-namespaces $SELECTOR -o wide 2>&1 | tail -n +2 | grep -v "Evicted" | grep "${NODE}" | awk '{print $1, $2}')
fi

if [ ! "$NS_POD" ]; then
  echo "Pod not found"
  exit 1
fi

if [ "$LESS" ]; then
  $KUBECTL logs $FOLLOW_KUBECTL -n $NS_POD -c csi-zadara-driver $TAIL_ARG | less -R $FOLLOW_LESS
else
  $KUBECTL logs $FOLLOW_KUBECTL -n $NS_POD -c csi-zadara-driver $TAIL_ARG
fi
