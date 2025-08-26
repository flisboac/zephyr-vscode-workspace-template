#!/bin/sh

set -e

SCRIPT_NAME="$(basename "${0}")"
SYSTEMD_UDEVD_CMD="${SYSTEMD_UDEVD_CMD:-"/lib/systemd/systemd-udevd"}"

if [ ! -z "${SYSTEMD_UDEVD_CMD}" ]; then
  __UDEV_STAT="$(ps -Ao command)"
  if ! printf '%s' "${__UDEV_STAT}" | grep -F "${SYSTEMD_UDEVD_CMD}" >/dev/null 2>/dev/null; then
    printf 'INFO: Script "%s": Initializing udev daemon...\n' "${SCRIPT_NAME}" >&2
    sudo "${SYSTEMD_UDEVD_CMD}" --daemon
  fi
else
  printf 'INFO: Script "%s": ignoring udev daemon initialization.\n' "${SCRIPT_NAME}" >&2
fi

printf 'INFO: Script "%s": Finished.\n' "${SCRIPT_NAME}" >&2
