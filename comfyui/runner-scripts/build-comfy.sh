#!/bin/bash

set -e

# Run user's set-proxy script
cd /comfyui
if [ ! -f "/comfyui/user-scripts/set-proxy.sh" ] ; then
    mkdir -p /comfyui/user-scripts
    cp /runner-scripts/set-proxy.sh.example /comfyui/user-scripts/set-proxy.sh
else
    echo "[INFO] Running set-proxy script..."

    chmod +x /comfyui/user-scripts/set-proxy.sh
    source /comfyui/user-scripts/set-proxy.sh
fi ;

# Install ComfyUI
cd /comfyui
if [ ! -f "/comfyui/.download-complete" ] ; then
    chmod +x /runner-scripts/download.sh
    bash /runner-scripts/download.sh
fi ;

# Run user's pre-start script
cd /comfyui
if [ ! -f "/comfyui/user-scripts/pre-start.sh" ] ; then
    mkdir -p /comfyui/user-scripts
    cp /runner-scripts/pre-start.sh.example /comfyui/user-scripts/pre-start.sh
else
    echo "[INFO] Running pre-start script..."

    chmod +x /comfyui/user-scripts/pre-start.sh
    source /comfyui/user-scripts/pre-start.sh
fi ;


echo "########################################"
echo "[INFO] Starting ComfyUI..."
echo "########################################"

# Let .pyc files be stored in one place
export PYTHONPYCACHEPREFIX="/comfyui/.cache/pycache"
# Let PIP install packages to /comfyui/.local
export PIP_USER=true
# Add above to PATH
export PATH="${PATH}:/comfyui/.local/bin"
# Suppress [WARNING: Running pip as the 'root' user]
export PIP_ROOT_USER_ACTION=ignore


