#!/bin/bash

echo "------------------------------------------------------------------"
echo "Users: Setting Up"
echo "------------------------------------------------------------------"
NEW_USER="pi"
NEW_USER_PASSWORD="raspberry"
adduser --disabled-password --gecos "" "${NEW_USER}"
echo "${NEW_USER}:${NEW_USER_PASSWORD}" | chpasswd
chsh -s /bin/bash "${NEW_USER}"

AptInstall sudo
adduser "${NEW_USER}" sudo

echo "------------------------------------------------------------------"
echo "Users: Done"
echo "------------------------------------------------------------------"
