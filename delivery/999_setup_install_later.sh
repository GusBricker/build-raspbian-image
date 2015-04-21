#!/bin/bash

BannerEcho "Install Later: Setting up"

STARTUP_INJECTION_PATH="/etc/rc.local"
STARTUP_INJECTION_BACKUP_PATH="/etc/rc.local.backup"

mv "${STARTUP_INJECTION_PATH}" "${STARTUP_INJECTION_BACKUP_PATH}"

tac "${STARTUP_INJECTION_BACKUP_PATH}" | sed "1 s|exit 0$|${INSTALL_LATER_PATH}|" | tac | tee "${STARTUP_INJECTION_PATH}"
cat "${STARTUP_INJECTION_PATH}"

chmod +x "${STARTUP_INJECTION_PATH}"
chmod +x "${INSTALL_LATER_PATH}"

rm "${STARTUP_INJECTION_BACKUP_PATH}"

BannerEcho "Install Later: Done"
