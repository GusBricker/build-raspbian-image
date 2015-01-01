#!/bin/bash

function MonitorDD()
{
    local pid=$1
    sleep 1

    while true
    do
        kill -USR1 ${pid}
        if [ $? -ne 0 ]
        then
            break
        fi
        sleep 5
    done
}

input=$1
output=$2

if [ $# -ne 2 ]
then
    echo "Require 2 arguments"
    echo "Arg 1 = input file"
    echo "Arg 2 = output file"
    exit 1
fi

if [[ "x${output}" = "x/" ]]
then
    echo "Output cant be root, this will kill your OS"
    exit 1
fi

echo "==== Writing"
dd if="${input}" of="${output}" bs=1M conv=fsync &
dd_pid=$!

MonitorDD "${dd_pid}"

echo "==== Final sync's"
sync
sync
