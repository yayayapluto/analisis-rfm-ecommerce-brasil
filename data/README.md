# Dokumentasi Data

Dataset: **Brazil E-commerce Orders Dataset**  
Akun Kaggle: `mehmetisik`  
URL: https://www.kaggle.com/datasets/mehmetisik/order-customerrfm  
Lisensi: Unknown (tidak tercantum pada halaman Kaggle)  
Tanggal pembaruan: 2023-06-09T07:17:24.663000

## Berkas

| Berkas | Isi |
|---|---|
| `raw/order_customer.csv` | Data mentah, 112.650 baris transaksi level order-item, 4 kolom |
| `processed/order_customer_clean.csv` | Tabel pelanggan hasil agregasi dan penyaringan, 95.420 baris |

Kolom berkas mentah:

| Kolom | Keterangan |
|---|---|
| `order_id` | Identitas order |
| `customer_unique_id` | Identitas pelanggan |
| `order_purchase_timestamp` | Waktu pembelian |
| `price` | Harga item pada baris transaksi, dalam real Brasil (BRL, R$) |

## Variabel model

Tabel hasil agregasi memakai satu baris per `customer_unique_id`.

| Peran | Variabel | Keterangan |
|---|---|---|
| Y | `Monetary_Value` | Penjumlahan `price` per pelanggan, dalam real Brasil (BRL, R$) |
| X1 | `Total_Purchases` | Jumlah `order_id` unik per pelanggan |
| X2 | `Average_Order_Value` | `Monetary_Value` dibagi `Total_Purchases`, dalam real Brasil (BRL, R$) |
| X3 | `Recency_Days` | Selisih hari antara transaksi terakhir pelanggan dan 2018-09-03 |

## Pra-pengolahan

Script `R/analysis.R` mengubah `order_purchase_timestamp` menjadi tanggal, lalu
mengagregasi transaksi per pelanggan. Agregasi menghasilkan 95.420 observasi dari
112.650 baris transaksi dan 98.666 order unik. Penyaringan `NA` pada empat
variabel model tidak membuang baris. Pemeriksaan duplikat setelah itu juga tidak
menemukan baris ganda, sehingga baris final tetap 95.420 dan total baris dibuang
0.

Baris transaksi yang identik tetap dipertahankan saat agregasi karena berkas
mentah tidak memuat identitas produk. Baris tersebut dapat berupa produk berbeda
dengan harga sama pada satu order.

## Satuan dan wilayah

Seluruh nilai uang memakai real Brasil (BRL, R$), mata uang Brasil. Transaksi berasal dari e-commerce Brasil, bukan Indonesia.
