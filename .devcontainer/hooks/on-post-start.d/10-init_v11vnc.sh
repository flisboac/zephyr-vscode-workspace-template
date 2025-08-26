#!/bin/sh

set -e

SCRIPT_NAME="$(basename "${0}")"

if command -v v11vnc >/dev/null 2>/dev/null; then
  printf 'INFO: Initializing VNC server...\n' "${SCRIPT_NAME}" >&2
  v11vnc --create -forever
else
  printf 'INFO: Script "%s": Ignoring VNC server initialization.\n' "${SCRIPT_NAME}" >&2
fi

printf 'INFO: Script "%s": Finished.\n' "${SCRIPT_NAME}" >&2
