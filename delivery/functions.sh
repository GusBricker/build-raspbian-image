#!/bin/bash

function AptUpdate()
{
    apt-get update $@
}

function AptInstall()
{
    apt-get install -y --force-yes $@
}

