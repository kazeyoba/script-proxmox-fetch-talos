for VMID in $(qm list | awk 'NR>1 {print $1}' | sort -n); do
    if [ "$VMID" -ge 2000 ]; then
        echo "[*] Suppression de la VM/Template $VMID..."
        qm destroy $VMID --purge
    fi
done
