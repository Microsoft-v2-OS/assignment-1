#!/bin/bash
KELOMPOK="B04"

print_header() {
    echo "==================================="
    echo "TUGAS 1 OS - KELOMPOK $KELOMPOK"
    echo "==================================="
}

require_vm() {
    if [ -z "$1" ]; then
        print_header
        echo "Error: nama VM belum diisi."
        echo "Usage: $0 <aksi> <nama_vm> [argumen_tambahan]"
        exit 1
    fi
}

vm_list() {
    print_header
    echo "Memindai daftar Virtual Machine..."
    echo "Daftar VM terdaftar:"
    VBoxManage list vms | nl
}

vm_info() {
    require_vm "$1"
    print_header
    local vm="$1"
    local ram=$(VBoxManage showvminfo "$vm" --machinereadable | grep "^memory=" | cut -d= -f2)
    local cpu=$(VBoxManage showvminfo "$vm" --machinereadable | grep "^cpus=" | cut -d= -f2)
    local status=$(VBoxManage showvminfo "$vm" --machinereadable | grep "^VMState=" | cut -d= -f2 | tr -d '"')
    echo "VM               : $vm"
    echo "RAM dialokasikan : ${ram} MB"
    echo "vCPU dialokasikan: $cpu"
    echo "Status saat ini  : $status"
}

vm_start() {
    require_vm "$1"
    print_header
    local vm="$1"
    echo "Menyalakan VM '$vm' secara headless..."
    VBoxManage startvm "$vm" --type headless
}

vm_stop() {
    require_vm "$1"
    print_header
    local vm="$1"
    echo "Mematikan VM '$vm' secara aman..."
    VBoxManage controlvm "$vm" acpipowerbutton
}

vm_snapshot_create() {
    require_vm "$1"
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
    VBoxManage snapshot "$vm" take "$name"
}

vm_snapshot_list() {
    require_vm "$1"
    print_header
    local vm="$1"
    echo "Daftar snapshot VM '$vm':"
    VBoxManage snapshot "$vm" list
}

case "$1" in
    list) vm_list ;;
    info) vm_info "$2" ;;
    start) vm_start "$2" ;;
    stop) vm_stop "$2" ;;
    snapshot)
        case "$2" in
            create) vm_snapshot_create "$3" "$4" ;;
            list) vm_snapshot_list "$3" ;;
            *) echo "Usage: $0 snapshot {create|list} <nama_vm> [nama_snapshot]" ;;
        esac
        ;;
    *) echo "Usage: $0 {list|info|start|stop|snapshot create|snapshot list} <nama_vm>" ;;
esac