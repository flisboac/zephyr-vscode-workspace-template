#!/bin/sh

set -e

OWN_DIR="$( realpath -s "$(dirname "${0}")" )"
OWN_SCRIPTS_DIR="${OWN_DIR}/on-post-start.d/"
SCRIPT_NAME="$(basename "${0}")"

printf 'INFO: Script "%s": Looking for scripts at location: %s\n' "${0}" "${OWN_SCRIPTS_DIR}" >&2

find "${OWN_SCRIPTS_DIR}" -mindepth 1 -maxdepth 1 -executable -not -name '*.disabled' | sort | while read dev_init_script; do
  printf 'INFO: Executing script: %s\n' "${dev_init_script}" >&2
  "${dev_init_script}"
  printf 'INFO: Executed script: %s\n' "${dev_init_script}" >&2
done

printf 'INFO: Script "%s": Finished.\n' "${0}" >&2
