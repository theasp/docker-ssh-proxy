#!/bin/bash

if [[ $DEBUG = true ]]; then
  LOGLEVEL=3
fi

function slog {
  local TAG=$1
  local L

  case $TAG in
    debug) L=3 TAG="DEBUG" ;;
    info)  L=2 TAG="INFO" ;;
    warn)  L=1 TAG="WARNING" ;;
    *)     L=0 TAG="ERROR";;
  esac

  if [[ $L -le ${LOGLEVEL:-2} ]]; then
    while read line; do
      echo "$(date +'%F %T') $TAG: $line" 1>&2
    done
  else
    cat > /dev/null
  fi
}

function log {
  local level=$1
  shift
  echo "$@" | slog $level
}

function error {
  log error "$@"
  exit 1
}

function debug {
  log debug "$@"
}

function info {
  log info "$@"
}

function fibonacci {
  local n=$1

  if [[ $n -eq 0 ]]; then
    echo 0
  else
    if [[ $n -eq 1 ]]; then
      echo 1
    else
      local prev=0
      local cur=1

      for _ in $(seq 2 $n); do
        local this=$(( $cur + $prev ))
        prev=$cur
        cur=$this
      done

      echo $cur
    fi
  fi
}

function backoff {
  local max_attempts=${ATTEMPTS:-12}
  local attempt=0
  local exitCode=0
  local delay=0

  while [[ $attempt -le $max_attempts ]]; do
    attempt=$(( attempt + 1 ))
    log info "Attempt $attempt/$max_attempts: $@"
    if (eval "$@"); then
      exitCode=0
      break
    else
      exitCode=$?
      delay=$(fibonacci $attempt)
      log info "Failure! Retrying in $delay.."
      sleep $delay
    fi
  done

  if [[ $exitCode = 0 ]]; then
    log info "Success"
  else
    log warn "Max attempts reached, giving up"
  fi

  return $exitCode
}
