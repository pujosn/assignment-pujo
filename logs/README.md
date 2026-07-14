Di dalam Bash script, perintah set -e (sering disebut errexit) berfungsi untuk menghentikan eksekusi skrip secara otomatis jika ada satu saja perintah yang menghasilkan error (atau mengembalikan exit status non-nol).

Tanpa set -e: Bash akan terus mengeksekusi baris berikutnya meskipun perintah di atasnya gagal total. Ini sangat berbahaya untuk tugas otomatisasi (seperti deployment atau backup).

contoh kasus bahaya:
cd /folder_yang_salah
rm -rf *  # Jika folder gagal dibuka, perintah ini malah menghapus folder aktif saat itu!

Dengan set -e: Begitu perintah cd di atas gagal karena foldernya tidak ada, skrip akan langsung mati saat itu juga sebelum sempat mengeksekusi perintah menghapus (rm), sehingga server aman dari kesalahan fatal.


