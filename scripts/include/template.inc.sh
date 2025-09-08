#!/bin/sh

: ${OWN_DIR?Missing env-var OWN_DIR}
: ${WORKSPACE_ROOT?Missing env-var WORKSPACE_ROOT}

TPL_SUFFIX=".tpl.sh"
OWN_FILE="$( realpath -s "${0}" )"
OWN_DIR="$( dirname "${OWN_FILE}" )"
TARGET_FILE="${OWN_DIR}/$(basename "${0}" "${TPL_SUFFIX}")"

if [ -e "${TARGET_FILE}.defaults" ]; then
    . "${TARGET_FILE}.defaults"
fi

WORKSPACE_NAME="${WORKSPACE_NAME:-"$(basename "${WORKSPACE_ROOT}")"}"
WORKSPACE_SCRIPTS_DIR="${WORKSPACE_SCRIPTS_DIR:-"${WORKSPACE_ROOT}/scripts"}"
WORKSPACE_SCRIPTS_INCLUDE_DIR="${WORKSPACE_SCRIPTS_INCLUDE_DIR:-"${WORKSPACE_SCRIPTS_DIR}/include"}"

. "${WORKSPACE_SCRIPTS_INCLUDE_DIR}/log-utils.inc.sh"


log_debug_ok 'Workspace root: %s' "${WORKSPACE_ROOT}"
log_debug_ok 'Default Workspace name: %s' "${WORKSPACE_NAME}"

#
# UTILITIES
#
# NOTE: All functions take a file path relative to the workspace root.
#

_realpath_workspace() (
    cd "${WORKSPACE_ROOT}"; realpath -s "${_tgt_file}"
)

_realpath_workspace_tmpfile() {
    local file
    local abs_file
    local tmp_file
    local rel_file
    file="$1"; shift
    abs_file="$( _realpath_workspace "${_tgt_file}" )"
    rel_file="$( realpath -s --relative-base="${WORKSPACE_ROOT}" "${abs_file}" )"
    if [ "${abs_file}" = "${rel_file}" ]; then
        log_debug 'Possible templated file "%s" (absolute path: "%s") is outside root workspace folder "%s".' "${file}" "${abs_file}" "${WORKSPACE_ROOT}"
        printf ''
        return 1
    fi
    printf '%s' "$(realpath -s "${_TEMP_CONTENTS_DIR}/${_REL_TARGET_FILE}")"
}

_tpl_file_checked() {
    local file
    local tmp_file
    file="$1"; shift
    tmp_file="$(_realpath_workspace_tmpfile "${file}")"
    [ ! -z "${tmp_file}" ] && [ -e "${file}" ]
}

_source_tpl_env_file() {
    local _file
    local _tpl_file
    local _tgt_file
    while [ "$#" -gt 0 ]; do
        _file="${1}"; shift
        _tgt_file="${_file}"
        _tgt_file="$(_realpath_workspace "${_tgt_file}")"
        _tpl_file="${_tgt_file}${TPL_SUFFIX}"
        if ! _tpl_file_checked "${_file}"; then
            log_verbose 'Generating dependent file: %s: %s -> %s' "${OWN_FILE}" "${_tpl_file}" "${_tgt_file}"
            "${_tpl_file}"
        fi
        . "${_tgt_file}"
    done
}

_execute_tpl_script_file() {
    local _file
    local _tpl_file
    local _tgt_file
    while [ "$#" -gt 0 ]; do
        _file="${1}"; shift
        _tgt_file="${_file}"
        _tgt_file="$(_realpath_workspace "${_tgt_file}")"
        _tpl_file="${_tgt_file}${TPL_SUFFIX}"
        if ! _tpl_file_checked "${_file}"; then
            log_verbose 'Generating dependent file: %s: %s -> %s' "${OWN_FILE}" "${_tpl_file}" "${_tgt_file}"
            "${_tpl_file}"
        fi
        "${_tgt_file}"
    done
}

_ensure_tpl_file() {
    local _file
    local _tpl_file
    local _tgt_file
    while [ "$#" -gt 0 ]; do
        _file="${1}"; shift
        _tgt_file="${_file}"
        _tgt_file="$(_realpath_workspace "${_tgt_file}")"
        _tpl_file="${_tgt_file}${TPL_SUFFIX}"
        if ! _tpl_file_checked "${_file}"; then
            log_verbose 'Generating dependent file: %s: %s -> %s' "${OWN_FILE}" "${_tpl_file}" "${_tgt_file}"
        fi
        "${_tpl_file}"
    done
}


#
# CLI PARSING
#

PRISTINE="${PRISTINE:-"0"}"

while [ "$#" -gt 0 ]; do
    case "$1" in
    --pristine) shift; PRISTINE="1" ;;
    -p) shift; PRISTINE="1" ;;
    --pristine-all) shift; export PRISTINE=1 ;;
    -P) shift; export PRISTINE=1 ;;
    -h) log_abort 0 'Usage: %s [OPTIONS]' >&2 ;;
    --) shift; break ;;
    -*) log_die 'Unknown option/flag: %s'  "$1" >&2 ;;
    *) break ;;
    esac
done

if [ "$#" -gt 0 ]; then
    log_die 'This script does not receive positional parameters.' >&2
fi


#
# INTERNAL ENV-VARS
#

if [ -z "${_TEMP_CONTENTS_DIR}" ]; then
    export _TEMP_CONTENTS_DIR="$(mktemp -t -d "$(basename "${TARGET_FILE}").tmp.XXXXXXXXXX")"
    trap 'rm -rf "${_TEMP_CONTENTS_DIR}"; trap - EXIT; exit' EXIT INT HUP
fi

_REL_TARGET_FILE="$(realpath -s --relative-base="${WORKSPACE_ROOT}" "${TARGET_FILE}")"

if [ "${TARGET_FILE}" = "${_REL_TARGET_FILE}" ]; then
    log_die 'Cannot have templated files outside root workspace folder "%s"!' "${WORKSPACE_ROOT}"
fi

_TMP_TARGET_FILE="$(realpath -s "${_TEMP_CONTENTS_DIR}/${_REL_TARGET_FILE}")"

#
# TARGET FILE GENERATION
#

# NOTE: Must be called in the including script (explicitly) in order to generate the target file!
# NOTE: Function `_do_generate_file` MUST be defined prior to calling this function!
_generate_target_file() {
    if [ -e "${_TMP_TARGET_FILE}" ]; then
        log_debug_ok 'Target file "%s" was already checked and/or generated.' "${TARGET_FILE}"
        return 0
    fi

    mkdir -p "$(dirname "${_TMP_TARGET_FILE}")"
    _do_generate_file "${_TMP_TARGET_FILE}"
    log_verbose_ok 'Generating temp-file "%s"...' "${_TMP_TARGET_FILE}"

    if [ -e "${TARGET_FILE}" ]; then
        log_verbose_ok 'Checking if existing target file "%s" needs to be rewritten...' "${TARGET_FILE}"

        if [ "${PRISTINE}" -eq 1 ]; then
            log_info_ok 'Template file "%s": Target file "%s" already exists, but will be recreated (pristine option enabled).' "${0}" "${TARGET_FILE}" >&2
            mv "${_TMP_TARGET_FILE}" "${TARGET_FILE}"

        elif command -v diff >/dev/null 2>/dev/null; then
            diff_tmpfile="$(mktemp -t)"
            cmd_errcode="$(
                set +e
                diff "${TARGET_FILE}" "${_TMP_TARGET_FILE}" \
                    -I '^# AUTOGENERATED AT' \
                    -I '^/* AUTOGENERATED AT' \
                    -c3 \
                    --to-file="${_TMP_TARGET_FILE}" \
                    --color="$([ "${LOG_COLORS}" -eq 1 ] && printf 'always' || printf 'never')" >"$diff_tmpfile"
                errcode="$?"
                echo "$errcode"
            )"
            case "${cmd_errcode}" in
                1)
                    cat "${diff_tmpfile}" | log_warn_ok - 'Template file "%s": Target file "%s" already exists, but the generated template content is different. Consider rewriting it via `--pristine`, or checking its contents. Diff:'  "${0}" "${TARGET_FILE}" >&2
                    rm -f "${diff_tmpfile}"
                    ;;
                0)
                    rm -f "${diff_tmpfile}"
                    log_verbose_ok 'Template file "%s": Target file "%s" already exists, and no changes were detected.' "${0}" "${TARGET_FILE}" >&2
                    ;;
                *)
                    rm -f "${diff_tmpfile}"
                    log_die 'Template file "%s": Failed to compare changes for target file "%s"! `diff` error code: %d!'  "${0}" "${TARGET_FILE}" "${cmd_errcode}" >&2
                    ;;
            esac

        elif [ "${0}" -nt "${TARGET_FILE}" ]; then
            log_warn_ok 'Template file "%s": Target file "%s" already exists, but the template is newer. Consider activating pristine mode, or reviewing its contents.'  "${0}" "${TARGET_FILE}" >&2

        else
            log_info_ok 'Template file "%s": Target file "%s" already exists. Skipping generation.' "${0}" "${TARGET_FILE}" >&2
        fi

    else
        log_info_ok 'Template file "%s": Creating target file "%s"...' "${0}" "${TARGET_FILE}" >&2
        mv "${_TMP_TARGET_FILE}" "${TARGET_FILE}"
    fi
}
