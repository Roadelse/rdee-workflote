#!/bin/bash

#@ Intro
#@ Last Update: @2024-12-18 17:51:49
#@ ---------------------------------
#@ This script aims to test basic functionality of wf utilities
#@ Note: wf-rec and wf-auto are partially test due to limitation
#@ of history command in script 

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo -e "\033[33mUsage\033[0m: \033[32msource\033[0m utest.sh"
    exit 0
fi

__filedir__=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))

trap 'errflag=1' ERR
errflag=0

function report_errflag(){
    if [[ $errflag -eq 0 ]]; then
        if [[ "$1" != mid ]]; then
            echo -e '\033[32m √ \033[0m'
        fi
        return 0
    else
        echo -e '\033[31m x \033[0m'
        return 1
    fi
}

echo -n '- Source wf-utility.sh '
source ${__filedir__}/../src/lib/wf-utility.sh >& /dev/null
report_errflag || return


cd $__filedir__

mkdir -p utest.wks && cd utest.wks
rm -f workflow.md .workflow.md


echo -n '- Testing wf-init '
wf-init 0
[[ -e .workflow.md ]] && rm .workflow.md
wf-init 1
[[ -e workflow.md ]] && rm workflow.md
report_errflag || return


echo -n '- Testing wf'
wf_path=$(wf | head -n 1)
[[ "$wf_path" =~ Error ]]
report_errflag mid || return
wf-init 1
wf_path=$(wf | head -n 1)
[[ "$wf_path" == $__filedir__/utest.wks/workflow.md ]]
report_errflag || return

echo -n '- Testing wf-exec '
wf-exec ls >& /dev/null
lastline=$(tail -n 1 workflow.md)
[[ "$lastline" == '+ `ls`' ]]
report_errflag || return

echo -n '- Testing wf-pexec '
wf-pexec ababa
lastline=$(tail -n 1 workflow.md)
[[ "$lastline" == '+ `ababa`' ]]
report_errflag || return

echo -n '- Testing wf-split & wf-say '
wf-split
wf-say do something
s2lastline=$(tail -n 2 workflow.md  | head -n 1)
lastline=$(tail -n 1 workflow.md)
[[ "$lastline" == '+ do something' ]]
[[ "$s2lastline" =~ ^At ]]
report_errflag || return

echo -n '- Testing wf-rec (pseudo)  '
wfsize1=$(stat -c %s workflow.md)
wf-rec >& /dev/null
wfsize2=$(stat -c %s workflow.md)
[[ $wfsize1 != $wfsize2 ]]
report_errflag || return

echo -n '- Testing wf-auto (pseudo)  '
wf-auto >& /dev/null
[[ "$PS1" =~ '[wf-auto]' ]]
# wfsize1=$(stat -c %s workflow.md)
# ls >& /dev/null
# wfsize2=$(stat -c %s workflow.md)
# [[ $wfsize1 == $wfsize2 ]]
# ls >& /dev/null;
# wfsize2=$(stat -c %s workflow.md)
# [[ $wfsize1 != $wfsize2 ]]
wf-auto >& /dev/null
report_errflag || return


cd $__filedir__
rm -rf utest.wks
trap - ERR