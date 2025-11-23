#!/bin/bash
set -e

cd "/var/lib/vz/template/iso" #Path for ISO on proxmox

echo "[*] Récupération de la liste des versions Talos..."

# Récupère toutes les versions publiées de Talos depuis GitHub
VERSIONS=$(curl -s https://api.github.com/repos/siderolabs/talos/releases \
    | grep tag_name | cut -d '"' -f 4)

VMID=$START_ID

for VERSION in $VERSIONS; do
    echo ""
    echo "====================================================="
    echo "[*] Traitement de Talos version: $VERSION"
    echo "====================================================="

    # URLs officielles QCOW2
    ISO_URL="https://github.com/siderolabs/talos/releases/download/${VERSION}/metal-amd64.iso"

    wget -O "talos-amd64-${VERSION}.iso" $ISO_URL
don