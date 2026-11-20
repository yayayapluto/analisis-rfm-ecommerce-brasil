suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(car))
suppressPackageStartupMessages(library(lmtest))

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/plots", recursive = TRUE, showWarnings = FALSE)

log_file <- file("output/analisis_log.txt", open = "wt")
sink(log_file, split = TRUE)

cat("Analisis regresi data pesanan e-commerce Brasil\n")
cat("Sumber data: data/raw/order_customer.csv\n")
cat("Data mentah berupa transaksi level order-item, lalu diagregasi per pelanggan.\n")
cat("Seluruh nilai memakai satuan dataset tanpa simbol mata uang.\n\n")

data_order <- read.csv(
  "data/raw/order_customer.csv",
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)

kolom_wajib <- c(
  "order_id",
  "customer_unique_id",
  "order_purchase_timestamp",
  "price"
)
kolom_hilang <- setdiff(kolom_wajib, names(data_order))
if (length(kolom_hilang) > 0) {
  stop("Kolom wajib tidak ditemukan: ", paste(kolom_hilang, collapse = ", "))
}

data_order$tanggal <- as.Date(data_order$order_purchase_timestamp)
tanggal_referensi <- max(data_order$tanggal)

cat("Baris transaksi order-item:", nrow(data_order), "\n")
cat("Order unik:", length(unique(data_order$order_id)), "\n")
cat("Pelanggan unik:", length(unique(data_order$customer_unique_id)), "\n")
cat(
  "Rentang transaksi:",
  format(min(data_order$tanggal)),
  "sampai",
  format(tanggal_referensi),
  "\n"
)
cat("Tanggal referensi recency:", format(tanggal_referensi), "\n")

id_pelanggan <- sort(unique(data_order$customer_unique_id))
total_pembelian <- unname(as.integer(tapply(
  data_order$order_id,
  data_order$customer_unique_id,
  function(x) length(unique(x))
)))
penerimaan_total <- unname(as.numeric(tapply(
  data_order$price,
  data_order$customer_unique_id,
  sum
)))
tanggal_terakhir <- as.Date(
  unname(tapply(data_order$tanggal, data_order$customer_unique_id, max)),
  origin = "1970-01-01"
)
recency_hari <- unname(as.numeric(tanggal_referensi - tanggal_terakhir))

data_mentah <- data.frame(
  customer_unique_id = id_pelanggan,
  Monetary_Value = penerimaan_total,
  Total_Purchases = total_pembelian,
  Average_Order_Value = penerimaan_total / total_pembelian,
  Recency_Days = recency_hari,
  stringsAsFactors = FALSE
)

kolom_model <- c(
  "Monetary_Value",
  "Total_Purchases",
  "Average_Order_Value",
  "Recency_Days"
)

kolom_hilang <- setdiff(kolom_model, names(data_mentah))
if (length(kolom_hilang) > 0) {
  stop("Kolom wajib tidak ditemukan: ", paste(kolom_hilang, collapse = ", "))
}

baris_awal <- nrow(data_mentah)
cat("Baris awal:", baris_awal, "\n")

ke_numerik <- function(x) {
  if (is.numeric(x)) {
    x
  } else {
    suppressWarnings(as.numeric(as.character(x)))
  }
}

data_mentah[kolom_model] <- lapply(data_mentah[kolom_model], ke_numerik)

na_model <- vapply(
  data_mentah[kolom_model],
  function(x) sum(is.na(x)),
  integer(1)
)
cat("\nJumlah NA pada variabel model sebelum penyaringan:\n")
print(na_model)

baris_lengkap <- stats::complete.cases(data_mentah[, kolom_model, drop = FALSE])
data_setelah_na <- data_mentah[baris_lengkap, , drop = FALSE]
rownames(data_setelah_na) <- NULL

baris_na <- baris_awal - nrow(data_setelah_na)
cat("\nBaris setelah complete.cases:", nrow(data_setelah_na), "\n")
cat("Baris dibuang karena NA pada variabel model:", baris_na, "\n")

baris_duplikat <- sum(duplicated(data_setelah_na))
data_bersih <- data_setelah_na[!duplicated(data_setelah_na), , drop = FALSE]
rownames(data_bersih) <- NULL

baris_final <- nrow(data_bersih)
baris_dibuang <- baris_awal - baris_final

cat("Baris duplikat dibuang:", baris_duplikat, "\n")
cat("Baris final:", baris_final, "\n")
cat("Total baris dibuang:", baris_dibuang, "\n")

if (baris_final == 0) {
  stop("Tidak ada baris lengkap pada variabel model.")
}

write.csv(
  data_bersih,
  "data/processed/order_customer_clean.csv",
  row.names = FALSE
)
cat("Tersimpan: data/processed/order_customer_clean.csv\n")

cat("\nStatistika deskriptif\n")

modus_manual <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA_real_)
  }
  tabel <- table(x)
  as.numeric(names(tabel)[which.max(tabel)])
}

statistik_satu <- function(x, nama) {
  x <- x[!is.na(x)]
  kuartil <- stats::quantile(
    x,
    probs = c(0.25, 0.5, 0.75),
    na.rm = TRUE,
    names = FALSE
  )
  data.frame(
    variabel = nama,
    n = length(x),
    mean = mean(x),
    median = stats::median(x),
    modus = modus_manual(x),
    varians = stats::var(x),
    sd = stats::sd(x),
    min = min(x),
    q1 = kuartil[1],
    q2 = kuartil[2],
    q3 = kuartil[3],
    max = max(x),
    stringsAsFactors = FALSE
  )
}

deskriptif <- do.call(
  rbind,
  lapply(kolom_model, function(v) statistik_satu(data_bersih[[v]], v))
)
rownames(deskriptif) <- NULL

deskriptif_tampil <- deskriptif
kolom_dibulatkan <- setdiff(names(deskriptif), c("variabel", "n"))
deskriptif_tampil[kolom_dibulatkan] <- lapply(
  deskriptif_tampil[kolom_dibulatkan],
  round,
  3
)
print(deskriptif_tampil, row.names = FALSE)

write.csv(
  deskriptif,
  "output/tables/statistik_deskriptif.csv",
  row.names = FALSE
)
cat("Tersimpan: output/tables/statistik_deskriptif.csv\n")

cat("\nKorelasi Pearson\n")
matriks_korelasi <- stats::cor(
  data_bersih[, kolom_model, drop = FALSE],
  use = "complete.obs",
  method = "pearson"
)
print(round(matriks_korelasi, 4))
write.csv(matriks_korelasi, "output/tables/korelasi.csv", row.names = TRUE)
cat("Tersimpan: output/tables/korelasi.csv\n")

cat("\nScatter plot\n")
pasangan_scatter <- list(
  list(
    x = "Total_Purchases",
    file = "scatter_purchases_y.png",
    judul = "Total Purchases dan Monetary Value",
    label = "Total Purchases (X1)"
  ),
  list(
    x = "Average_Order_Value",
    file = "scatter_order_value_y.png",
    judul = "Average Order Value dan Monetary Value",
    label = "Average Order Value (X2)"
  ),
  list(
    x = "Recency_Days",
    file = "scatter_recency_y.png",
    judul = "Recency Days dan Monetary Value",
    label = "Recency Days (X3)"
  )
)

for (p in pasangan_scatter) {
  plot_scatter <- ggplot(
    data_bersih,
    aes(x = .data[[p$x]], y = .data[["Monetary_Value"]])
  ) +
    geom_point(alpha = 0.2, size = 0.6, colour = "#2C6E8F") +
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      se = FALSE,
      colour = "#C0392B",
      linewidth = 0.8
    ) +
    labs(
      title = p$judul,
      x = p$label,
      y = "Monetary Value (Y)"
    ) +
    theme_minimal(base_size = 11)

  ggsave(
    file.path("output/plots", p$file),
    plot_scatter,
    width = 8,
    height = 5.5,
    dpi = 120
  )
  cat("Tersimpan: output/plots/", p$file, "\n", sep = "")
}

cat("\nRegresi linear sederhana\n")
model_sederhana <- lm(
  Monetary_Value ~ Total_Purchases,
  data = data_bersih
)
ringkasan_sederhana <- capture.output(print(summary(model_sederhana)))
cat(ringkasan_sederhana, sep = "\n")
cat("\n")
writeLines(
  c(
    "REGRESI LINEAR SEDERHANA",
    "Formula: Monetary_Value ~ Total_Purchases",
    "",
    ringkasan_sederhana
  ),
  "output/tables/regresi_sederhana.txt"
)
cat("Tersimpan: output/tables/regresi_sederhana.txt\n")

cat("\nRegresi linear berganda\n")
model_berganda <- lm(
  Monetary_Value ~ Total_Purchases + Average_Order_Value + Recency_Days,
  data = data_bersih
)
ringkasan_berganda <- capture.output(print(summary(model_berganda)))
cat(ringkasan_berganda, sep = "\n")
cat("\n")
writeLines(
  c(
    "REGRESI LINEAR BERGANDA",
    "Formula: Monetary_Value ~ Total_Purchases + Average_Order_Value + Recency_Days",
    "",
    ringkasan_berganda
  ),
  "output/tables/regresi_berganda.txt"
)
cat("Tersimpan: output/tables/regresi_berganda.txt\n")

r2_berganda <- summary(model_berganda)$r.squared
r2_adjusted <- summary(model_berganda)$adj.r.squared
cat(sprintf("R-squared model berganda: %.6f\n", r2_berganda))
cat(sprintf("R-squared adjusted model berganda: %.6f\n", r2_adjusted))

cat("\nUji asumsi\n")
nilai_vif <- car::vif(model_berganda)
teks_vif <- capture.output(print(nilai_vif))
cat("Multikolinearitas dengan VIF:\n")
cat(teks_vif, sep = "\n")
cat("\n")

residu <- stats::residuals(model_berganda)
set.seed(123)
ukuran_shapiro <- min(5000L, length(residu))
sampel_residu <- sample(residu, size = ukuran_shapiro, replace = FALSE)
uji_normal <- stats::shapiro.test(sampel_residu)
teks_normal <- capture.output(print(uji_normal))
cat("Normalitas residual dengan Shapiro-Wilk:\n")
cat("Ukuran sampel:", ukuran_shapiro, "\n")
cat(teks_normal, sep = "\n")
cat("\n")

uji_hetero <- lmtest::bptest(model_berganda)
teks_hetero <- capture.output(print(uji_hetero))
cat("Heteroskedastisitas dengan Breusch-Pagan:\n")
cat(teks_hetero, sep = "\n")
cat("\n")

writeLines(
  c(
    "UJI ASUMSI MODEL REGRESI BERGANDA",
    "",
    "Multikolinearitas dengan VIF:",
    teks_vif,
    "",
    paste(
      "Normalitas residual dengan Shapiro-Wilk, sampel acak n =",
      ukuran_shapiro,
      ":"
    ),
    teks_normal,
    "",
    "Heteroskedastisitas dengan Breusch-Pagan:",
    teks_hetero
  ),
  "output/tables/uji_asumsi.txt"
)
cat("Tersimpan: output/tables/uji_asumsi.txt\n")

cat("\nPrediksi tiga skenario\n")
kuantil_x1 <- stats::quantile(
  data_bersih$Total_Purchases,
  probs = c(0.25, 0.5, 0.75),
  names = FALSE
)
kuantil_x2 <- stats::quantile(
  data_bersih$Average_Order_Value,
  probs = c(0.25, 0.5, 0.75),
  names = FALSE
)
kuantil_x3 <- stats::quantile(
  data_bersih$Recency_Days,
  probs = c(0.25, 0.5, 0.75),
  names = FALSE
)

data_skenario <- data.frame(
  Total_Purchases = kuantil_x1,
  Average_Order_Value = kuantil_x2,
  Recency_Days = kuantil_x3
)
prediksi <- stats::predict(
  model_berganda,
  newdata = data_skenario,
  interval = "confidence",
  level = 0.95
)
tabel_prediksi <- data.frame(
  skenario = c("Rendah", "Menengah", "Tinggi"),
  total_purchases = data_skenario$Total_Purchases,
  average_order_value = data_skenario$Average_Order_Value,
  recency_days = data_skenario$Recency_Days,
  prediksi = prediksi[, "fit"],
  batas_bawah_95 = prediksi[, "lwr"],
  batas_atas_95 = prediksi[, "upr"],
  stringsAsFactors = FALSE
)
print(tabel_prediksi, row.names = FALSE)
write.csv(
  tabel_prediksi,
  "output/tables/prediksi.csv",
  row.names = FALSE
)
cat("Tersimpan: output/tables/prediksi.csv\n")

cat("\nPlot tambahan\n")
plot_hist <- ggplot(data_bersih, aes(x = Monetary_Value)) +
  geom_histogram(
    bins = 60,
    fill = "#2C6E8F",
    colour = "white",
    linewidth = 0.2
  ) +
  labs(
    title = "Distribusi Monetary Value",
    x = "Monetary Value (Y)",
    y = "Frekuensi"
  ) +
  theme_minimal(base_size = 11)
ggsave(
  "output/plots/hist_y.png",
  plot_hist,
  width = 8,
  height = 5.5,
  dpi = 120
)
cat("Tersimpan: output/plots/hist_y.png\n")

plot_box <- ggplot(data_bersih, aes(y = Monetary_Value)) +
  geom_boxplot(
    fill = "#A8C6D4",
    outlier.colour = "#C0392B",
    outlier.size = 0.7
  ) +
  labs(
    title = "Boxplot Monetary Value",
    y = "Monetary Value (Y)"
  ) +
  theme_minimal(base_size = 11)
ggsave(
  "output/plots/box_y.png",
  plot_box,
  width = 5,
  height = 6,
  dpi = 120
)
cat("Tersimpan: output/plots/box_y.png\n")

plot_residual <- ggplot(
  data.frame(
    fitted = stats::fitted(model_berganda),
    residual = residu
  ),
  aes(x = fitted, y = residual)
) +
  geom_point(alpha = 0.2, size = 0.6, colour = "#2C6E8F") +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    colour = "#C0392B"
  ) +
  labs(
    title = "Residual dan Nilai Fitted",
    x = "Nilai fitted",
    y = "Residual"
  ) +
  theme_minimal(base_size = 11)
ggsave(
  "output/plots/residual_vs_fitted.png",
  plot_residual,
  width = 8,
  height = 5.5,
  dpi = 120
)
cat("Tersimpan: output/plots/residual_vs_fitted.png\n")

png("output/plots/qq_plot.png", width = 1600, height = 1200, res = 200)
stats::qqnorm(residu, main = "QQ-Plot Residual Model Berganda")
stats::qqline(residu, col = "#C0392B", lwd = 1.5)
dev.off()
cat("Tersimpan: output/plots/qq_plot.png\n")

cat("\nRingkasan akhir\n")
cat("Baris awal:", baris_awal, "\n")
cat("Baris setelah complete.cases:", nrow(data_setelah_na), "\n")
cat("Baris dibuang karena NA:", baris_na, "\n")
cat("Baris duplikat dibuang:", baris_duplikat, "\n")
cat("Baris final:", baris_final, "\n")
cat("Total baris dibuang:", baris_dibuang, "\n")
cat(sprintf("R-squared model berganda: %.6f\n", r2_berganda))
cat("Analisis selesai.\n")

sink()
close(log_file)