#!/bin/bash
#set -eo pipefail

source /lib.sh

PROXY_METHOD=${PROXY_METHOD:-remote}
PROXY_HOST=${PROXY_HOST:-*}
PROXY_PORT=${PROXY_PORT:-3140}
SSH_USER=${SSH_USER:-root}
SSH_HOST=${SSH_HOST:-ssh.example.com}
SSH_PORT=${SSH_PORT:-22}
TARGET_HOST=localhost
TARGET_PORT=${TARGET_PORT:-80}
ARGS="-T -N -oStrictHostKeyChecking=no -oServerAliveInterval=180 -oUserKnownHostsFile=/dev/null -p $SSH_PORT $ARGS"
SERVER="$SSH_USER@$SSH_HOST"
MAX_SLEEP=${MAX_SLEEP:-120}
export SSHPASS=${SSHPASS:-$SSH_PASSWORD}

case ${PROXY_METHOD} in
  socks)  proxy="-D $PROXY_HOST:$PROXY_PORT" ;;
  local)  proxy="-L $PROXY_HOST:$PROXY_PORT:$TARGET_HOST:$TARGET_PORT" ;;
  remote) proxy="-R $PROXY_HOST:$PROXY_PORT:$TARGET_HOST:$TARGET_PORT" ;;
  *)
    error "Unknown method: $PROXY_METHOD"
    exit 1
    ;;
esac

if [[ $ASK_PASSWORD = true ]]; then
  read -sp "Password: " SSH_PASSWORD
  echo
fi

if [[ -f /ssh_key ]]; then
  ARGS="-i /ssh_key $ARGS"
fi

function tunnel {
  if [[ $SSHPASS ]]; then
    (set -x; sshpass -e ssh $ARGS $proxy $SERVER)
  else
    (set -x; ssh $ARGS $proxy $SERVER)
  fi
  info "SSH exited with RC=$?"

  return $?
}

function main {
  local running=true
  local attempt=1
  while [[ $running = true ]]; do
    local start=$SECONDS
    tunnel
    local end=$SECONDS
    
    if [[ $(( $end - $start )) -gt 60 ]]; then
      attempt=1
    fi
    
    local delay=$(fibonacci $attempt)
    if [[ $delay -gt $MAX_SLEEP ]]; then
      delay=$MAX_SLEEP
    else
      attempt=$(( $attempt + 1 ))
    fi

    info "Next attempt in $delay seconds"
    sleep $delay
  done
}
main
