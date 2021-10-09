#!/bin/bash
#
# ========
# print3d
# ========
#
# Eric O Meehan
# 2021-10-09
#
# Controlls the sending of gcode to a Marlin controller over a usb serial port.
#

function help()
{
    echo "usage: print3d [] []"
}

function self_promotion()
{
    echo "========"
    echo "print3d"
    echo "========"
    echo "Created by Eric O Meehan"
    echo $"\n"
}

function setup()
{
    export DATA=$1
    export DEVICE=$2
    export PIPE=/tmp/print3d

    echo "[INFO] - $(date +%Y-%m-%d_%H:%M:%S) - Preparing to print $DATA"
    mkfifo $PIPE
    cat $DEVICE > $PIPE &
    export pid=$!
}

function main()
{
    while read gcode
    do
        command_prefix="${gcode:0:1}"
        if [[ $command_prefix == "G" || $command_prefix == "M" ]]
        then
            echo "[INFO] - $(date +%Y-%m-%d_%H:%M:%S) - write - $gcode"
            echo "$gcode" > $DEVICE
            timeout=true
            while read -t 10 response
            do
                echo "[INFO] - $(date +%Y-%m-%d_%H:%M:%S) - read - $response"
                if [[ ${response:0:2} == "ok" ]]
                then
                    timeout=false
                    break
                fi
            done < $PIPE
            if $timeout
            then
                echo "[WARNING] - $(date +%Y-%m-%d_%H:%M:%S) - timeout - $gcode"
            fi
        else
            echo "[INFO] - $(date +%Y-%m-%d_%H:%M:%S) - skip - $gcode"
        fi
    done < $DATA
}

function teardown()
{
    kill $pid
    rm $PIPE
}

case $# in
    2)
        self_promotion
        setup $@
        main $@
        teardown
        ;;
    *)
        help
        ;;
esac
