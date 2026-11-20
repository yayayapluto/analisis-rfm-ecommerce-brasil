# Alur Pengerjaan: Dari Pencarian Data sampai Publikasi

Dokumen ini merangkum alur kerja analisis `Monetary_Value` pada *Brazil
E-commerce Orders Dataset*. Cakupannya mulai dari penentuan kebutuhan data,
pencarian dan unduhan dataset, agregasi transaksi menjadi data pelanggan,
eksekusi pipeline R, penyusunan laporan dan slide, sampai publikasi di GitHub.
Prosedur di sini ditulis supaya bisa diulang dari awal. Angka yang disebut
berasal dari berkas output di repo.

## Ringkasan keputusan

| Aspek | Keputusan |
|---|---|
| Sumber data | Kaggle `mehmetisik/order-customerrfm` |
| Judul dataset | Brazil E-commerce Orders Dataset |
| Lisensi | Unknown pada halaman Kaggle |
| Tanggal pembaruan | 2023-06-09T07:17:24.663000 |
| Karakter data | Transaksi e-commerce Brasil, bukan data Indonesia |
| Baris transaksi mentah | 112.650 |
| Order unik | 98.666 |
| Pelanggan unik | 95.420 |
| Variabel terikat | `Y = Monetary_Value` |
| Prediktor | `X1 = Total_Purchases`, `X2 = Average_Order_Value`, `X3 = Recency_Days` |
| Baris setelah agregasi | 95.420 |
| Baris dibuang karena `NA` | 0 |
| Baris duplikat dibuang | 0 |
| Baris final | 95.420 |
| Repo publik | `yayayapluto/analisis-rfm-ecommerce-brasil`, branch `main` |

---

## Tahap 1: Menetapkan kebutuhan data

Analisis memakai regresi linear dengan satu variabel terikat dan tiga prediktor.
Dataset tidak menyediakan kolom RFM siap pakai, sehingga kriteria kandidat data
diubah sebagai berikut.

1. Memuat identitas order, identitas pelanggan, waktu pembelian, dan nilai
   transaksi.
2. Nilai transaksi dapat diagregasi menjadi total per pelanggan.
3. Waktu transaksi dapat dipakai untuk menghitung selisih hari terhadap tanggal
   referensi.
4. Jumlah transaksi cukup besar untuk estimasi regresi berganda.
5. Pemilik dan tanggal pembaruan dataset tercantum supaya versi data bisa
   dilacak.
6. Proyek tidak mengklaim data sebagai transaksi Indonesia. Satuan nilai
   mengikuti dataset tanpa simbol mata uang.

---

## Tahap 2: Mencari dataset di Kaggle

Langkah berikut dipakai untuk menemukan dan menilai kandidat dataset.

1. Buka https://www.kaggle.com/datasets.
2. Cari dengan kata kunci `order customer rfm`.
3. Buka hasil pada tab **Datasets**, lalu periksa deskripsi, jumlah baris, daftar
   kolom, pemilik, dan tanggal pembaruan.
4. Tolak kandidat yang hanya menyediakan variabel agregat tanpa identitas order
   atau waktu transaksi.
5. Pilih *Brazil E-commerce Orders Dataset* dari akun `mehmetisik`. Dataset ini
   memuat 112.650 baris order-item dan empat kolom yang dibutuhkan.
6. Simpan URL, pemilik, lisensi, dan tanggal pembaruan ke
   `output/tables/provenance.txt` dan `data/README.md`.

Tautan final: https://www.kaggle.com/datasets/mehmetisik/order-customerrfm

Metadata API Kaggle mencatat `ref = mehmetisik/order-customerrfm`,
`lastUpdated = 2023-06-09 07:17:24.663000`, `licenseName = Unknown`, dan
`totalBytes = 5098690`.

---

## Tahap 3: Mengunduh dan menyimpan data mentah

### Cara manual

1. Masuk ke akun Kaggle.
2. Buka tautan dataset.
3. Klik **Download**.
4. Ekstrak arsip hasil unduhan.
5. Simpan berkas CSV ke `data/raw/order_customer.csv`.

### Cara Python API

Modul `kaggle` tersedia sebagai paket Python. Jalankan dari root proyek:

```bash
python -m kaggle datasets download -d mehmetisik/order-customerrfm -p data/raw --unzip
```

Periksa hasil unduhan dari konsol R:

```r
data_mentah <- read.csv("data/raw/order_customer.csv")
nrow(data_mentah)  # 112650
ncol(data_mentah)  # 4
names(data_mentah)
```

Pemeriksaan lanjutan: 98.666 `order_id` unik, 95.420 `customer_unique_id`
unik, 0 nilai `NA` pada keempat kolom, dan rentang tanggal 2016-09-04 sampai
2018-09-03.

---

## Tahap 4: Mencatat provenance

Provenance ditulis sebelum analisis lanjutan supaya sumber data tidak tercampur
dengan hasil olahan. Berkas `output/tables/provenance.txt` memuat:

- nama dataset, judul, dan pemilik,
- URL Kaggle,
- lisensi dan tanggal pembaruan,
- jumlah baris transaksi, order unik, dan pelanggan unik,
- definisi `Y`, `X1`, `X2`, dan `X3`,
- jumlah baris setelah agregasi, penyaringan `NA`, duplikat, dan baris final.

`data/README.md` memuat versi ringkas untuk pembaca repo. Keduanya mengacu pada
dataset yang sama dengan CSV di `data/raw/`.

---

## Tahap 5: Agregasi dan pra-pengolahan

Script `R/analysis.R` mengubah transaksi menjadi data pelanggan sebelum
pemodelan.

1. Membaca `data/raw/order_customer.csv` dengan `read.csv()`.
2. Memeriksa keberadaan `order_id`, `customer_unique_id`,
   `order_purchase_timestamp`, dan `price`. Script berhenti bila ada kolom yang
   hilang.
3. Mengubah `order_purchase_timestamp` menjadi tanggal dan menetapkan 2018-09-03
   sebagai tanggal referensi `Recency_Days`.
4. Menyusun `id_pelanggan` dari `sort(unique())`, lalu menghitung empat variabel
   dengan `tapply()` yang dibungkus `unname()`.
5. Menghitung `Monetary_Value` dari penjumlahan `price`, `Total_Purchases` dari
   jumlah `order_id` unik, `Average_Order_Value` dari pembagian keduanya, dan
   `Recency_Days` dari selisih tanggal.
6. Menghitung jumlah `NA` per variabel model dan menyaring dengan
   `complete.cases()`.
7. Membuang duplikat dengan `!duplicated()`, lalu menghitung `baris_na`,
   `baris_duplikat`, `baris_final`, dan `baris_dibuang`.
8. Menyimpan hasil akhir ke `data/processed/order_customer_clean.csv`.

Hasil terverifikasi: 95.420 baris awal setelah agregasi, 0 baris dibuang karena
`NA`, 0 baris duplikat, 95.420 baris final, dan 0 total baris dibuang. Baris
transaksi identik tetap dihitung karena berkas mentah tidak memuat identitas
produk.

---

## Tahap 6: Menjalankan pipeline R

Paket yang dipakai: `ggplot2`, `car`, `lmtest`, `knitr`, dan `rmarkdown`.
Jalankan dari root proyek:

```bash
Rscript R/analysis.R
```

| Tahap analisis | Fungsi utama | Output |
|---|---|---|
| Statistik deskriptif | `mean`, `median`, `var`, `sd`, kuartil | `output/tables/statistik_deskriptif.csv` |
| Korelasi | `cor()` pada variabel model | `output/tables/korelasi.csv` |
| Regresi sederhana | `lm(Y ~ X1)` | `output/tables/regresi_sederhana.txt` |
| Regresi berganda | `lm(Y ~ X1 + X2 + X3)` | `output/tables/regresi_berganda.txt` |
| Multikolinearitas | `car::vif()` | `output/tables/uji_asumsi.txt` |
| Normalitas residual | `shapiro.test()` pada sampel 5.000 residual | `output/tables/uji_asumsi.txt` |
| Heteroskedastisitas | `lmtest::bptest()` | `output/tables/uji_asumsi.txt` |
| Prediksi tiga skenario | `predict()` dengan interval 95 persen | `output/tables/prediksi.csv` |
| Visualisasi | `ggplot2`, `qqnorm()` | `output/plots/*.png` |
| Log eksekusi | `sink()` | `output/analisis_log.txt` |

Skenario prediksi dibentuk dari kuartil 0,25; 0,50; dan 0,75 pada masing-masing
prediktor. Baris **Rendah**, **Menengah**, dan **Tinggi** berasal dari kombinasi
kuartil yang dibuat oleh script, bukan dari baris data tertentu.

---

## Tahap 7: Membaca hasil

Angka berikut dibaca langsung dari output R.

| Ringkasan | Nilai |
|---|---|
| `kor(Y, X1)` | 0,106 |
| `kor(Y, X2)` | 0,985 |
| `kor(Y, X3)` | 0,001 |
| R-squared `Y ~ X1` | 0,0112 |
| R-squared `Y ~ X1 + X2 + X3` | 0,9831 |
| VIF `X1`, `X2`, `X3` | 1,000619; 1,000133; 1,000515 |
| Shapiro-Wilk | `W = 0,21583`, `p < 2.2e-16` |
| Breusch-Pagan | `BP = 1992,3`, `df = 3`, `p < 2.2e-16` |
| Prediksi Rendah, Menengah, Tinggi | 45,23; 86,75; 150,12 |

Korelasi Y-X2 sangat tinggi karena X2 diturunkan dari Y dibagi X1. R² model
berganda berada di atas 0,98, tetapi angka itu tidak boleh dipakai sebagai bukti
prediksi umum. `Total_Purchases` memiliki variasi kecil karena sebagian besar
pelanggan hanya memiliki satu order. `Recency_Days` tidak signifikan pada model
berganda. Uji Shapiro-Wilk dan Breusch-Pagan menolak normalitas serta
homoskedastisitas residual, sehingga interpretasi inference perlu dibaca dengan
hati-hati.

---

## Tahap 8: Menyusun laporan, slide, dan ringkasan hasil

1. Render laporan dari root proyek:

   ```bash
   Rscript -e "rmarkdown::render('laporan/laporan.Rmd')"
   ```

   `laporan/laporan.Rmd` membaca angka dari `output/tables/`, jadi tidak ada
   nilai regresi yang ditulis manual di dalam laporan.

2. Periksa `laporan/laporan.pdf`. Bab 2 membahas sumber data dan agregasi, Bab 3
   sampai Bab 7 membahas hasil analisis, Bab 8 memuat kesimpulan.

3. Salin tujuh plot ke `assets/` dengan nama `g1_` sampai `g7_` agar
   `RESULT.md` punya aset lokal.

4. Perbarui `RESULT.md` dengan ringkasan pipeline, visualisasi, tabel hasil,
   prediksi, dan keterbatasan.

5. Perbarui `presentasi/slide.md`. Slide 3 memuat sumber data, Slide 4 agregasi
   dan preprocessing, Slide 11 demo RStudio.

6. Perbarui `README.md` jika struktur folder, paket, atau cara menjalankan
   berubah.

---

## Tahap 9: Publikasi

Repo publik memakai nama `analisis-rfm-ecommerce-brasil` supaya sumber data
Brasil tercermin pada nama repo. Branch utamanya `main`. Perubahan masuk lewat
pull request agar alurnya sama dengan repo proyek sebelumnya.

1. Buat branch kerja dari `main`.
2. Commit perubahan dengan pesan Conventional Commits.
3. Push branch kerja.
4. Buat pull request ke `main`.
5. Merge pull request, lalu hapus branch kerja.
6. Perbarui checkout lokal dengan `git pull --ff-only`.

URL repo: https://github.com/yayayapluto/analisis-rfm-ecommerce-brasil

---

## Checklist selesai

- [x] `data/raw/order_customer.csv` ada, berisi 112.650 baris dan 4 kolom.
- [x] `data/processed/order_customer_clean.csv` ada, berisi 95.420 baris akhir.
- [x] Seluruh berkas di `output/tables/` dan `output/plots/` terbentuk.
- [x] `laporan/laporan.pdf` lebih baru daripada `laporan/laporan.Rmd`.
- [x] Angka di `README.md`, `RESULT.md`, `laporan/laporan.Rmd`, dan
      `presentasi/slide.md` cocok dengan output R.
- [x] Tidak ada sisa nama dataset, path, atau klaim lama di dokumentasi.
- [ ] `git status --short` bersih dan `main` sudah sinkron dengan remote. (Belum: masih ada perubahan di branch `fix/perbaikan-uas` yang disiapkan untuk MR.)
- [x] URL repo publik mengembalikan status HTTP 200. (Diverifikasi 2026-11-20.)

Untuk langkah teknis membuka proyek di RStudio, lihat `README.md` bagian 4.1.
Untuk daftar output dan penjelasan tiap berkas, lihat `README.md` bagian 6.
