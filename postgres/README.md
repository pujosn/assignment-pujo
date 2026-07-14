# PostgreSQL configuration and investigation

## Start and verify

1. Mulai database dengan `docker-compose up -d db`.
2. Cek konfigurasi `max_connections`:

   ```docker exec -it pujo-mifx-db psql -U postgres -d postgres -c "SHOW max_connections;"
      max_connections 
      -----------------
      200
      (1 row)
   ```

   Output yang diharapkan adalah `200`.

User yang dibuat saat inisialisasi:

| User | Akses |
| --- | --- |
| `sre` | Login user, owner database `sre`, full access. |
| `sre_read` | Login user, read-only (`SELECT`) pada tabel yang ada dan tabel baru di schema `public`. |



## Analisis Penyelesaian Masalah: Lonjakan CPU Database & Query Lambat

Ketika tim back-office melakukan pengecekan jumlah afiliasi, penggunaan CPU pada database melonjak signifikan dan penarikan data menjadi sangat lambat. Di sisi lain, resource pada dashboard terpantau normal. Hal ini menandakan bahwa masalah utama (bottleneck) murni terjadi pada lapisan database.

```
select count(affiliates) from client where client_id = 'this_is_client_id';
```

Setelah memeriksa skema tabel client, ditemukan dua akar masalah utama:

1. Tidak Ada Index (Penyebab Utama): Pada bagian Indexes, tertulis "No index defined" untuk kolom client_id. Karena kolom
   yang digunakan pada klausa WHERE tidak di-index, PostgreSQL terpaksa melakukan Sequential Scan (Full Table Scan). Database harus membaca seluruh baris tabel satu per satu dari disk/memori hanya untuk mencari client_id yang cocok. Proses ini memakan komputasi CPU yang sangat besar dan membuat query semakin lambat seiring bertambahnya data.
2. Agregasi Kurang Efisien: Query menggunakan count(affiliates). Perintah ini memaksa database untuk mengecek satu per satu
   apakah nilai di dalam kolom affiliates bernilai NULL atau tidak pada setiap baris yang cocok, bukan langsung menghitung total barisnya.

Strategi Penyelesaian & Langkah Implementasi

1. Pembuatan Database Indexing. menambahkan index tipe B-Tree pada kolom client_id untuk mengubah proses pencarian database
   dari Sequential Scan yang berat menjadi Index Scan yang sangat cepat.
   Agar proses pembuatan index tidak mengunci tabel (table locking) yang dapat mengganggu aktivitas baca/tulis aplikasi yang sedang berjalan, index dibuat menggunakan keyword CONCURRENTLY:

'''CREATE INDEX CONCURRENTLY idx_client_client_id ON client(client_id);'''

2. Optimasi Query (Refactoring Kode Backend) merekomendasikan tim developer untuk mengoptimasi penarikan data di sisi backend dengan mengubah perhitungan berbasis kolom menjadi berbasis baris (wildcard):

'''select count(*) from client where client_id = 'this_is_client_id';'''

3. Untuk memastikan perbaikan berhasil, query diuji kembali menggunakan perintah 

'''EXPLAIN ANALYZE:SQLEXPLAIN ANALYZE select count(*) from client where client_id = 'this_is_client_id';'''

   - Perubahan Hasil:Perencanaan query (query plan) berubah dari Seq Scan yang berbiaya tinggi menjadi Bitmap Index Sca
     (atau Index Scan menggunakan idx_client_client_id).
   - Waktu Eksekusi (Execution Time): Turun drastis dari yang sebelumnya hitungan detik/menit menjadi hanya beberapa
     milidetik ($ms$).
   - Penggunaan Resource: Penggunaan CPU database kembali stabil dan tidak ada lagi lonjakan (spike) saat tim back-office
     menarik data tersebut. Masalah selesai sepenuhnya.
