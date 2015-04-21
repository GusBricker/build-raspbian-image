#!/bin/bash

BannerEcho "SSH: Setting Up"

update-rc.d ssh enable &&
invoke-rc.d ssh start

BannerEcho "SSH: Done"
