# Projek Analisis Data E-Commerce: Nilai Transaksi Pelanggan

**Tujuan**  
Mengeksplorasi hubungan antara nilai transaksi pelanggan dan tiga ukuran perilaku belanja pada *Brazil E-commerce Orders Dataset* dari Kaggle. Dokumentasi ini mencakup struktur proyek, kebutuhan sistem, alur pengerjaan, cara menjalankan ulang, penjelasan script, daftar output, catatan metodologi, serta panduan pemecahan masalah. Ringkasan hasil dan visualisasi tersedia di [RESULT.md](RESULT.md). Rincian alur dari pencarian dataset sampai publikasi ada di [docs/alur-pengerjaan.md](docs/alur-pengerjaan.md).

---

## 1. Struktur Proyek

```
analisis-rfm-ecommerce-brasil/
│
├─ data/
│   ├─ README.md                               # Sumber, lisensi, dan variabel
│   ├─ raw/
│   │   └─ order_customer.csv                  # 112.650 baris transaksi, 4 kolom
│   └─ processed/
│       └─ order_customer_clean.csv            # 95.420 baris pelanggan hasil agregasi
│
├─ assets/                                     # Salinan plot untuk RESULT.md
│   ├─ g1_distribusi_monetary_value.png
│   ├─ g2_boxplot_monetary_value.png
│   ├─ g3_scatter_total_purchases.png
│   ├─ g4_scatter_average_order_value.png
│   ├─ g5_scatter_recency_days.png
│   ├─ g6_residual_vs_fitted.png
│   └─ g7_qq_plot.png
│
├─ output/
│   ├─ tables/
│   │   ├─ statistik_deskriptif.csv
│   │   ├─ korelasi.csv
│   │   ├─ regresi_sederhana.txt
│   │   ├─ regresi_berganda.txt
│   │   ├─ uji_asumsi.txt
│   │   ├─ prediksi.csv
│   │   └─ provenance.txt
│   ├─ plots/
│   │   ├─ hist_y.png
│   │   ├─ box_y.png
│   │   ├─ scatter_purchases_y.png
│   │   ├─ scatter_order_value_y.png
│   │   ├─ scatter_recency_y.png
│   │   ├─ residual_vs_fitted.png
│   │   └─ qq_plot.png
│   └─ analisis_log.txt
│
├─ R/
│   └─ analysis.R                              # Script utama menghasilkan semua output
│
├─ laporan/
│   ├─ laporan.Rmd                             # Membaca output secara dinamis
│   ├─ laporan.pdf
│   └─ render_log.txt
│
├─ presentasi/
│   └─ slide.md
│
├─ docs/
│   └─ alur-pengerjaan.md
├─ RESULT.md
├─ projek_uas.Rproj
└─ README.md
```

---

## 2. Kebutuhan Sistem

- **R** versi 4.3 atau lebih tinggi
- **RStudio** untuk alur klik di bagian 4.1
- **Paket R**: `ggplot2`, `car`, `lmtest`, `knitr`, `rmarkdown`
- **Python** dan modul `kaggle` untuk mengunduh ulang dataset
- **Git** untuk kontrol versi
- **Lisensi data**: halaman Kaggle mencantumkan `Unknown`; berkas mentah disertakan di `data/raw/` agar analisis dapat diulang tanpa bergantung pada unduhan ulang

---

## 3. Alur Pengerjaan

1. **Unduh dataset** `mehmetisik/order-customerrfm` dari Kaggle dan simpan sebagai `data/raw/order_customer.csv`. Berkas mentah memuat 112.650 baris transaksi level order-item dan 4 kolom.
2. **Agregasi data** menjadi satu baris per `customer_unique_id`. Script menghitung 95.420 pelanggan, 98.666 order unik, dan empat variabel model.
3. **Bersihkan data**:
   - Periksa empat kolom wajib pada berkas mentah.
   - Hitung `Monetary_Value`, `Total_Purchases`, `Average_Order_Value`, dan `Recency_Days`.
   - Buang baris dengan `NA` pada variabel model memakai `complete.cases()`.
   - Buang baris duplikat dari hasil penyaringan dengan `!duplicated()`.
   - Simpan hasil ke `data/processed/order_customer_clean.csv` sebanyak 95.420 baris.
4. **Jalankan script R** `R/analysis.R` yang menghasilkan statistik deskriptif, matriks korelasi, regresi sederhana `Y ~ X1`, regresi berganda `Y ~ X1 + X2 + X3`, uji asumsi, prediksi tiga skenario, log, dan tujuh plot.
5. **Render laporan** dengan `laporan/laporan.Rmd`. Semua angka dibaca dari berkas output, bukan ditulis manual.
6. **Perbarui** `RESULT.md`, `docs/alur-pengerjaan.md`, `data/README.md`, dan `presentasi/slide.md` bila struktur atau hasil berubah.

---

## 4. Cara Menjalankan Ulang

### 4.1 Membuka proyek di RStudio

1. Kloning repositori:

   ```bash
   git clone https://github.com/yayayapluto/analisis-rfm-ecommerce-brasil.git
   cd analisis-rfm-ecommerce-brasil
   ```

2. Buka RStudio. Pilih **File > Open Project...**, arahkan ke folder proyek, lalu pilih `projek_uas.Rproj`.

3. Di panel **Console**, pasang paket sekali saja:

   ```r
   install.packages(c("ggplot2", "car", "lmtest", "knitr", "rmarkdown"))
   ```

4. Buka `R/analysis.R`, lalu klik **Source**. Script membaca CSV mentah, menulis tabel dan plot ke `output/`, lalu mencetak `Analisis selesai.`

5. Buka `laporan/laporan.Rmd`, lalu klik **Knit**. Hasil tersimpan sebagai `laporan/laporan.pdf`.

6. Periksa `RESULT.md` dan `output/tables/`. Angka di laporan dan slide berasal dari berkas output yang dibuat pada langkah 4.

### 4.2 Menjalankan lewat terminal

Jalankan dari root proyek:

```bash
Rscript R/analysis.R
Rscript -e "rmarkdown::render('laporan/laporan.Rmd')"
```

Untuk mengunduh ulang data mentah:

```bash
python -m kaggle datasets download -d mehmetisik/order-customerrfm -p data/raw --unzip
```

---

## 5. Penjelasan Script `R/analysis.R`

Script memakai base R untuk agregasi, pembacaan, dan penulisan CSV, `ggplot2` untuk plot, `car` untuk VIF, dan `lmtest` untuk Breusch-Pagan. Urutan kerjanya:

1. Membaca `data/raw/order_customer.csv` dan memeriksa kolom wajib.
2. Mengubah timestamp menjadi tanggal, lalu menetapkan tanggal transaksi terakhir sebagai referensi `Recency_Days`.
3. Mengagregasi transaksi per pelanggan menjadi empat variabel model.
4. Menyaring `NA` dengan `complete.cases()` dan duplikat dengan `!duplicated()`.
5. Menyimpan `data/processed/order_customer_clean.csv`.
6. Menghitung statistik deskriptif dan matriks korelasi Pearson.
7. Menaksir model `Y ~ X1` dan `Y ~ X1 + X2 + X3`.
8. Menjalankan VIF, Shapiro-Wilk pada 5.000 residual acak, dan Breusch-Pagan.
9. Memprediksi tiga skenario kuartil dengan interval kepercayaan 95 persen.
10. Menyimpan tujuh plot dan menulis log ke `output/analisis_log.txt`.

---

## 6. Daftar Output

| Nama Berkas | Deskripsi |
|-------------|-----------|
| `output/tables/statistik_deskriptif.csv` | Statistik deskriptif tiap variabel model. |
| `output/tables/korelasi.csv` | Matriks korelasi Pearson untuk Y, X1, X2, X3. |
| `output/tables/regresi_sederhana.txt` | Ringkasan model `Y ~ X1`. |
| `output/tables/regresi_berganda.txt` | Ringkasan model `Y ~ X1 + X2 + X3`. |
| `output/tables/uji_asumsi.txt` | Hasil VIF, Shapiro-Wilk, dan Breusch-Pagan. |
| `output/tables/prediksi.csv` | Skenario `total_purchases`, `average_order_value`, `recency_days`, prediksi, dan batas interval 95 persen. |
| `output/tables/korelasi_spearman.csv` | Matriks korelasi Spearman untuk Y, X1, X2, X3 (pembanding Pearson). |
| `output/tables/regresi_tanpa_x2.txt` | Ringkasan model pembanding `Y ~ X1 + X3` (R² 0,0112). |
| `output/tables/regresi_log.txt` | Ringkasan model `log(Y) ~ X1 + X3` (R² 0,0201). |
| `output/tables/uji_asumsi_robust.csv` | Galat baku robust HC1 untuk model berganda. |
| `output/tables/provenance.txt` | Sumber, lisensi, metadata, dan ringkasan baris. |
| `output/analisis_log.txt` | Log lengkap eksekusi script R. |
| `data/processed/order_customer_clean.csv` | Tabel pelanggan hasil agregasi dan penyaringan, 95.420 baris. |
| `output/plots/*.png` | Tujuh plot yang dipakai laporan, slide, dan `RESULT.md`. |

---

## 7. Catatan Metodologi

- **Sumber data**: *Brazil E-commerce Orders Dataset*, Kaggle `mehmetisik/order-customerrfm`, pembaruan terakhir 2023-06-09. Halaman dataset mencantumkan lisensi `Unknown`.
- **Unit analisis**: pelanggan, bukan baris transaksi. Agregasi menghasilkan 95.420 pelanggan dari 112.650 baris transaksi dan 98.666 order unik.
- **Variabel model**
  - `Y` = `Monetary_Value`, total `price` per pelanggan, dalam real Brasil (BRL, R$).
  - `X1` = `Total_Purchases`, jumlah `order_id` unik per pelanggan.
  - `X2` = `Average_Order_Value`, `Monetary_Value` dibagi `X1`, dalam real Brasil (BRL, R$).
  - `X3` = `Recency_Days`, selisih hari antara transaksi terakhir pelanggan dan 2018-09-03.
- **Penyaringan**: 0 baris dibuang karena `NA`, 0 baris duplikat dibuang, 95.420 baris final. Baris transaksi identik tetap dihitung saat agregasi karena berkas mentah tidak memuat identitas produk.
- **Korelasi kunci**: kor(Y, X1) = 0,106; kor(Y, X2) = 0,985; kor(Y, X3) = 0,001.
- **Model sederhana** `Y ~ X1`: intercept 29,523; slope X1 109,202; R² 0,0112.
- **Model berganda** `Y ~ X1 + X2 + X3`: intercept -122,076; X1 120,285; X2 1,015; X3 -0,001; R² 0,9831; adjusted R² 0,9831. X3 tidak signifikan dengan p-value 0,264.
- **Catatan penting**: X2 diturunkan dari Y dibagi X1. Hubungan X2 dengan Y memuat identitas aljabar, sehingga R² model berganda tidak boleh dibaca sebagai kemampuan prediksi umum.
- **Uji asumsi**: VIF berada di sekitar 1, sedangkan Shapiro-Wilk dan Breusch-Pagan menolak normalitas serta homoskedastisitas residual.
- **Wilayah data**: transaksi berasal dari e-commerce Brasil, bukan Indonesia. Seluruh nilai uang memakai real Brasil (BRL, R$).

---

## 8. Pemecahan Masalah

| Masalah | Solusi |
|---------|--------|
| **Gagal membaca CSV** | Pastikan `data/raw/order_customer.csv` ada. Coba baca dengan `read.csv()` dari konsol R. |
| **Kolom wajib hilang** | Periksa nama kolom pada berkas mentah. Script berhenti bila `order_id`, `customer_unique_id`, `order_purchase_timestamp`, atau `price` tidak ada. |
| **Semua nilai NA setelah agregasi** | Periksa keselarasan vektor hasil `tapply()` dengan `id_pelanggan`. Urutan agregasi mengikuti urutan `sort(unique())`. |
| **Plot tidak muncul** | Pastikan `ggplot2` terpasang dan direktori kerja berada di root proyek. |
| **Laporan Rmd error** | Jalankan `rmarkdown::render()` dari root proyek. Periksa path relatif bila dipindah ke folder lain. |
| **Angka laporan tidak berubah** | Jalankan ulang `R/analysis.R` sebelum `rmarkdown::render()`. Laporan membaca berkas output, bukan menghitung ulang dari CSV mentah. |

---

## 9. Referensi Singkat

- `mehmetisik`, *Brazil E-commerce Orders Dataset*, Kaggle, 2023. https://www.kaggle.com/datasets/mehmetisik/order-customerrfm
- Metodologi regresi linear sederhana dan berganda memakai paket `stats` bawaan R.
- Prosedur lengkap ada di [docs/alur-pengerjaan.md](docs/alur-pengerjaan.md).

---

*End of README.md*
