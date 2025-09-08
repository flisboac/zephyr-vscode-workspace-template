#!/bin/sh

WEST="${WEST:-"west"}"
PIP="${PIP}"
PIPX="${PIPX}"

UID="${UID:-"$(id -u)"}"

if [ "$UID" -eq 0 ]; then
    GLOBAL_WEST="${GLOBAL_WEST:-"1"}"
else
    GLOBAL_WEST="${GLOBAL_WEST:-"0"}"
fi

if [ "$#" -gt 0 ]; then
    printf 'FATAL: This script does not receive parameters.\n' >&2
    exit 1
fi

RESOLVED_WEST="$(command -v "${WEST}" 2>/dev/null)"
ERRNO="$?"

if [ "${ERRNO}" -eq 0 ] && [ ! -z "${RESOLVED_WEST}" ]; then
    printf 'INFO: West is already installed.\n' >&2
    printf '%s\n' "${RESOLVED_WEST}"
    exit 0
fi

if [ -z "${PIPX}" ]; then
    PIPX="$(command -v pipx 2>/dev/null)"
fi

if [ ! -z "${PIPX}" ]; then
    if [ -z "${GLOBAL_WEST}" ] || [ "${GLOBAL_WEST}" -eq 0 ]; then
        printf 'INFO: Installing West via pipx...\n' >&2
        "${PIPX}" install west >&2
        ERRNO="$?"
        pipx ensurepath || {
            printf 'FATAL: Failed to `pip ensurepath`!\n' >&2
            exit 1
        }
    else
        printf 'INFO: Installing West globally via pipx...\n' >&2
        # PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin "${PIPX}" install west >&2
        "${PIPX}" install --global west >&2
        ERRNO="$?"
        pipx ensurepath --global || {
            printf 'FATAL: Failed to `pip ensurepath`!\n' >&2
            exit 1
        }
    fi

    if [ "${ERRNO}" -eq 0 ]; then
        RESOLVED_WEST="$(command -v west)" || {
            printf 'FATAL: Failed to find installed west!\n' >&2
            exit 1
        }
    fi

else
    if [ -z "${PIP}" ]; then
        PIP="$(command -v pip 2>/dev/null)"
        if [ "$?" -ne 0 ] || [ -z "${PIP}" ]; then
            PIP="$(command -v pip3 2>/dev/null)"
        fi
    fi

    if [ -z "${PIP}" ]; then
        printf 'FATAL: Cannot install West: Could not find the `pip` executable.\n' >&2
        exit 1
    fi

    if [ ! -z "${VIRTUAL_ENV}" ]; then
        printf 'INFO: Installing West via pip in venv "%s"...\n' "${VIRTUAL_ENV}" >&2
        "${PIP}" install -U west >&2
        ERRNO="$?"
    elif [ -z "${GLOBAL_WEST}" ] || [ "${GLOBAL_WEST}" -eq 0 ]; then
        printf 'INFO: Installing West via pip in venv, globally...\n' >&2
        "${PIP}" install -U west >&2
        ERRNO="$?"
    else
        printf 'INFO: Installing West via pip in venv, in user folder...\n' >&2
        "${PIP}" install --user -U west >&2
        ERRNO="$?"
    fi

    if [ "${ERRNO}" -eq 0 ]; then
        RESOLVED_WEST="$(command -v west)" || {
            printf 'FATAL: Failed to find installed west!\n' >&2
            exit 1
        }
    fi
fi

if [ "${ERRNO}" -eq 0 ]; then
    if [ -z "${RESOLVED_WEST}" ]; then
        printf 'FATAL: west could not be found after installation!\n' >&2
        exit 1
    fi

    printf '%s\n' "${RESOLVED_WEST}"
fi

exit "${ERRNO}"
