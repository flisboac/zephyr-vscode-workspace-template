#!/bin/sh

set -e

SCRIPT_DIR="$( realpath -s "$(dirname "${0}")" )"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-"$( realpath -s "${SCRIPT_DIR}/.." )"}"

WEST_WORKSPACE_DIRNAME="${WEST_WORKSPACE_DIRNAME:-"projects"}"

WEST="$("${SCRIPT_DIR}/dev-ensure-west.sh")"

while [ "$#" -gt 0 ]; do
    case "$1" in
    -h) printf 'Usage: %s [OPTIONS] <REPO_URL> [WEST_FLAGS]\n' >&2; exit 0 ;;
    --) shift; break ;;
    -*) printf 'FATAL: Unknown option/flag: %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
    esac
done

if [ "$#" -gt 0 ]; then
    printf 'FATAL: Missing repository URL.\n' >&2
    exit 1
fi

REPO_URL="${1}"
shift

cd "${WORKSPACE_ROOT}"
exec "${WEST}" init -m "${REPO_URL}" $? "${WEST_WORKSPACE_DIRNAME}/"
