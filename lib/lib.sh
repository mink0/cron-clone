#!/usr/bin/env bash
#
# Service functions for clone scripts

# colors will be only aviable in interactive shell
if [ -t 1 ]; then
  readonly COLOR_DEF='\033[0;39m'
  readonly COLOR_DGRAY='\033[1;30m'
  readonly COLOR_LRED='\033[1;31m'
  readonly COLOR_LCYAN='\033[1;36m'
  readonly COLOR_LGREEN='\033[1;32m'
  readonly COLOR_LYELLOW='\033[1;33m'
  readonly COLOR_LBLUE='\033[1;34m'
  readonly COLOR_LMAGENTA='\033[1;35m'
fi

# Parse options and read config from file
# Arguments:
#   Call it with "$@" parameter from parent script
load_config() {
  log "starting $0.."
  parse_opts "$@"

  # check required params
  if [[ -z "${CONFIG_PATH// }" ]]; then
    CONFIG_PATH="${CWD}/$(basename $0 .sh).conf"
    log::warn "no config file is set, trying default at ${CONFIG_PATH}"
    [ ! -f "${CONFIG_PATH}" ] && exception "Config file not found!"
  fi

  [[ "${VERBOSE}" == true ]] && log "loading config from: ${CONFIG_PATH}"
  source "${CONFIG_PATH}"
  [[ "${VERBOSE}" == true ]] && log "config is loaded"

  if [[ "${VERBOSE}" == true ]]; then
    log "environment and variables:"
    set -o posix; set
  fi
}

# Options parser
# Arguments:
#   Call it with "$@" parameter from parent script
parse_opts() {
  usage() {
    echo -e "Usage: $0 [options]"
    echo -e "\t-c --config \t\t Path to config file"
    echo -e "\t-v --verbose \t\t Turn on verbose output"
    echo -e "\t-h --help \t\t Display this message"
    echo ""
  }

  # defaults
  VERBOSE=false
  CONFIG_PATH=""

  while getopts "h?vc:" opt; do
    case "$opt" in
    h|\?) usage; exit 0
    ;;
    v) VERBOSE=true
    ;;
    c) CONFIG_PATH=$OPTARG
    ;;
    esac
  done
}

# print message
log() {
  echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S%z')]: $@"
}

# print error message into stderr
err() {
  log "${COLOR_LRED}$@${COLOR_DEF}" >&2
}

# fancy print log message in green color
log::ok() {
  log "${COLOR_LGREEN}$@${COLOR_DEF}"
}

# fancy print log message in red color
log::warn() {
  log "${COLOR_LYELLOW}$@${COLOR_DEF}"
}

# fancy print log message in yellow color
log::info() {
  log "${COLOR_LCYAN}$@${COLOR_DEF}"
}

# Throw error and exit
exception() {
  err "$@"
  exit 1
}
