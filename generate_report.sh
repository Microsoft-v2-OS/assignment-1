#!/usr/bin/env bash
# ==========================================================================
# generate_report.sh
# File ini berisi FUNGSI yang bertugas menggabungkan seluruh hasil
# pengecekan (dari sysinfo.sh dan resource_check.c) menjadi satu tabel rapi, lalu menyimpannya ke
# sysinfo_report.txt.
#
# CARA PAKAI:
#   1. Taruh file ini satu folder dengan sysinfo.sh
#   3. Panggil generate_report_table dengan format:
#         generate_report_table "<GROUP_LABEL>" "${rows[@]}"
#      dimana setiap elemen rows berformat:
#         "Check Category|Item|STATUS|Details"
#
#      Contoh (disesuaikan dengan hasil nyata dari sysinfo.sh & resource_check.c):
#         rows=(
#           "OS|Ubuntu 24.04 LTS|PASS|Kernel 6.8.0"
#           "Users|Regular accounts|PASS|1 akun"
#           "Processes|Running|PASS|134 proses berjalan"
#           "Virtualization|Hypervisor|PASS|Terdeteksi: VirtualBox"
#           "Disk|${DISK_PCT}%|${DISK_STATUS}|Ambang FAIL>=90%% WARN>=75%%"
#           "Proses Berjalan|${PROC_COUNT}|${PROC_STATUS}|Ambang FAIL>=400 WARN>=200"
#         )
#         generate_report_table "AXX" "${rows[@]}"
#
#   Fungsi ini TIDAK menghitung status PASS/WARN/FAIL sendiri -- itu tugas
#   resource_check.c dan pengambilan metrik dasar.
#   Fungsi ini murni memformat data yang sudah jadi menjadi tabel + header
#   + menyimpannya ke file laporan.
# ==========================================================================

generate_report_table() {
    local group_label="${1:-AXX}"
    shift
    local report_file="sysinfo_report.txt"

    local -a categories=() items=() statuses=() details=()

    # --- Parsing setiap baris input "Category|Item|Status|Details" ---
    for row in "$@"; do
        IFS='|' read -r cat item stat det <<< "$row"
        categories+=("$cat")
        items+=("$item")
        statuses+=("$stat")
        details+=("$det")
    done

    local h1="Check Category" h2="Item" h3="Status" h4="Details"

    # --- Hitung lebar kolom otomatis (menyesuaikan isi terpanjang) ---
    local w1=${#h1} w2=${#h2} w3=${#h3} w4=${#h4}
    local i
    for i in "${!categories[@]}"; do
        (( ${#categories[$i]} > w1 )) && w1=${#categories[$i]}
        (( ${#items[$i]}      > w2 )) && w2=${#items[$i]}
        (( ${#statuses[$i]}   > w3 )) && w3=${#statuses[$i]}
        (( ${#details[$i]}    > w4 )) && w4=${#details[$i]}
    done

    local border
    border="+$(printf '%*s' $((w1+2)) '' | tr ' ' '-')"
    border+="+$(printf '%*s' $((w2+2)) '' | tr ' ' '-')"
    border+="+$(printf '%*s' $((w3+2)) '' | tr ' ' '-')"
    border+="+$(printf '%*s' $((w4+2)) '' | tr ' ' '-')+"

    local total_width=${#border}
    local title="TUGAS 1 OS - KELOMPOK ${group_label}"
    local pad=$(( (total_width - ${#title}) / 2 ))
    (( pad < 0 )) && pad=0

    {
        printf '%*s\n' "$total_width" '' | tr ' ' '='
        printf '%*s%s\n' "$pad" '' "$title"
        printf '%*s\n' "$total_width" '' | tr ' ' '='
        echo "$border"
        printf "| %-*s | %-*s | %-*s | %-*s |\n" "$w1" "$h1" "$w2" "$h2" "$w3" "$h3" "$w4" "$h4"
        echo "$border"
        for i in "${!categories[@]}"; do
            printf "| %-*s | %-*s | %-*s | %-*s |\n" \
                "$w1" "${categories[$i]}" "$w2" "${items[$i]}" \
                "$w3" "${statuses[$i]}"   "$w4" "${details[$i]}"
        done
        echo "$border"
    } > "$report_file"

    echo "Laporan berhasil disimpan ke $report_file"
}
