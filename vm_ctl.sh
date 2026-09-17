#!/bin/bash
# vm_ctl.sh, ini script kontrol VM dari sisi HOST (dijalankan di luar VM)
# Tugas 1 Sistem Operasi oleh Kelompok B04


KELOMPOK="B04"

# fungsi buat nampilin header standard supaya semua perintah formatnya sama
print_header() {
    echo "==================================="
    echo "TUGAS 1 OS - KELOMPOK $KELOMPOK"
    echo "==================================="
}

# untuk validasi jika nama vm tidak diisi maka script akan berhenti
# dan kasi tahu cara pakai yang benar, ini dilakukan supaya mencegah ia lanjut
# dan malah error dari VBoxManage
require_vm() {
    if [ -z "$1" ]; then
        print_header
        echo "Error: nama VM belum diisi."
        echo "Usage: $0 <aksi> <nama_vm> [argumen_tambahan]"
        exit 1
    fi
}

# fungsi untuk membantu mengambil status VM saat ini (running/poweroff/dst),
get_status() {
    VBoxManage showvminfo "$1" --machinereadable | grep "^VMState=" | cut -d= -f2 | tr -d '"'
}

# Menampilkan daftar seluruh VM yang terdaftar
vm_list() {
    print_header
    echo "Memindai daftar Virtual Machine..."
    echo ""
    echo "Daftar VM terdaftar:"
    local i=1
    while IFS= read -r line; do
        local name=$(echo "$line" | sed -E 's/^"([^"]+)".*/\1/')
        echo "  $i. $name"
        i=$((i+1))
    done < <(VBoxManage list vms)
}

# menampilkan RAM, vCPU, dan status VM
vm_info() {
    require_vm "$1"
    print_header
    local vm="$1"
    # showvminfo --machincereadable ngasi output key = value,
    # jadi tinggal difilter baris yang dibutuhkan pakai grep + cut
    local ram=$(VBoxManage showvminfo "$vm" --machinereadable | grep "^memory=" | cut -d= -f2)
    local cpu=$(VBoxManage showvminfo "$vm" --machinereadable | grep "^cpus=" | cut -d= -f2)
    local status=$(get_status "$vm")
    echo ""
    printf "  VM                : %s\n" "$vm"
    printf "  RAM dialokasikan  : %s MB\n" "$ram"
    printf "  vCPU dialokasikan : %s\n" "$cpu"
    printf "  Status saat ini   : %s\n" "$status"
}

# menyalakan VM headless, lalu konfirmasi statusnya
vm_start() {
    require_vm "$1"
    print_header
    local vm="$1"
    echo "Menyalakan VM '$vm' secara headless..."
    VBoxManage startvm "$vm" --type headless > /dev/null 2>&1
    sleep 3
    local status=$(get_status "$vm")
    echo "VM '$vm' berhasil dinyalakan. Status: $status"
}

# mematikan VM lewat sinyal ACPI power buttom, tunggu sampai benar-benar mati

vm_stop() {
    require_vm "$1"
    print_header
    local vm="$1"
    echo "Mematikan VM '$vm' secara aman..."
    VBoxManage controlvm "$vm" acpipowerbutton > /dev/null 2>&1
    local status=""
    for i in $(seq 1 15); do
        status=$(get_status "$vm")
        [ "$status" = "poweroff" ] && break
        sleep 2
    done
    echo "VM '$vm' berhasil dimatikan. Status: $status"
}

# membuat snapshot baru dari kondisi VM saat ini, konfirmasi dengan timestamp
vm_snapshot_create() {
    require_vm "$1"
    # nama snapshot juga wajib diisi sama seperti validasi nama vm
    if [ -z "$2" ]; then
        print_header
        echo "Error: nama snapshot belum diisi."
        echo "Usage: $0 snapshot create <nama_vm> <nama_snapshot>"
        exit 1
    fi
    print_header
    local vm="$1"
    local name="$2"
    echo "Membuat snapshot '$name' pada VM '$vm'..."
    VBoxManage snapshot "$vm" take "$name" > /dev/null 2>&1
    # ambil waktu sekarang dari sistem buat bukti kapan snapshot dibuat
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "Snapshot '$name' berhasil dibuat pada $timestamp."
}

# menampilkan daftar snapshot
vm_snapshot_list() {
    require_vm "$1"
    print_header
    local vm="$1"
    echo "Daftar snapshot VM '$vm':"
    # VBoxManage snapshot list outputnya berlapis dan agak berantakan
    # jadi diambil cuma baris "Name:" nya, lalu dinomori 
    local i=1
    while IFS= read -r name; do
        echo "  $i. $name"
        i=$((i+1))
    done < <(VBoxManage snapshot "$vm" list | grep "Name:" | sed -E 's/^[[:space:]]*Name:[[:space:]]*([^(]+).*/\1/' | sed 's/ *$//')
}

# baca argumen pertama ($1),
# lalu panggil fungsi yg sesuai
case "$1" in
    list) vm_list ;;
    info) vm_info "$2" ;;
    start) vm_start "$2" ;;
    stop) vm_stop "$2" ;;
    snapshot)
	# action snapshot punya subaction untuk create/list di argumen kedua
        case "$2" in
            create) vm_snapshot_create "$3" "$4" ;;
            list) vm_snapshot_list "$3" ;;
            *) echo "Usage: $0 snapshot {create|list} <nama_vm> [nama_snapshot]" ;;
        esac
        ;;
    *) echo "Usage: $0 {list|info|start|stop|snapshot create|snapshot list} <nama_vm>" ;;
esac