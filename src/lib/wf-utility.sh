#!/bin/bash

# This script provides a series of wf_* functions, used to record target commands into file.
# Different from popular script/asciinema/termRecord tools which aim to record the general
# terminal input/output, this tool only focuses on simple command recording, without any
# dependency except for a bash

# *********************************************************
# 2024-12-18    OPTIMIZE    | Functionalize more thoroughly
# 2024-03-26    REBUILD     | encapsulate all modes into functions
# 2024-03-25    UPDATE      | Optimize auto-mode, re-arrange the skeleton comments

#@ Prepare
#@ .functions


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "The script can only be sourced rather than executed"
    exit 0
fi

if [[ -n "$1" && "$1" == "unload" ]]; then
    if [[ "${wf_auto_on:-0}" == 1 ]]; then
        wf-auto
    fi
    unset wf_auto_on PS1_orig wf_split_flag
    unset -f get_wf_file wf-help wf-init wf wf-show wf-cancel wf-split wf-exec wf-pexec wf-say wf-rec _wf_autorec wf-auto
    return
fi


function get_wf_file() {
    #@ Intro
    #@ Last Update: @2024-12-17 13:11:18
    #@ ---------------------------------
    #@ Find target wf_file, according to given path or $PWD

    local wf_file tarDir

    #@ Prepare
    if [[ -n "$1" ]]; then
        tarDir="$1"
    else
        tarDir=$PWD
    fi

    #@ Main
    wf_file=
    while [[ $tarDir != "/" ]]; do
        if [[ -e $tarDir/workflow.md && $(test -w $tarDir/workflow.md && echo ok || echo fail) == ok ]]; then
            wf_file=$tarDir/workflow.md
            break
        elif [[ -e $tarDir/.workflow.md && $(test -w $tarDir/.workflow.md && echo ok || echo fail) == ok ]]; then
            wf_file=$tarDir/.workflow.md
            break
        else
            tarDir=$(dirname $tarDir)
            continue
        fi
    done

    #@ Post
    echo $wf_file
}

function wf-help() {
    #@ Intro
    #@ Last Update: @2024-12-17 17:42:09
    #@ ---------------------------------
    #@ Print help message
    echo -e '
    The \033[34mwf-*\033[0m series functions are used to record target commands into file.
    Unlike script, asciinema, or termRecord which aim to record general terminal
    input/output, these tools focus solely on command recording and requires no
    dependency except for a bash

    Usage: 
        Just source the script: wf-utility.sh, then type \033[32miwf\033[0m to load the functions below
        Type \033[32mqwf\033[0m to leave those functions

    Loaded functions:
        \033[38;5;228m● wf\033[0m
            Show the status under current directory
        \033[38;5;228m● wf-init [visible]\033[0m
            Create a new workflow.md in PWD if [visible] is not set to 0, or create .workflow.md 
        \033[38;5;228m● wf-help\033[0m
            Show thie help message
        \033[38;5;228m● wf-show [tool]\033[0m
            Show the content of target workflow.md via [arg], which is glow/cat by default
            You can use less, vim, .etc.
        \033[38;5;228m● wf-cancel\033[0m
            Remove the nearest record
        \033[38;5;228m● wf-split\033[0m
            Let the next record in a new section even the path remains the same
        \033[38;5;228m● wf-rec [co] [count]\033[0m
            Find the target command based on [co] from previous [count] command history
            Use the nearest command history if [co] not specified
            [count] is default to 20
        \033[38;5;228m● wf-exec <command>\033[0m
            Execute the [command] and record it
        \033[38;5;228m● wf-pexec <command>\033[0m
            Record the command only without execution
        \033[38;5;228m● (suspended) wf-filter\033[0m
            Filter the workflow.md based on .wfignore
        \033[38;5;228m● wf-say <...>\033[0m
            Just record the saying
        \033[38;5;228m● (alias=::) wf-auto\033[0m
            Toggle auto mode on/off
            If the auto mode of wf is turned on,
                - PROMPT should show hint
                - successful command ending with ";" will be recorded automatically
                - any command ending with ";:" will be recorded automatically
    ' | cut -c5-  #@ exp | use `cut -c5-` to omit the leading spaces
}


function wf-init(){
    #@ Intro
    #@ Last Update: @2024-12-17 17:46:27
    #@ ---------------------------------
    #@ param:$1     [visible] create .workflow.md if set to 0
    if [[ -e workflow.md || -e .workflow.md ]]; then
        echo -e '\033[33mWarning!\033[0m] The workflow file already exists'
    fi
    if [[ "$1" == 0 ]]; then
        touch .workflow.md
    else
        touch workflow.md
    fi
}


function wf(){
    #@ Intro
    #@ Last Update: @2024-12-17 13:22:10
    #@ ---------------------------------
    local wf_file

    wf_file=$(get_wf_file)
    if [[ -n "$wf_file" ]]; then
        echo "$wf_file"
        if [[ "${wf_auto_on:-0}" == 1 ]]; then
            echo -e "auto mode: \033[32mon\033[0m"
        else
            echo -e "auto mode: \033[31moff\033[0m"
        fi
    else
        echo -e "\033[31mError!\033[0m Cannot find valid workflow.md / .workflow.md"
    fi
    echo -e '\033[38;5;244m---------------------------------------------------------\033[0m'
    echo -e '\033[38;5;244mType \033[33;3mwf-help\033[38;5;244m to see detailed usage of wf series functions'
}

function wf-show() {
    #@ Intro
    #@ Last Update: @2024-12-17 16:38:40
    #@ ---------------------------------

    wf_file=$(get_wf_file)
    if [[ -z "$wf_file" ]]; then wf; return; fi

    if [[ -z "$1" ]]; then
        show_command=glow
    else
        show_command=$1
    fi

    echo -e "\033[38;5;244m$wf_file"
    echo -e '----------------------------------------\033[0m'

    if [[ $(which glow) == "" ]]; then
        echo -e "\033[33m Cannot find glow, use tail either \033[0m"
        show_command=cat
    fi

    eval $show_command $wf_file
}

function wf-cancel() {
    #@ Intro
    #@ Last Update: @2024-12-17 13:22:10
    #@ ---------------------------------

    wf_file=$(get_wf_file)
    if [[ -z "$wf_file" ]]; then wf; return; fi

    sed -i '$d' $wf_file                             #@ exp remove the last line
    if [[ ! $(sed -n '$p' $wf_file) =~ \+.* ]]; then #@ branch if the last line becomes location info, remove the last 2 lines
        head -n -2 $wf_file >.ade && mv -f .ade $wf_file
    fi
}

function wf-split() {
    wf_split_flag=1    
}

function wf-exec() {
    #@ Intro
    #@ Last Update: @2024-12-17 13:24:10
    #@ ---------------------------------
    wf-pexec "$*"
    ${*:1}
}

function wf-pexec() {
    #@ Intro
    #@ Last Update: @2024-12-17 13:25:03
    #@ ---------------------------------
    local wf_file wf_dir relpath last_relpath

    wf_file=$(get_wf_file)
    if [[ -z "$wf_file" ]]; then wf; return; fi
    wf_dir=$(dirname $wf_file)

    relpath=$(realpath --relative-to=$wf_dir $PWD)
    last_relpath=$(grep -Po '^At \*\*\K(.*)(?=\*\*)' $wf_file | tail -n 1)

    if [[ $last_relpath == $relpath && ${wf_split_flag:-0} == 0  ]]; then
        echo -e "+ \`$*\`" >>$wf_file
    else
        # nowDT=$(date '+%Y-%m-%d %H:%M:%S')
        wf_split_flag=0
        echo -e "***\nAt **${relpath}**\n+ \`$*\`" >>$wf_file
    fi
}

function wf-say() {
    #@ Intro
    #@ Last Update: @2024-12-17 13:25:03
    #@ ---------------------------------
    local wf_file wf_dir relpath last_relpath

    wf_file=$(get_wf_file)
    if [[ -z "$wf_file" ]]; then wf; return; fi
    wf_dir=$(dirname $wf_file)

    relpath=$(realpath --relative-to=$wf_dir $PWD)
    last_relpath=$(grep -Po '^At \*\*\K(.*)(?=\*\*)' $wf_file | tail -n 1)

    if [[ $last_relpath == $relpath && ${wf_split_flag:-0} == 0  ]]; then
        echo -e "+ $*" >>$wf_file
    else
        # nowDT=$(date '+%Y-%m-%d %H:%M:%S')
        wf_split_flag=0
        echo -e "***\nAt **${relpath}**\n+ $*" >>$wf_file
    fi
}

function wf-rec() {
    #@ Intro
    #@ Last Update: @2024-12-18 11:57:20
    #@ ---------------------------------
    #@ Record target command from history

    local wf_file wf_dir relpath last_relpath nlines nlines_plus targetCommand

    wf_file=$(get_wf_file)
    if [[ -z "$wf_file" ]]; then wf; return; fi
    wf_dir=$(dirname $wf_file)

    relpath=$(realpath --relative-to=$wf_dir $PWD)
    last_relpath=$(grep -Po '^At \*\*\K(.*)(?=\*\*)' $wf_file | tail -n 1)

    nlines=20
    if [[ -n "$2" ]]; then
        nlines=$2
        if [[ ! "$nlines" -eq "$nlines" ]]; then
            echo -e "\033[31m Error!\033[0m wf-rec's 2nd argument must be integer"
            return
        fi
    fi
    ((nlines_plus = nlines + 1))

    if [[ -z "$1" ]]; then
        targetCommand=$(history 2 | head -n 1 | awk '{$1=""; sub(/^[ \t]+/, ""); print}')
    else
        targetCommand=
        if [[ -n $1 ]]; then
            history $nlines_plus | head -n $nlines | tac | awk '{$1=""; sub(/^[ \t]+/, ""); print}' >.temp.wf
            while read -r line; do
                echo "$line vs $1"
                if [[ "$line" =~ ^"$1" ]]; then
                    targetCommand=$line
                    break
                fi
            done <.temp.wf
            # done <<<$(history $nlines_plus | head -n $nlines | tac | awk '{$1=""; sub(/^[ \t]+/, ""); print}')
            rm -f .temp.wf
        fi
        if [[ -z "$targetCommand" ]]; then
            echo -e "\033[31m Cannot find target command in last $nlines commands"
            return
        fi
    fi

    echo "targetCommand=$targetCommand"

    wf-pexec $targetCommand

    # if [[ $last_relpath == $relpath ]]; then
    #     echo -e "+ $targetCommand" >>$wf_file
    # else
    #     nowDT=$(date '+%Y-%m-%d %H:%M:%S')
    #     echo -e "***\nAt **${relpath}** *@${nowDT}*\n+ ${targetCommand}" >>$wf_file
    # fi
}

# wf_srcdir=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
# function wf-filter() {
#     ig_file=$wf_dir/.wfignore
#     if [[ $filter_mode == 1 && -e $ig_file ]]; then
#         $wf_srcdir/../libexec/filterWF $wf_file $ig_file
#     fi
# }

function _wf_autorec() {
    #@ Intro
    #@ Last Update: @2024-12-17
    #@ ---------------------------------
    #@ Executor for recording automatically, according to the ending characters
    
    
    #@ Prepare
    #@ .resolve-last-command

    local rcode=$?  #@ note | Must be put at the first line of this function

    local last_command wf_file wf_dir relpath last_relpath failed
    
    last_command=$(history 1 | awk '{$1=""; sub(/^[ \t]+/, ""); print}')

    #@ Main
    #@ .exclude-condition handle include/exclude separately
    if [[ "$last_command" =~ .*";"$ ]]; then
        if [[ $rcode != 0 ]]; then
            return
        fi
        last_command=${last_command:0:-1}
    elif [[ "$last_command" =~ .*";:"$ ]]; then
        last_command=${last_command:0:-2}
    else
        return
    fi

    
    wf_file=$(get_wf_file)
    if [[ -z "$wf_file" ]]; then wf; return; fi
    wf_dir=$(dirname $wf_file)

    #@ .resolve-path
    local relpath=$(realpath --relative-to=$wf_dir .)
    # echo -e "\033[35m tarDir=$tarDir, relpath=$relpath"
    last_relpath=$(grep -Po '^At \*\*\K(.*)(?=\*\*)' $wf_file | tail -n 1)

    #@ .action
    if [[ $last_relpath == $relpath && ${wf_split_flag:-0} == 0 ]]; then
        echo -e "+ \`${last_command}\`" >>$wf_file
    else
        # local nowDT=$(date '+%Y-%m-%d %H:%M:%S')
        wf_split_flag=0
        echo -e "***\nAt **${relpath}**\n+ \`${last_command}\`" >>$wf_file
    fi

    # Post
    echo -e "\033[33mcommand recorded in $wf_file \033[0m"
}

function wf-auto() {
    #@ Intro
    #@ Last Update: @2024-12-18 11:53:28
    #@ ---------------------------------
    #@ Toggle auto-mode on/off
    #@ It will modify bash prompt if auto-mode is turned on
    if [[ "${wf_auto_on:-0}" == 0 ]]; then
        #@ exp | turn off auto mode
        echo -e "Turning \033[32mon\033[0m auto-mode"
        export PROMPT_COMMAND=_wf_autorec
        wf_auto_on=1
        PS1_orig="$PS1"
        PS1="\[\033[38;5;208m\][wf-auto]\[\033[0m\] ${PS1_orig}"
    else
        #@ exp | turn on auto mode
        echo -e "Turning \033[31moff\033[0m auto-mode"
        wf_auto_on=0
        export PROMPT_COMMAND=
        PS1="$PS1_orig"
    fi
}

alias -- '::'=wf-auto