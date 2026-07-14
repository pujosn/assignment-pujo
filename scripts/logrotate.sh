#!/bin/bash
# Menggunakan set -e agar skrip berhenti jika terjadi error kritis
set -e

# --- KONFIGURASI TUGAS ---
TARGET_DIR="/home/pujo/Music/pujo-assignment-mfix/scripts/logstest" # Ganti dengan direktori log tujuanmu
LOG_FILE="/var/log/custom_logrotate.log"               # File untuk mencatat aksi skrip ini
MAX_SIZE_MB=5                                           # Batas ukuran file (5 MB)

# Konversi ukuran ke satuan Bytes untuk perbandingan matematika
# 5 MB = 5 * 1024 * 1024 Bytes
MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1024 * 1024))

# Fungsi untuk mencatat log ke file logrotate
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 1. Pastikan direktori target ada
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Direktori $TARGET_DIR tidak ditemukan!"
    exit 1
fi

log_message "=== Memulai Proses Logrotate Custom ==="

# 2. Scan setiap file yang berakhiran .log di dalam direktori
for file in "$TARGET_DIR"/*.log; do
    
    # Antisipasi jika tidak ada file .log sama sekali di dalam folder
    [ -e "$file" ] || continue

    # Ambil ukuran file dalam satuan Bytes
    FILE_SIZE=$(stat -c%s "$file")

    # 3. Cek apakah ukuran file lebih besar dari 5 MB (MAX_SIZE_BYTES)
    if [ "$FILE_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
        TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
        ARCHIVE_NAME="${file}_${TIMESTAMP}.tar.gz"

        log_message "Ditemukan: $(basename "$file") berukuran $(($FILE_SIZE/1024/1024)) MB (Melebihi $MAX_SIZE_MB MB)"

        # a. Proses Archiving: Kompres file log menjadi .tar.gz
        tar -czf "$ARCHIVE_NAME" -C "$TARGET_DIR" "$(basename "$file")"
        log_message "Archived: Berhasil membuat arsip $ARCHIVE_NAME"

        # b. Proses Truncating: Kosongkan isi file log asli tanpa menghapus filenya
        # Menggunakan '>' lebih aman dibanding 'rm' karena aplikasi yang sedang menulis log tidak akan patah/error
        > "$file"
        log_message "Truncated: File $(basename "$file") berhasil dikosongkan."
    fi
done

log_message "=== Proses Logrotate Selesai ==="
