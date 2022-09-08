#!/bin/bash

# For non-standard distributions. Use environment variable, or default.
if [ ! $KUBECTL ]; then
  KUBECTL='kubectl'
fi
if [ ! $(which $KUBECTL) ]; then
  echo "Error: cannot find kubectl (Now set to $KUBECTL)."
  echo "For non-standard distributions use 'export KUBECTL=<kubectl name>'"
  echo "Example: 'export KUBECTL=oc'"
  exit 1
fi

###############################################################################

declare -A NAMESPACED_CATEGORIES
NAMESPACED_CATEGORIES["storage"]="pvc"
NAMESPACED_CATEGORIES["networking"]="services"
NAMESPACED_CATEGORIES["workloads"]="deployments daemonsets statefulsets replicasets pods jobs cronjobs"
NAMESPACED_CATEGORIES["csi"]="volumesnapshots"
NAMESPACED_CATEGORIES["config"]="configmaps secrets"

declare -A CLUSTER_CATEGORIES
CLUSTER_CATEGORIES["nodes"]="nodes"
CLUSTER_CATEGORIES["storage"]="storageclasses pv"
CLUSTER_CATEGORIES["csi"]="csidrivers volumesnapshotclasses volumesnapshotcontents volumeattachments.storage.k8s.io"
CLUSTER_CATEGORIES["custom-resources"]="vscstorageclasses.storage.zadara.com
  vpsas.storage.zadara.com
  vscnodes.storage.zadara.com
  volumes.storage.zadara.com
  volumeattachments.storage.zadara.com
  snapshots.storage.zadara.com"

###############################################################################

function log() {
  echo "$@" >&2
}

function run_kubectl() {
  if [ "$DEBUG_PRINTS" ]; then
    # Echo the command in grey
    echo -e "\e[01;90m" "$ $KUBECTL $*" "\e[0m" >&2
    # Run the command, print stderr in red
    $KUBECTL "$@" 2> >(while read -r line; do echo -e "  \e[01;31m$line\e[0m" >&2; done)
  else
    $KUBECTL "$@" 2>/dev/null
  fi
}

###############################################################################

# k_get_all <directory>
function k_get_all() {
  local DIR="$1"

  for CATEGORY in "${!NAMESPACED_CATEGORIES[@]}"; do
    for RESOURCE in ${NAMESPACED_CATEGORIES[$CATEGORY]}; do
      for NAMESPACE in $NAMESPACES; do
        FILENAME="$DIR/$CATEGORY/$NAMESPACE/$RESOURCE.yaml"
        mkdir -p $(dirname $FILENAME)
        run_kubectl get $RESOURCE -n $NAMESPACE >$FILENAME
      done
    done
  done

  for CATEGORY in "${!CLUSTER_CATEGORIES[@]}"; do
    for RESOURCE in ${CLUSTER_CATEGORIES[$CATEGORY]}; do
      FILENAME="$DIR/$CATEGORY/$RESOURCE.yaml"
      mkdir -p $(dirname $FILENAME)
      run_kubectl get $RESOURCE >$FILENAME
    done
  done
}

function k_describe_all() {
  local DIR="$1"

  for CATEGORY in "${!NAMESPACED_CATEGORIES[@]}"; do
    for RESOURCE in ${NAMESPACED_CATEGORIES[$CATEGORY]}; do
      for NAMESPACE in $NAMESPACES; do
        FILENAME="$DIR/$CATEGORY/$NAMESPACE/$RESOURCE.yaml"
        mkdir -p $(dirname $FILENAME)
        run_kubectl describe $RESOURCE -n $NAMESPACE >$FILENAME
      done
    done
  done

  for CATEGORY in "${!CLUSTER_CATEGORIES[@]}"; do
    for RESOURCE in ${CLUSTER_CATEGORIES[$CATEGORY]}; do
      FILENAME="$DIR/$CATEGORY/$RESOURCE.yaml"
      mkdir -p $(dirname $FILENAME)
      run_kubectl describe $RESOURCE >$FILENAME
    done
  done
}

# k_logs <directory> <pod name pattern>
function k_logs() {
  local DIR="$1"
  local POD_NAME_PATTERN="$2"

  for NAMESPACE in $NAMESPACES; do
    PODS=$(run_kubectl get pods -n $NAMESPACE -o custom-columns='NAME:{..metadata.name}' | grep -E "$POD_NAME_PATTERN")
    for POD in $PODS; do
      CONTAINERS=$(run_kubectl get pod -n $NAMESPACE $POD -o jsonpath='{..spec.containers[*].name}')
      for CONTAINER in $CONTAINERS; do
        FILENAME="$DIR/$NAMESPACE/$POD.$CONTAINER.log"
        mkdir -p $(dirname $FILENAME)
        run_kubectl logs -n $NAMESPACE $POD -c $CONTAINER >$FILENAME
      done
    done
  done
}

###############################################################################

function print_usage_and_exit {
  echo "$0 [-h|--help] [-q|--quiet] [--prefix PREFIX] [--logs-from PATTERN] [--no-tar] [NAMESPACE...]"
  echo
  echo "ZSnap-like tool [beta] for k8s applications. Requires kubectl with access to"
  echo "the cluster. Resulting files are placed in the current directory."
  echo
  echo "Examples:"
  echo "  $0 -q"
  echo "  $0 --prefix 'before-upgrade' kube-system default"
  echo "  $0 --logs-from 'my-app|zadara' --no-tar"
  echo
  echo "Optional arguments:"
  echo "  -h, --help           Show this help message and exit"
  echo "  -q, --quiet          Show less output. Do not print kubectl commands and errors"
  echo "  --prefix PREFIX      Prefix for the k8snap directory."
  echo "                       Can be used to describe the reason for the snapshot,"
  echo "                       e.g. 'before-upgrade' or 'pods-failed-to-start'"
  echo "  --logs-from PATTERN  Pattern to match pods to grab logs from."
  echo "                       Uses 'grep -E' syntax. Default: 'zadara'"
  echo "  --no-tar             Do not create a tarball"
  echo "  NAMESPACE...         Namespaces to include (positional args, multiple allowed)"
  echo "                       If not specified: 'kube-system' and the current namespace."
  exit 1
}

PREFIX=
DO_TAR=true
NAMESPACES=
LOGS_PATTERN=zadara
DEBUG_PRINTS=true

while true; do
  case "$1" in
  -h | --help) print_usage_and_exit ;;
  -q | --quiet)
    DEBUG_PRINTS=
    shift
    ;;
  --no-tar)
    DO_TAR=""
    shift
    ;;
  --prefix)
    # slash is not allowed in the prefix
    PREFIX=`echo "$2" | tr '/' '+'`
    shift 2
    ;;
  --logs-from)
    LOGS_PATTERN="$2"
    shift 2
    ;;
  "") break ;;
  *)
    NAMESPACES="$NAMESPACES $1"
    shift
    ;;
  esac
done

if [ ! "$NAMESPACES" ]; then
  CURRENT_NAMESPACE=$($KUBECTL config view -o jsonpath='{..namespace}')
  NAMESPACES="kube-system $CURRENT_NAMESPACE"
fi

###############################################################################

K8SNAP_DIR="$(pwd)/k8snap-$PREFIX-$(date +%Y%m%d-%H%M%S)"

log "Creating k8snap directory: $K8SNAP_DIR"
mkdir -p "$K8SNAP_DIR"

log "Collect info from the namespaces:" $NAMESPACES

k_get_all "$K8SNAP_DIR/kubectl_get"
k_describe_all "$K8SNAP_DIR/kubectl_describe"
k_logs "$K8SNAP_DIR/logs" "$LOGS_PATTERN"

if [ "$DO_TAR" ]; then
  log "Creating tarball"
  # using `basename` prevents the tarball from containing the full path
  tar -czf "$K8SNAP_DIR.tar.gz" `basename "$K8SNAP_DIR"` && rm -rf "$K8SNAP_DIR"
  log "Done: $K8SNAP_DIR.tar.gz"
else
  log "Done:" $K8SNAP_DIR/
fi
