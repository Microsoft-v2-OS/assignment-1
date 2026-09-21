#!/bin/bash

# ==============================================================================
# TUGAS 1 SISTEM OPERASI - SYSINFO (SYSTEM CHECKS)
# Kelompok B04, Varian C
# Dijalankan DI DALAM VM Ubuntu 24.04
# ==============================================================================

set -uo pipefail

if [ -f "./generate_report.sh" ]; then
	source ./generate_report.sh
else
	echo "berkas generate_report.sh tidak ditemukan "
	exit 1
fi

KELOMPOK="B04"
BINER_C="./resource_check"
SUMBER_C="resource_check.c"
FILE_LAPORAN="sysinfo_report.txt"

# ------------------------------------------------------------------------------
# Pastikan program C sudah dikompilasi
# ------------------------------------------------------------------------------
if [ ! -x "$BINER_C" ]; then
    if [ -f "$SUMBER_C" ]; then
        echo "Mengompilasi $SUMBER_C ..."
        gcc -Wall -Wextra -std=c11 -o "$BINER_C" "$SUMBER_C" || exit 1
    else
        echo "Berkas $SUMBER_C tidak ditemukan."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# 1. OS & Kernel Check
# Dijalankan di subshell supaya variabel dari os-release tidak mencemari skrip
# ------------------------------------------------------------------------------
OS_NAME=$( . /etc/os-release && echo "$PRETTY_NAME" )
KERNEL_INFO=$(uname -r)
OS_KERNEL_STR="${OS_NAME} (Kernel ${KERNEL_INFO})"

# ------------------------------------------------------------------------------
# 2. Regular User Count Check
# UID 1000 sampai 59999 adalah wilayah akun manusia pada Debian/Ubuntu.
# Akun dengan shell nologin atau false dibuang karena tidak bisa dipakai login.
# count+0 mencegah keluaran kosong kalau tidak ada yang cocok.
# ------------------------------------------------------------------------------
USER_COUNT=$(awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/ {count++} END {print count+0}' /etc/passwd)

# ------------------------------------------------------------------------------
# 3. Running Processes Count
# Dipakai dua kali, sebagai pengecekan wajib dan sebagai Metrik 2 Varian C.
# Diambil sekali saja supaya angka di terminal dan di laporan konsisten.
# ------------------------------------------------------------------------------
PROC_COUNT=$(ps -e --no-headers | wc -l)

# ------------------------------------------------------------------------------
# 4. Virtualization Detection
# ------------------------------------------------------------------------------
VIRT_RAW=$(systemd-detect-virt)
if [ "$VIRT_RAW" = "oracle" ]; then
    VIRT_STATUS="Terdeteksi (VirtualBox)"
    VIRT_FLAG="PASS"
elif [ "$VIRT_RAW" = "none" ]; then
    VIRT_STATUS="Tidak Terdeteksi (Likely Bare Metal)"
    VIRT_FLAG="FAIL"
else
    VIRT_STATUS="Terdeteksi ($VIRT_RAW)"
    VIRT_FLAG="PASS"
fi

# ------------------------------------------------------------------------------
# 5. Metrik Varian C
#    Metrik 1 = Disk usage partisi root, persen
#    Metrik 2 = Jumlah proses berjalan (PROC_COUNT di atas)
#    Opsi -P memaksa format POSIX satu baris per filesystem supaya kolom
#    persentase tidak bergeser ketika nama device panjang.
# ------------------------------------------------------------------------------
DISK_USAGE=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')

# ------------------------------------------------------------------------------
# 6. Kirim kedua metrik ke program C lewat PIPE ke stdin
#    Bukan sebagai argumen command line, sesuai ketentuan soal.
#    Seluruh logika ambang batas ada di dalam program C.
# ------------------------------------------------------------------------------
HASIL_C=$(printf '%s\n%s\n' "$DISK_USAGE" "$PROC_COUNT" | "$BINER_C")
EXIT_C=$?

# Tangkap hasil balik dari program C, satu baris per metrik
BARIS_DISK=$(echo "$HASIL_C" | sed -n '1p')
BARIS_PROSES=$(echo "$HASIL_C" | sed -n '2p')

IFS='|' read -r D_NAMA D_NILAI D_STATUS D_KET <<< "$BARIS_DISK"
IFS='|' read -r P_NAMA P_NILAI P_STATUS P_KET <<< "$BARIS_PROSES"

# ------------------------------------------------------------------------------
# 7. Fitur Tambahan: VM Uptime
#    Dihitung dari /proc/uptime supaya tidak bergantung pada format teks
#    uptime -p yang berubah ubah (days, weeks, ada koma atau tidak).
# ------------------------------------------------------------------------------
UP_DETIK=$(awk '{print int($1)}' /proc/uptime)
UP_HARI=$(( UP_DETIK / 86400 ))
UP_JAM=$(( (UP_DETIK % 86400) / 3600 ))
UP_MENIT=$(( (UP_DETIK % 3600) / 60 ))
UPTIME_STR="${UP_HARI} hari ${UP_JAM} jam ${UP_MENIT} menit"

# ------------------------------------------------------------------------------
# Terminal Output Display
# ------------------------------------------------------------------------------
echo "==================================="
echo "TUGAS 1 OS - KELOMPOK ${KELOMPOK}"
echo "==================================="
echo "Mengecek sistem..."
printf "%-17s : %s\n" "OS/Kernel" "$OS_KERNEL_STR"
printf "%-17s : %s akun\n" "Akun pengguna" "$USER_COUNT"
printf "%-17s : %s proses\n" "Proses berjalan" "$PROC_COUNT"
printf "%-17s : %s\n" "Virtualisasi" "$VIRT_STATUS"

echo ""
echo "Menghitung metrik varian C..."
printf "%-17s : %-12s [ %s ]\n" "Disk usage" "$D_NILAI" "$D_STATUS"
printf "%-17s : %-12s [ %s ]\n" "Proses berjalan" "$P_NILAI" "$P_STATUS"

# Definisikan array terlebih dahulu
rows=(
	"OS|${OS_NAME}|PASS|Kernel ${KERNEL_INFO}"
	"Users|Regular accounts|PASS|${USER_COUNT} akun"
	"Processes|Running|PASS|${PROC_COUNT} proses berjalan"
	"Virtualization|Hypervisor|${VIRT_FLAG}|${VIRT_STATUS}"
	"Disk|${D_NILAI}|${D_STATUS}|${D_KET}"
	"Proses|${P_NILAI}|${P_STATUS}|${P_KET}"
	"Uptime|VM aktif|INFO|${UPTIME_STR}"
)

# Cetak seluruh isi array ke terminal
printf '%s\n' "${rows[@]}"

echo "Fitur tambahan:"
printf "%-17s : %s\n" "Uptime VM" "$UPTIME_STR"

# ------------------------------------------------------------------------------
# 8. Simpan seluruh hasil ke sysinfo_report.txt dalam bentuk tabel
# ------------------------------------------------------------------------------
echo "menyimpan laporan"
generate_report_table "${KELOMPOK}" "${rows[@]}"
echo "Laporan berhasil disimpan."
