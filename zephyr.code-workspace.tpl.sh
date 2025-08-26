#!/bin/sh

set -e

#
# DEFAULTS
#


OWN_SUFFIX=".tpl.sh"

#
# BASIC VARIABLES
#

OWN_DIR="$( realpath -s "$(dirname "${0}")" )"
TARGET_FILE="${OWN_DIR}/$(basename "${0}" "${OWN_SUFFIX}")"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-"$( realpath -s "${OWN_DIR}/" )"}"
WORKSPACE_NAME="${WORKSPACE_NAME:-"$(basename "${WORKSPACE_ROOT}")"}"

if [ -e "${TARGET_FILE}.defaults" ]; then
    . "${TARGET_FILE}.defaults"
fi

#
# OTHER VARIABLES
#

# ...

#
# CLI PARSING
#

PRISTINE="${PRISTINE:-"0"}"

while [ "$#" -gt 0 ]; do
    case "$1" in
    --pristine) shift; PRISTINE="1" ;;
    -p) shift; PRISTINE="1" ;;
    -h) printf 'Usage: %s [OPTIONS]\n' >&2; exit 0 ;;
    --) shift; break ;;
    -*) printf 'FATAL: Unknown option/flag: %s\n'  "$1" >&2; exit 1 ;;
    *) break ;;
    esac
done

if [ "$#" -gt 0 ]; then
    printf 'FATAL: This script does not receive positional parameters.\n' >&2
    exit 1
fi

#
# DEPENDENT ENV FILES
#

export PRISTINE

"${WORKSPACE_ROOT}/host.env${OWN_SUFFIX}"
. "${WORKSPACE_ROOT}/host.env"

#
# TARGET FILE GENERATION
#

if [ -e "${TARGET_FILE}" ]; then
    if [ "${PRISTINE}" -eq 1 ]; then
        printf 'INFO: Template file "%s": Target file "%s" already exists, but will be recreated.\n' "${0}" "${TARGET_FILE}" >&2
    elif [ "${0}" -nt "${TARGET_FILE}" ]; then
        printf 'WARN: Template file "%s": Target file "%s" already exists, but the template is newer. Consider activating pristine mode, or reviewing its contents.\n'  "${0}" "${TARGET_FILE}" >&2
        exit 0
    else
        printf 'INFO: Template file "%s": Target file "%s" already exists.\n' "${0}" "${TARGET_FILE}" >&2
        exit 0
    fi
else
    printf 'INFO: Template file "%s": Creating target file "%s"...\n' "${0}" "${TARGET_FILE}" >&2
fi

cat >"${TARGET_FILE}" <<EOF
{
  "folders": [
    {
      "path": "./",
      "name": "Workspace-Root"
    }
  ],
  "extensions": {
    "recommendations": [
      "CS128.cs128-clang-tidy",
      "eamodio.gitlens",
      "EditorConfig.EditorConfig",
      "lextudio.restructuredtext",
      "marus25.cortex-debug",
      "mcu-debug.debug-tracker-vscode",
      "mcu-debug.rtos-views",
      "mhutchie.git-graph",
      "ms-azuretools.vscode-docker",
      "ms-python.python",
      "ms-vscode.cmake-tools",
      "ms-vscode.cpptools-themes",
      "ms-vscode.cpptools",
      "ms-vscode.vscode-embedded-tools",
      "ms-vscode.vscode-serial-monitor",
      "mylonics.zephyr-ide",
      "nordic-semiconductor.nrf-connect-extension-pack",
      "nordic-semiconductor.nrf-connect",
      "nordic-semiconductor.nrf-devicetree",
      "nordic-semiconductor.nrf-kconfig",
      "redhat.vscode-yaml",
      "stkb.rewrap",
      "trond-snekvik.gnu-mapfiles",
      "wayou.vscode-todo-highlight",
      "xaver.clang-format"
    ],
    "unwantedRecommendations": [
      "ms-vscode.cpptools-extension-pack"
    ]
  }
}
EOF
