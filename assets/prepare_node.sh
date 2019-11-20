#!/bin/bash

SERVICE="run-on-host-server"

IFILE="assets/${SERVICE}_x86_64"
DIR="/var/zadara"
SFILE="${DIR}/${SERVICE}"
SOCK="${DIR}/csi-iscsi.sock"

SCSI_SERVICE="[Unit]
Description = ${SERVICE} container to host adapter service

[Service]
ExecStart = ${SFILE} -socket unix://${SOCK}

[Install]
WantedBy = multi-user.target"

SCSI_SERVICE_NAME="${SERVICE}.service"
SCSI_SERVICE_FILE="/lib/systemd/system/${SCSI_SERVICE_NAME}"

function install_service()
{
    systemctl status run-on-host-server.service >/dev/null
    if [[ $? == 0 ]]; then
      echo "[INFO] ${SERVICE} is already running"
      exit 0
    fi

    echo "[INFO] Get ${SERVICE} files"
    mkdir -p ${DIR}
    cp "${IFILE}" "${SFILE}"
    if [[ $? != 0 ]]; then
        echo "[ERROR] Failed to get ${SERVICE}: not found at ${IFILE}"
        exit 1
    fi
    chmod +x "${SFILE}"

    echo "[INFO] Registering $SERVICE service"
    echo "${SCSI_SERVICE}" > "${SCSI_SERVICE_FILE}"
    if [ ! -e "${SCSI_SERVICE_FILE}" ]; then
        echo "[ERROR] Failed to create '${SCSI_SERVICE_FILE}'.  Exiting"
        exit 1
    fi
    systemctl enable "${SCSI_SERVICE_NAME}"
    if [[ $? != 0 ]]; then
        echo "[ERROR] Failed to register $SERVICE service"
        exit 1
    fi

    echo "[INFO] Starting $SERVICE service"
    systemctl start "${SCSI_SERVICE_NAME}"
    if [[ $? != 0 ]]; then
        echo "[ERROR] Failed to start $SERVICE service"
        exit 1
    fi

    sleep 1

    echo "[INFO] Verifying service started correctly"
    systemctl status --no-pager -l "${SCSI_SERVICE_NAME}"
    if [[ $? != 0 ]]; then
        echo "[ERROR] Failed to verify $SERVICE service is running"
    fi
}

function install_iscsi() {
  if [ -f /etc/os-release ]; then
      os_name=$(grep -E "^NAME=" /etc/os-release | awk -F"NAME=" '{print $2}')
      echo "[INFO] os name: $os_name"

    echo "$os_name" | grep -E -q "Red Hat|CentOS"
    if [[ $? != 0 ]]; then
          CONFORM_TO=redhat
      fi

    echo "$os_name" | grep -E -q "Ubuntu|Debian"
    if [[ $? != 0 ]]; then
          CONFORM_TO=ubuntu
      fi
  fi

  if [ "$CONFORM_TO" = "ubuntu" ]; then
      # TODO: apt-get -qq install -y multipath-tools
      if [ ! -f /sbin/iscsid ]; then
          apt-get -qq update
          apt-get -qq install -y open-iscsi
      else
          echo "[INFO] open-iscsi already installed"
      fi
  elif [ "$CONFORM_TO" = "redhat" ]; then
      # TODO: yum -y install device-mapper-multipath
      if [ ! -f /sbin/iscsid ]; then
          yum -y install iscsi-initiator-utils
      else
          echo "[INFO] iscsi-initiator-utils already installed"
      fi
  else
      echo "[ERROR] failed to auto-install open-iscsi package for $os_name. Please install manually"
      exit 1
  fi
  # load iscsi_tcp modules, its a no-op if its already loaded
  modprobe iscsi_tcp
}

function uninstall()
{
    echo "[INFO] Stopping service"
    systemctl stop "${SCSI_SERVICE_NAME}"
    echo "[INFO] Disabling service"
    systemctl disable "${SCSI_SERVICE_NAME}"
    echo "[INFO] Removing service file"
    rm -- "${SCSI_SERVICE_FILE}"
    echo "[INFO] Reloading/Resetting systemctl"
    systemctl daemon-reload
    systemctl reset-failed
    echo "[INFO] Removing binary"
    rm -- "${SFILE}" "${SOCK}"
}

function usage()
{
    echo "Usage: $0 [-hpu]
    -h  Print this help
    -p  Install prerequisites: open-iscsi packages for Debian or RedHat based systems
    -u  Uninstall $SERVICE service (does not uninstall open-iscsi)" 1>&2; exit 1;
}

while getopts ":uhp" option
do
    case "${option}"
    in
        u)
          uninstall
          exit
          ;;
        p)
          install_iscsi
          exit
          ;;
        \?) echo "Invalid Option: -${OPTARG}" >&2; exit 1
          ;;
        *)
          usage
          exit 1
          ;;
    esac
done

install_service
