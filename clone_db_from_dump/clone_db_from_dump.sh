#!/usr/bin/env bash
#
# Clone db using dump file

set -eo pipefail

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${CWD}/../lib/lib.sh"

load_config "$@"

login="-h${DST_DB_HOST} -u${DST_DB_USER} -p${DST_DB_PWD}"

mkdir -v -p ${DST_DIR}
scp -i "${SSH_KEY}" "${SSH_USER}@${SRC_HOST}:${SRC_DIR}/${DUMP_FILE}" "${DST_DIR}" ||
  exception "Can't download file: ${SRC_HOST}:${SRC_DIR}/${DUMP_FILE}"

log::info "${DUMP_FILE} was downloaded to ${DST_DIR}"

backup_fpath="${DST_DIR}/${DST_DB_NAME}_backup.sql.gz"
log "saving current database..."
mysqldump -v -f ${login} "${DST_DB_NAME}" | gzip > "${backup_fpath}"
log::info "current database saved at: ${backup_fpath}"

if [[ "${FLUSH_DB}" == true ]]; then
  log "droping current database (if any)..."
  mysql ${login} -v -e "DROP DATABASE IF EXISTS ${DST_DB_NAME}" || true
fi

log "creating new database (if not any)..."
mysql ${login} -v -e "CREATE DATABASE IF NOT EXISTS ${DST_DB_NAME}"  || true

log "loading ${DUMP_FILE} into database..."
cmd="zcat ${DST_DIR}/${DUMP_FILE}"
if [[ ! -z "${FILTER// }" ]]; then
  log "using configured filter: ${FILTER}"
  cmd="${cmd} | ${FILTER}"
fi

cmd="${cmd} | mysql ${login} ${DST_DB_NAME}"

[[ "${VERBOSE}" == true ]] && log "${cmd}"
eval "${cmd}"

log::info "${SRC_HOST}:${SRC_DIR}/${DUMP_FILE} is cloned to mysql://${DST_DB_HOST}/${DST_DB_NAME}"

log::ok "$0 finished!"
