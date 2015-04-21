#!/bin/bash

function BannerEcho()
{
    echo "------------------------------------------------------------------"
    for arg in "$@"
    do
        echo "    $arg"
    done
    echo "------------------------------------------------------------------"
}

function AptUpdate()
{
    apt-get update $@
}

function AptInstall()
{
    apt-get install -y --force-yes $@
}

function GetFile()
{
	local base_url=$1
	local filename=$2

	wget -N "${base_url}/${filename}"
}

function DirectoryOrderedExecute()
{
    local directory=$1
    local cfg
    local cfgs
    local cfgn

    cfgs=`ls -1 "${directory}"/[0-9]*`
    for cfg in $cfgs; do
        cd ${directory}
        cfgn=`basename ${cfg}`
        echo "Applying ${cfgn}..."
        source ${cfg}
    done
}
