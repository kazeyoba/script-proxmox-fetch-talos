#!/bin/bash
set -e

START_ID=2000

cd "/var/lib/vz/template/iso"

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

    ISO_FILE="talos-amd64-${VERSION}.iso"
    ISO_URL="https://github.com/siderolabs/talos/releases/download/${VERSION}/metal-amd64.iso"

    if [ -f "$ISO_FILE" ]; then
        echo "[*] ISO déjà existante: $ISO_FILE, téléchargement ignoré."
    else
        echo "[*] Téléchargement de l'ISO: $ISO_FILE"
        wget -O "$ISO_FILE" "$ISO_URL"
    fi
done
