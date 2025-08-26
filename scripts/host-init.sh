#!/bin/sh

set -e

SCRIPT_DIR="$( realpath -s "$(dirname "${0}")" )"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-"$( realpath -s "${SCRIPT_DIR}/.." )"}"

PRISTINE="${PRISTINE:-"0"}"

while [ "$#" -gt 0 ]; do
    case "$1" in
    --pristine) shift; PRISTINE="1" ;;
    -p) shift; PRISTINE="1" ;;
    -h) printf 'Usage: %s [OPTIONS] <REPO_URL> [WEST_FLAGS]\n' >&2; exit 0 ;;
    --) shift; break ;;
    -*) printf 'FATAL: Unknown option/flag: %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
    esac
done

if [ "$#" -gt 0 ]; then
    printf 'FATAL: This script does not receive positional parameters.\n' >&2
    exit 1
fi

export PRISTINE

for file in $(find "${WORKSPACE_ROOT}" -mindepth 1 -maxdepth 1 -type f -name '*.tpl.sh' -executable); do
    "${file}"
done

for file in $(find "${WORKSPACE_ROOT}/.devcontainer" -type f -name '*.tpl.sh' -executable); do
    "${file}"
done
