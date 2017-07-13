#!/usr/bin/env bash
#
# Clone db using dump file

set -eo pipefail

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${CWD}/../lib/lib.sh"

load_config "$@"

src_login="-h${SRC_HOST} -u${SRC_USER} -p${SRC_PWD}"
dst_login="-h${DST_HOST} -u${DST_USER} -p${DST_PWD}"

main() {
  if [[ ! -z "${BACKUP_DIR// }" ]]; then
    log::info "starting backup of current database: ${DST_HOST}/${DST_DB}/${table:-*}"
    
    mkdir -v -p "${BACKUP_DIR}"
    
    if [ ! -z ${SRC_TABLES+test} ]; then
      for table in "${SRC_TABLES[@]}"; do save_dump "${table}"; done
    else
      save_dump
    fi
    
    log::info "backup finished"
  fi

  if [[ "${FLUSH_DB}" == true ]]; then
    log "droping current database (if any)..."
    mysql ${dst_login} -v -e "DROP DATABASE IF EXISTS ${DST_DB}" || true
  fi

  log "creating new database (if not any)..."
  mysql ${dst_login} -v -e "CREATE DATABASE IF NOT EXISTS ${DST_DB}"

  log "database cloning..."
  if [ ! -z ${SRC_TABLES+test} ]; then
    for table in "${SRC_TABLES[@]}"; do pipe_clone "${table}"; done
  else
    pipe_clone
  fi

  log::ok "$0 finished!"
}

# pipe one db to another
pipe_clone() {
  local table="$1"

  log "pipe cloning ${SRC_HOST}/${SRC_DB}/${table:-*} to \
    ${DST_HOST}/${DST_DB}/${table:-*}..."

  local cmd="mysqldump -v -f ${src_login} ${SRC_DB} ${table}"
  if [[ ! -z "${FILTER// }" ]]; then
    log "using configured filter: ${FILTER}"
    cmd="${cmd} | ${FILTER}"
  fi

  cmd="${cmd} | mysql ${dst_login} ${DST_DB}"

  [[ "${VERBOSE}" == true ]] && log "${cmd}"

  eval "${cmd}"

  log::info "${SRC_HOST}/${SRC_DB}/${table:-*} is cloned to \
    mysql://${DST_HOST}/${DST_DB}/${table:-*}"
}

# save dumps of selected databases and tables
save_dump() {
  local table="$1"

  local backup_fpath="${BACKUP_DIR}/${DST_DB}_${table}.sql.gz"
  log "backuping ${DST_HOST}/${DST_DB}/${table:-*}..."

  local cmd="mysqldump -v -f ${dst_login} ${DST_DB} ${table} | gzip > ${backup_fpath}"

  [[ "${VERBOSE}" == true ]] && log "${cmd}"

  eval "${cmd}"

  log "${DST_HOST}/${DST_DB}/${table:-*} is saved at: ${backup_fpath}"
  log "${BACKUP_DIR} size is: $(du -h "${BACKUP_DIR}")"
}

main "$@"
