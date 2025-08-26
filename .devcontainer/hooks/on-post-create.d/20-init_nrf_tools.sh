#!/bin/sh

set -e 

if ! nrfutil list | grep device >/dev/null 2>/dev/null; then
  printf 'INFO: Script "%s": Installing nrfutil device command...\n' "${SCRIPT_NAME}" >&2
  nrfutil install device
else
  printf 'INFO: Script "%s": nrfutil device command already installed.\n' "${SCRIPT_NAME}" >&2
fi

if ! nrfutil list | grep toolchain-manager >/dev/null 2>/dev/null; then
  printf 'INFO: Script "%s": Installing nrfutil toolchain-manager command...\n' "${SCRIPT_NAME}" >&2
  nrfutil install toolchain-manager
else
  printf 'INFO: Script "%s": nrfutil toolchain-manager already installed.\n' "${SCRIPT_NAME}" >&2
fi

printf 'INFO: Script "%s": Finished.\n' "${SCRIPT_NAME}" >&2
