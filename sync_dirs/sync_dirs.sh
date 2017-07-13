#!/usr/bin/env bash
#
# Copy remote directory using scp

set -eo pipefail

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${CWD}/../lib/lib.sh"

load_config "$@"

main() {
  log::ok "$0 starting"

  local i src dst
  for i in {1..20}; do
    # bash it, baby!
    eval src="\$SRC_DIR$i"
    eval dst="\$DST_DIR$i"

    [[ ! -z "${src// }" ]] && clone "${src}" "${dst}"
  done

  log::ok "$0 finished!"
}

clone() {
  local src="$1"
  local dst="$2"

  local reset_cmd="sudo chmod -R g+w '${dst}' && sudo chown -R '${DST_USER}:${DST_USER}' '${dst}'"
  local clone_cmd
  case "${CLONE_TYPE}" in
    "rsync")
      clone_cmd="rsync -chavz -O -e 'ssh -i ${SSH_KEY}' '${SRC_USER}@${SRC_HOST}':'${src}' '${dst}'"
    ;;
    "scp")
      clone_cmd="scp -r -i '${SSH_KEY}' '${SRC_USER}@${SRC_HOST}':'${src}' '${dst}'"
    ;;
    "*")
      exception "unknown CLONE_TYPE type ${CLONE_TYPE}"
    ;;
  esac

  log "cloning ${SRC_HOST}:${src} to ${dst}"
  [[ "${VERBOSE}" == true ]] && log "${reset_cmd}"
  eval "${reset_cmd}"
  [[ "${VERBOSE}" == true ]] && log "${clone_cmd}"
  eval "${clone_cmd}"
  [[ "${VERBOSE}" == true ]] && log "${reset_cmd}"
  eval "${reset_cmd}"

  log::info "${SRC_HOST}:${src} is downloaded"
}

main "$@"