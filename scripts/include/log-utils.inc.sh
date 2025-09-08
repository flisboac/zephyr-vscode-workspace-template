#!/bin/sh

LOG_FILE="${LOG_FILE:-"2"}" # If it starts with number, MUST be a valid file descriptor number! Else, will be considered a normal (filesystem) file name.
LOG_PRESERVE_STDOUT_FD="${LOG_PRESERVE_STDOUT_FD:-"5"}"
LOG_LEVEL="${LOG_LEVEL:-"info"}"
LOG_EXITCODE="${LOG_EXITCODE:-"1"}"
LOG_MODULE="${LOG_MODULE:-"$(basename "$0")"}"
LOG_FORMAT="${LOG_FORMAT:-"text"}" # valid values: text, jsonln (requires "jq")
LOG_FILE_ISTTY="${LOG_FILE_ISTTY:-"$(if [ -t "${LOG_FILE}" ]; then printf '1'; else printf '0'; fi)"}"
LOG_COLORS="${LOG_COLORS:-"$(if [ "${LOG_FILE_ISTTY}" -eq 1 ]; then printf '1'; else printf '0'; fi)"}"

LOG_MODULE_SEP="/"

LOG_COLOR_FG_RESET='\e[0m'
LOG_COLOR_FG_BLACK='\e[30m'
LOG_COLOR_FG_RED='\e[31m'
LOG_COLOR_FG_GREEN='\e[32m'
LOG_COLOR_FG_YELLOW='\e[33m'
LOG_COLOR_FG_BLUE='\e[34m'
LOG_COLOR_FG_MAGENTA='\e[35m'
LOG_COLOR_FG_CYAN='\e[36m'
LOG_COLOR_FG_WHITE='\e[37m'

LOG_LEVELNUM_DEBUG=80
LOG_LEVELNUM_VERBOSE=70
LOG_LEVELNUM_INFO=60
LOG_LEVELNUM_REQ=50
LOG_LEVELNUM_WARN=40
LOG_LEVELNUM_ERROR=30
LOG_LEVELNUM_FATAL=20
LOG_LEVELNUM_ABORT=10

LOG_LEVELNAME_DEBUG="DEBUG"
LOG_LEVELNAME_VERBOSE="VERB"
LOG_LEVELNAME_INFO="INFO"
LOG_LEVELNAME_REQ="REQ"
LOG_LEVELNAME_WARN="WARN"
LOG_LEVELNAME_ERROR="ERROR"
LOG_LEVELNAME_FATAL="FATAL"
LOG_LEVELNAME_ABORT="ABORT"

log_printfc() {
    local color="$1"; shift
    local msg="$1"; shift
    if [ "${LOG_COLORS}" -eq 1 ]; then
        printf "${color}${msg}${LOG_COLOR_FG_RESET}" "$@"
    else
        printf "${msg}" "$@"
    fi
}
log_printfc_black() { log_printfc "${LOG_COLOR_FG_BLACK}" "$@"; }
log_printfc_red() { log_printfc "${LOG_COLOR_FG_RED}" "$@"; }
log_printfc_green() { log_printfc "${LOG_COLOR_FG_GREEN}" "$@"; }
log_printfc_yellow() { log_printfc "${LOG_COLOR_FG_YELLOW}" "$@"; }
log_printfc_blue() { log_printfc "${LOG_COLOR_FG_BLUE}" "$@"; }
log_printfc_magenta() { log_printfc "${LOG_COLOR_FG_MAGENTA}" "$@"; }
log_printfc_cyan() { log_printfc "${LOG_COLOR_FG_CYAN}" "$@"; }
log_printfc_white() { log_printfc "${LOG_COLOR_FG_WHITE}" "$@"; }

log_nametolvl() {
    local lvl="$1"; shift
    case "$lvl" in
    [0-9]*) printf '%d\n' "$lvl" ;;
    [dD][eE][bB][uU][gG]*) printf '%d\n' "${LOG_LEVELNUM_DEBUG}" ;;
    [vV][eE][rR][bB]*) printf '%d\n' "${LOG_LEVELNUM_VERBOSE}" ;;
    [iI][nN][fF][oO]*) printf '%d\n' "${LOG_LEVELNUM_INFO}" ;;
    [rR][eE][qQ]*) printf '%d\n' "${LOG_LEVELNUM_REQ}" ;;
    [wW][aA][rR][nN]*) printf '%d\n' "${LOG_LEVELNUM_WARN}" ;;
    [eE][rR][rR][oO][rR]*) printf '%d\n' "${LOG_LEVELNUM_ERROR}" ;;
    [fF][aA][tT][aA][lL]*) printf '%d\n' "${LOG_LEVELNUM_FATAL}" ;;
    [aA][bB][oO][rR][tT]*) printf '%d\n' "${LOG_LEVELNUM_ABORT}" ;;
    *) return 1 ;;
    esac
    return 0
}
log_lvltoname() (
    set -e
    local lvl="$1"; shift
    case "${lvl}" in
    [0-9]*)
        lvl="$(log_nametolvl "${lvl}")"
        if [ "${lvl}" -ge "${LOG_LEVELNUM_DEBUG}" ]; then printf '%s\n' "${LOG_LEVELNUM_DEBUG}"; return 0; fi
        if [ "${lvl}" -ge "${LOG_LEVELNUM_VERBOSE}" ]; then printf '%s\n' "${LOG_LEVELNUM_VERBOSE}"; return 0; fi
        if [ "${lvl}" -ge "${LOG_LEVELNUM_INFO}" ]; then printf '%s\n' "${LOG_LEVELNUM_INFO}"; return 0; fi
        if [ "${lvl}" -ge "${LOG_LEVELNUM_REQ}" ]; then printf '%s\n' "${LOG_LEVELNUM_REQ}"; return 0; fi
        if [ "${lvl}" -ge "${LOG_LEVELNUM_WARN}" ]; then printf '%s\n' "${LOG_LEVELNUM_WARN}"; return 0; fi
        if [ "${lvl}" -ge "${LOG_LEVELNUM_ERROR}" ]; then printf '%s\n' "${LOG_LEVELNUM_ERROR}"; return 0; fi
        if [ "${lvl}" -ge "${LOG_LEVELNUM_FATAL}" ]; then printf '%s\n' "${LOG_LEVELNUM_FATAL}"; return 0; fi
        if [ "${lvl}" -ge "${LOG_LEVELNUM_ABORT}" ]; then printf '%s\n' "${LOG_LEVELNUM_ABORT}"; return 0; fi
        ;;
    *)
        printf '%s\n' "${lvl}"
        return 0
        ;;
    esac
    return 1
)
log_checklvl() {
    local lvl="$(log_nametolvl "$1")"; shift
    local reqlvl="$(log_nametolvl "${LOG_LEVEL}")"
    [ "${lvl}" -le "${reqlvl}" ]
}
log_printf_text() {
    local loglvl="$(log_get_levelname "$1")"; shift
    local modulename="$1"; shift
    local logtemplate="$1"; shift
    local log_stdout="$1"; shift
    local preserve_stdout="$1"; shift
    local timestamp="$(log_get_timestamp)"
    local username="$(log_get_username)"
    local hostname="$(log_get_hostname)"
    local log_entry
    local has_logtemplate
    if [ ! -z "${logtemplate}" ]; then
        has_logtemplate="1"
    else
        has_logtemplate="0"
    fi
    logtemplate="🛈 $(log_printfc_green %s %s) $(log_printfc_blue %s %s) @ $(log_printfc_cyan %s %s) :: $(log_printfc_yellow %s %s) [$(log_printfc_red %s '% 7s')] ${logtemplate}\n"
    log_entry="$(printf "${logtemplate}" "${timestamp}" "${username}" "${hostname}" "${modulename}" "${loglvl}" "$@")"
    case "${LOG_FILE}" in
    -) printf '%s\n' "${log_entry}" ;;
    [0-9]*) printf '%s\n' "${log_entry}" >&$LOG_FILE ;;
    [!0-9]*) printf '%s\n' "${log_entry}" >"$LOG_FILE" ;;
    *) printf '%s\n' "${log_entry}" "$@" >&2 ;;
    esac
    if [ "${log_stdout}" -eq 1 ]; then
        if [ "${has_logtemplate}" -eq 1 ]; then
            case "${LOG_FILE}" in
            -) printf '\n' ;;
            [0-9]*) printf '\n' >&$LOG_FILE ;;
            [!0-9]*) printf '\n' >>"$LOG_FILE" ;;
            *) printf '\n' >&2 ;;
            esac
        fi
        if [ ! "${preserve_stdout}" -eq 1 ]; then
            case "${LOG_FILE}" in
            -) cat ;;
            [0-9]*) cat >&$LOG_FILE ;;
            [!0-9]*) cat >>"$LOG_FILE" ;;
            *) cat >&2 ;;
            esac
        else
            case "${LOG_FILE}" in
            -|1) cat ;;
            # Not exactly POSIX-portable, but eh.
            [0-9]*) cat | tee "/dev/fd/${LOG_FILE}" ;;
            [!0-9]*) cat | tee "$LOG_FILE" ;;
            *) cat >&1 >&2 ;;
            esac
        fi
    elif [ "${preserve_stdout}" -eq 1 ]; then
        cat
    fi
}
log_printf_jsonln() {
    local loglvl="$1"; shift
    local modulename="$1"; shift
    local logtemplate="$1"; shift
    local jq_flags=""
    local log_stdout="$1"; shift
    local stdout
    local preserve_stdout="$1"; shift
    if [ "${LOG_COLORS}" -eq 1 ]; then
        jq_flags="${jq_flags} --color-output"
    elif [ "${LOG_COLORS}" -eq 0 ]; then
        jq_flags="${jq_flags} --monochrome-output"
    fi
    if [ "${log_stdout}" -eq 1 ]; then
        if [ ! "${preserve_stdout}" -eq 1 ]; then
            stdout="$(cat)"
        else
            (
                exec 5>&1
                stdout="$( cat | tee | cat - >&5 )"
            )
        fi
    elif [ "${preserve_stdout}" -eq 1 ]; then
        cat
    fi
    log_entry="$(
        jq $jq_flags -c -n '{ "timestamp": $TIM, "username": $USR, "hostname": $HST, "module": $MOD, "level_num": $LVN, "level": $LVL, "message": $MSG, "stdout": $OUT }' \
            --arg TIM "$(log_get_timestamp)" \
            --arg USR "$(log_get_username)" \
            --arg HST "$(log_get_hostname)" \
            --arg MOD "${modulename}" \
            --arg LVN "$(log_get_levelnum "${loglvl}")" \
            --arg LVL "$(log_get_levelname "${loglvl}")" \
            --arg MSG "$(printf "${logtemplate}\n" "$@")" \
            --arg OUT "${stdout}"
    )"
    case "${LOG_FILE}" in
    -) printf '%s\n' "${log_entry}" ;;
    [0-9]*) printf '%s\n' "${log_entry}" >&$LOG_FILE ;;
    *) printf '%s\n' "${log_entry}" "$@" >&2 ;;
    esac
}
log_subshell() { LOG_MODULE="${LOG_MODULE}${LOG_MODULE_SEP}${1?"Missing sub-module name"}"; }
log_printf() { log_printf_$LOG_FORMAT "$@"; }
log_get_hostname() { if [ ! -z "${LOG_HOSTNAME}" ]; then printf '%s\n' "${LOG_HOSTNAME}"; else hostname; fi; }
log_get_username() { if [ ! -z "${LOG_USERNAME}" ]; then printf '%s\n' "${LOG_USERNAME}"; else id -un; fi; }
log_get_timestamp() { if [ ! -z "${LOG_TIMESTAMP_CMD}" ]; then $LOG_TIMESTAMP_CMD; else date -Ins --utc; fi; }
log_get_levelname() { log_lvltoname "$1"; }
log_get_levelnum() { log_nametolvl "$1"; }
log() {
    local exitcode="$?"
    local lvl
    local msg
    local at
    local do_exit=0
    local log_stdout="0"
    local preserve_stdout="0"
    local explicit_exitcode="0"
    at="${LOG_MODULE}"
    while [ "$#" -gt 0 ]; do
        case "$1" in
        -) shift; log_stdout="1" ;;
        -1) shift; preserve_stdout="1" ;;
        --preserve-stdout) shift; preserve_stdout="1" ;;
        --) shift; break ;;
        --level) shift; lvl="$1"; shift ;;
        --level=*) lvl="${1#--level=}"; shift ;;
        @*) at="${at}${LOG_MODULE_SEP}${1#@}"; shift ;;
        --in) shift; at="${at}${LOG_MODULE_SEP}${1}"; shift ;;
        --in=*) at="${at}${LOG_MODULE_SEP}${1#--in=}"; shift ;;
        --module) shift; at="${1}"; shift ;;
        --module=*) at="${1#--module=}"; shift ;;
        -c) shift; exitcode="$1"; explicit_exitcode="1"; shift ;;
        -c*) exitcode="${1#-c}"; explicit_exitcode="1"; shift ;;
        --code) shift; exitcode="$1"; explicit_exitcode="1"; shift ;;
        --code=*) exitcode="${1#--code=}"; explicit_exitcode="1"; shift ;;
        -e) do_exit="1"; shift ;;
        --exit) do_exit="1"; shift ;;
        --capture-stdout) log_stdout="1" ;;
        -*) printf '*** [LOG-UTILS] ERROR: Incorrect flag or parameter: %s\n' "$1" >&2; return 1 ;;
        *) break ;;
        esac
    done
    if [ -z "${lvl}" ]; then
        if [ "$#" -le 0 ]; then
            printf '*** [LOG-UTILS] ERROR: Missing log level.\n' >&2
            return 1
        fi
        lvl="$1"; shift
    fi
    if [ "$#" -le 0 ]; then
        if [ "${log_stdout}" -ne 1 ]; then
            printf '*** [LOG-UTILS] ERROR: Missing log message.\n' >&2
            return 1
        fi
    else
        msg="$1"; shift
    fi
    if [ ! "${explicit_exitcode}" -eq 1 ] \
        && { [ "${preserve_stdout}" -eq 1 ] || [ "${log_stdout}" -eq 1 ]; };
    then
        if [ "$(basename "${SHELL}")" = "bash" ]; then
            exitcode="${PIPESTATUS[0]}"
        fi
        if [ "$(basename "${SHELL}")" = "zsh" ]; then
            exitcode="${pipestatus[1]}"
        fi
        # Unfortunately, DASH doesn't have something similar.
    fi
    if log_checklvl "${lvl}"; then
        log_printf "${lvl}" "${at}" "${msg}" "${log_stdout}" "${preserve_stdout}" "$@"
    fi
    if [ "${do_exit}" -eq 1 ]; then
        exit "${exitcode}"
    fi
    return "${exitcode}"
}

#
# Abbreviated log functions preserving last return/exit code
# e.g. `false || log_debug_ok 'This keeps the last "$?", so the expression will fail after the log'`
# `log_abort` will force an unsuccessful exit code, keeping "$?" if it's nonzero.
# `log_exit` will do the same as `log_abort`, but will exit the program via `exit` instead of just `return`.
#
log_debug() { log --code="$?" --level=DEBUG "$@"; }
log_verbose() { log --code="$?" --level=VERBOSE "$@"; }
log_info() { log --code="$?" --level=INFO "$@"; }
log_req() { log --code="$?" --level=REQ "$@"; }
log_warn() { log --code="$?" --level=WARN "$@"; }
log_error() { log --code="$?" --level=ERROR "$@"; }
log_fatal() { log --code="$?" --level=FATAL "$@"; }
log_abort() { local code="$?"; if [ "${code}" -eq 0 ]; then code="${LOG_EXITCODE}"; fi; log --code="$code" --level=ABORT "$@"; }
log_die() { local code="$?"; if [ "${code}" -eq 0 ]; then code="${LOG_EXITCODE}"; fi; log --exit --code="$code" --level=ABORT "$@"; }

#
# Abbreviated log functions forcing 0 (success)
# e.g. `false || log_debug_ok 'This changes "$?" to 0, so the expression does not fail'`
#
log_debug_ok() { log --code="0" --level=DEBUG "$@"; }
log_verbose_ok() { log --code="0" --level=VERBOSE "$@"; }
log_info_ok() { log --code="0" --level=INFO "$@"; }
log_req_ok() { log --code="0" --level=REQ "$@"; }
log_warn_ok() { log --code="0" --level=WARN "$@"; }
log_error_ok() { log --code="0" --level=ERROR "$@"; }
log_fatal_ok() { log --code="0" --level=FATAL "$@"; }
