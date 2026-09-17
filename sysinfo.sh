#!/bin/bash

# ==============================================================================
# TUGAS 1 SISTEM OPERASI - SYSINFO (SYSTEM CHECKS)
# ==============================================================================

# 1. OS & Kernel Check
source /etc/os-release
KERNEL_INFO=$(uname -r)
OS_KERNEL_STR="${PRETTY_NAME} (Kernel ${KERNEL_INFO})"

# 2. Regular User Count Check
USER_COUNT=$(awk -F: '$3 >= 1000 && $3 < 65534 {count++} END {print count}' /etc/passwd)

# 3. Running Processes Count (Used for Variant C Metric 2)
PROC_COUNT=$(ps -e --no-headers | wc -l)

# 4. Virtualization Detection
VIRT_RAW=$(systemd-detect-virt)
if [ "$VIRT_RAW" = "oracle" ]; then
    VIRT_STATUS="Terdeteksi (VirtualBox)"
elif [ "$VIRT_RAW" = "none" ]; then
    VIRT_STATUS="Tidak Terdeteksi (Likely Bare Metal)"
else
    VIRT_STATUS="Terdeteksi ($VIRT_RAW)"
fi

# 5. Fitur Tambahan: VM Uptime
UPTIME_STR=$(uptime -p | sed -e 's/up //' -e 's/ days\?,/ hari/' -e 's/ hours\?,/ jam/' -e 's/ minutes\?/ menit/')

# ------------------------------------------------------------------------------
# Terminal Output Display
# ------------------------------------------------------------------------------
echo "==================================="
echo "     TUGAS 1 OS KELOMPOK B04      "
echo "==================================="
echo "Mengecek sistem..."
printf "%-17s : %s\n" "OS/Kernel" "$OS_KERNEL_STR"
printf "%-17s : %s akun\n" "Akun pengguna" "$USER_COUNT"
printf "%-17s : %s proses\n" "Proses berjalan" "$PROC_COUNT"
printf "%-17s : %s\n" "Virtualisasi" "$VIRT_STATUS"

echo ""
echo "Fitur tambahan:"
printf "%-17s : %s\n" "Uptime VM" "$UPTIME_STR"
