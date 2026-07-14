# Security hardening: Nginx dan PHP-FPM

Dokumen ini menjelaskan perubahan untuk memenuhi bagian **Security Hardening** pada technical test.

## Nginx

| Tujuan tugas | Implementasi | Alasan |
| --- | --- | --- |
| Tidak menampilkan directory listing | `autoindex off;` | URL ke folder tanpa `index.html` atau `index.php` akan menghasilkan respons 403, bukan daftar file. |
| Folder `.git` tidak dapat diakses | `location ~ /\\.git(?:/|$) { return 404; }` | Metadata repository seperti riwayat, remote, dan kemungkinan credential tidak bocor. |
| Tidak berjalan sebagai root | Dockerfile memakai `USER nginx`; folder runtime diberi owner `nginx`. | Jika proses dieksploitasi, dampaknya tidak memiliki hak root. |
| Header tidak menunjukkan Nginx | Modul `headers-more` mengatur `Server: MIFX Web Server`; `server_tokens off` juga menyembunyikan versi. | Mengurangi informasi teknologi yang diberikan kepada pihak luar. |

Nginx tetap dapat mendengarkan port 80 karena binary diberi capability `cap_net_bind_service`, bukan karena proses dijalankan sebagai root.

## PHP-FPM

| Tujuan tugas | Implementasi | Alasan |
| --- | --- | --- |
| `exec()` tidak bisa digunakan | `disable_functions` di `php-fpm/99-security.ini` menonaktifkan `exec` serta fungsi eksekusi shell terkait. | Mengurangi risiko remote command execution. |
| PHP-FPM tidak berjalan sebagai root | Pool `www` memakai `user = nginx` dan image berjalan dengan `USER nginx`. | Master dan worker PHP-FPM berjalan dengan hak terbatas. |

`expose_php = Off` dan `fastcgi_hide_header X-Powered-By` menambahkan perlindungan agar versi PHP tidak terlihat dari header HTTP.

## Verifikasi

Build image baru terlebih dahulu:

```sh
docker build -t pujosn/pujo-mifx-task:v1.7.0 .
docker run --rm -d --name pujo-security-test -p 18081:80 pujosn/pujo-mifx-task:v1.7.0
```

Kemudian jalankan pemeriksaan berikut:

```sh
# Tidak boleh ada "Server: nginx" atau "X-Powered-By".
curl -sI http://localhost:18081/

# Harus 404.
curl -i http://localhost:18081/.git/HEAD

# Buat folder tanpa index; respons harus 403, bukan daftar file.
docker exec pujo-security-test mkdir -p /var/www/html/no-index
curl -i http://localhost:18081/no-index/

# Harus menampilkan bool(false): fungsi exec dinonaktifkan.
docker exec pujo-security-test php82 -r 'var_dump(function_exists("exec"));'

# Semua proses utama harus memakai user nginx, bukan root.
docker exec pujo-security-test ps -o user,args

docker stop pujo-security-test
```
