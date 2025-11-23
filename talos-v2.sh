#!/bin/bash
set -e

### ============================
### CONFIGURATION UTILISATEUR
### ============================

START_ID=2000                  # VMID initial
STORAGE="local"                # Nom du storage Proxmox
NET_BRIDGE="vmbr2"             # Bridge réseau
VLAN_TAG=20                     # VLAN tag pour l'interface
ISO_DIR="/var/lib/vz/template/qcow2"  # Répertoire pour les QCOW2

# Clé publique SSH à injecter dans Cloud-init
SSH_KEY="ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAFRDXoGwAz0HK1rQZrXqsJbDc/QXahlZrLA2B8dZxFoY0aA4/e1reHpQQBG9pGFb2WzHPv3df4Je5f8pheH60vcOgAWK/TFoItv4WO76vHJ7SuI1zffd9fYx9/GBtzQVp/U+faFNcDup982U/z+yshW2qx+8RKCh+da8EA5kUuH5wU5oQ== timaiselmi@gmail.com"

# Schematic vanilla officiel (pas d'extensions)
SCHEMATIC_ID="376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"

mkdir -p "$ISO_DIR"

echo "[*] Récupération des versions Talos disponibles..."
VERSIONS=$(curl -s https://factory.talos.dev/versions | jq -r '.[]')

VMID=$START_ID

for VERSION in $VERSIONS; do
    echo ""
    echo "====================================================="
    echo "[*] Traitement Talos $VERSION"
    echo "====================================================="

    RAW_URL="https://factory.talos.dev/image/${SCHEMATIC_ID}/${VERSION}/metal-amd64.raw.zst"
    RAW_FILE="${ISO_DIR}/talos-${VERSION}.raw.zst"
    RAW_DECOMPRESSED="${ISO_DIR}/talos-${VERSION}.raw"
    QCOW_FILE="${ISO_DIR}/talos-${VERSION}.qcow2"

    echo "[*] Téléchargement RAW... $RAW_URL"
    curl -L -o "$RAW_FILE" "$RAW_URL"

    echo "[*] Décompression ZSTD..."
    unzstd -f "$RAW_FILE" -o "$RAW_DECOMPRESSED"

    echo "[*] Conversion RAW → QCOW2..."
    qemu-img convert -f raw -O qcow2 "$RAW_DECOMPRESSED" "$QCOW_FILE"

    echo "[*] Création VM ID $VMID..."
    qm create $VMID \
        --name "talos-${VERSION}" \
        --memory 2048 \
        --cores 2 \
        --ostype l26 \
        --scsihw virtio-scsi-pci \
        --net0 "virtio,bridge=${NET_BRIDGE},tag=${VLAN_TAG}" \
        --sshkey <(echo "$SSH_KEY") \
        --ipconfig0 "ip=dhcp" \
        --ciuser root


    echo "[*] Importation du disque QCOW2..."
    qm importdisk $VMID "$QCOW_FILE" "$STORAGE" --format qcow2

    qm set $VMID --scsi0 "${STORAGE}:${VMID}/vm-${VMID}-disk-0.qcow2"
    qm set $VMID --scsi1 "${STORAGE}:30"
    qm set $VMID --ide0 "$STORAGE:cloudinit"
    qm set $VMID --boot order=scsi0

    echo "[*] Conversion de la VM en template..."
    qm template $VMID

    echo "[+] Template Talos $VERSION (VMID $VMID) créée avec succès."

    VMID=$((VMID + 1))
done

echo ""
echo "====================================================="
echo "[✔] Toutes les VMs Talos ont été créées et converties en templates."
echo "====================================================="