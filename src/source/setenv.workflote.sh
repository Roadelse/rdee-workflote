#!/bin/bash


#@ Introduction
# The script implements serverl wrapper bash functions for calling wurial.py
#@


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "The script can only be sourced rather than executed"
    exit 0
fi

if [[ -n "$1" && "$1" == "unload" ]]; then
    unset -f iwf qwf
    unset __wflib__
    return
fi


__wflib__=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/../lib

function iwf(){
    source $__wflib__/wf-utility.sh
}

function qwf(){
    source $__wflib__/wf-utility.sh unload
}
