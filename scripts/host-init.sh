#!/bin/sh

set -e

#
# BASIC SCRIPT VARIABLES
#

OWN_DIR="$( realpath -s "$(dirname "${0}")" )"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-"${OWN_DIR}/.."}"
WORKSPACE_SCRIPTS_DIR="${WORKSPACE_SCRIPTS_DIR:-"${WORKSPACE_ROOT}/scripts"}"
WORKSPACE_SCRIPTS_INCLUDE_DIR="${WORKSPACE_SCRIPTS_INCLUDE_DIR:-"${WORKSPACE_SCRIPTS_DIR}/include"}"

. "${WORKSPACE_SCRIPTS_INCLUDE_DIR}/log-utils.inc.sh"

PRISTINE="${PRISTINE:-"0"}"

export _TEMP_CONTENTS_DIR="$(mktemp -t -d "$(basename "${TARGET_FILE}").tmp.XXXXXXXXXX")"
trap 'rm -rf "${_TEMP_CONTENTS_DIR}"; trap - EXIT; exit' EXIT INT HUP

while [ "$#" -gt 0 ]; do
    case "$1" in
    --pristine) shift; export PRISTINE="1" ;;
    -p) shift; export PRISTINE="1" ;;
    -h) log_abort 0 'Usage: %s [OPTIONS] <REPO_URL> [WEST_FLAGS]' ;;
    --) shift; break ;;
    -*) log_die 'Unknown option/flag: %s\n' "$1" ;;
    *) break ;;
    esac
done

if [ "$#" -gt 0 ]; then
    log_die 'This script does not receive positional parameters.'
fi

for file in $(find "${WORKSPACE_ROOT}" -mindepth 1 -maxdepth 1 -type f -name '*.tpl.sh' -executable); do
    "${file}"
done

for file in $(find "${WORKSPACE_ROOT}/.devcontainer" -type f -name '*.tpl.sh' -executable); do
    "${file}"
done

log_verbose_ok 'Done.'
