#!/bin/bash

# For non-standard distributions, like microk8s. Use environment variable, or default.
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
    echo "Usage: $0 <node|controller|stonith> [-l] [-f] [-t <N>] [-n <K8S_NODE>]"
    echo "    -l:                   Pipe to 'less' (can be combined with -f)"
    echo "    -f:                   Use 'follow' option"
    echo "    -n <K8S_NODE>:        Node name as appears in 'kubectl get nodes', or IP"
    echo "                          If not specified - show logs for the 1st node/controller pod in list"
    echo "    -t <N>:               Tail last N lines"
    echo "Examples:"
    echo "  $0 controller -f"
    echo "  $0 controller -t 100 -lf"
    echo "  $0 node -t 100"
    echo "  $0 node -n 192.168.0.12"
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
	CONTAINER_ARG="-c csi-zadara-driver"
    ;;
"stonith")
    ;;
*)
    print_usage_and_exit
    ;;
esac

while getopts ":n:t:lf" opt; do
  case ${opt} in
    l ) LESS=true
      ;;
    f ) FOLLOW_KUBECTL="-f"
        FOLLOW_LESS="+F"
      ;;
    n ) NODE="${OPTARG}"
      ;;
    t ) TAIL="${OPTARG}"
      ;;
    * ) print_usage_and_exit
      ;;
  esac
done

SELECTOR="-l publisher=zadara -l app.kubernetes.io/component=$WHAT"

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
  $KUBECTL logs $FOLLOW_KUBECTL -n $NS_POD $CONTAINER_ARG $TAIL_ARG | less -R $FOLLOW_LESS
else
  echo $KUBECTL logs $FOLLOW_KUBECTL -n $NS_POD $CONTAINER_ARG $TAIL_ARG
  $KUBECTL logs $FOLLOW_KUBECTL -n $NS_POD $CONTAINER_ARG $TAIL_ARG
fi
