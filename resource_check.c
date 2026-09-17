/*
 * resource_check.c
 * Tugas 1 Sistem Operasi - VM Manager
 * Kelompok B04, Varian C
 *
 * Varian C
 *   Metrik 1 = Disk usage (persen)     -> FAIL >= 90, WARN >= 75
 *   Metrik 2 = Jumlah proses berjalan  -> FAIL >= 400, WARN >= 200
 *
 */

#include <stdio.h>

/* Ambang batas Metrik 1, disk usage persen */
#define DISK_FAIL 90.0
#define DISK_WARN 75.0

/* Ambang batas Metrik 2, jumlah proses berjalan */
#define PROC_FAIL 400.0
#define PROC_WARN 200.0

/* Kode status, sengaja urut supaya bisa dibandingkan dengan operator lebih besar */
#define ST_PASS 0
#define ST_WARN 1
#define ST_FAIL 2

static const char *nama_status(int kode)
{
    if (kode == ST_FAIL) return "FAIL";
    if (kode == ST_WARN) return "WARN";
    return "PASS";
}

/* Metrik 1, disk usage */
static int cek_disk(double persen)
{
    if (persen >= DISK_FAIL) return ST_FAIL;
    if (persen >= DISK_WARN) return ST_WARN;
    return ST_PASS;
}

/* Metrik 2, jumlah proses berjalan */
static int cek_proses(double jumlah)
{
    if (jumlah >= PROC_FAIL) return ST_FAIL;
    if (jumlah >= PROC_WARN) return ST_WARN;
    return ST_PASS;
}

static const char *ket_disk(int status)
{
    if (status == ST_FAIL) return "Kritis, ruang hampir habis";
    if (status == ST_WARN) return "Mulai penuh";
    return "Masih lega";
}

static const char *ket_proses(int status)
{
    if (status == ST_FAIL) return "Sangat padat, cek proses liar";
    if (status == ST_WARN) return "Lebih padat dari biasanya";
    return "Masih wajar";
}

int main(void)
{
    double disk = 0.0, proses = 0.0;
    int status_disk, status_proses, terburuk;

    /* Baca 2 angka dari stdin, dikirim sysinfo.sh lewat pipe */
    if (scanf("%lf", &disk) != 1) {
        fprintf(stderr, "resource_check: gagal membaca metrik 1 (disk usage)\n");
        return 3;
    }
    if (scanf("%lf", &proses) != 1) {
        fprintf(stderr, "resource_check: gagal membaca metrik 2 (jumlah proses)\n");
        return 3;
    }

    status_disk = cek_disk(disk);
    status_proses = cek_proses(proses);

    terburuk = (status_disk > status_proses) ? status_disk : status_proses;

    printf("Disk|%.0f%%|%s|%s\n",
           disk, nama_status(status_disk), ket_disk(status_disk));
    printf("Proses|%.0f proses|%s|%s\n",
           proses, nama_status(status_proses), ket_proses(status_proses));

    return terburuk;
}
