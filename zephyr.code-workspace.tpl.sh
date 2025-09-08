#!/bin/sh

set -e

#
# BASIC SCRIPT VARIABLES
#

OWN_DIR="$( realpath -s "$(dirname "${0}")" )"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-"${OWN_DIR}"}"
WORKSPACE_SCRIPTS_DIR="${WORKSPACE_SCRIPTS_DIR:-"${WORKSPACE_ROOT}/scripts"}"
WORKSPACE_SCRIPTS_INCLUDE_DIR="${WORKSPACE_SCRIPTS_INCLUDE_DIR:-"${WORKSPACE_SCRIPTS_DIR}/include"}"

. "${WORKSPACE_SCRIPTS_INCLUDE_DIR}/template.inc.sh"

#
# DEPENDENT ENV FILES
#

_source_tpl_env_file host.env

#
# TARGET FILE GENERATION
#


_do_generate_file() {
    local _target_file
    _target_file="${1}"; shift
cat >"${_target_file}" <<EOF
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
}

_generate_target_file

log_verbose_ok 'Done.'


