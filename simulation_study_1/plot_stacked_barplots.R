#!/usr/bin/env Rscript
# =============================================================================
# plot_stacked_barplots.R
# =============================================================================
# Generates stacked barplots comparing posterior model probabilities between
# Mongrail 2.0 (at N=10, 100, 1000) and original Mongrail.
#
# Produces two figures per run:
#   1. Backcross (model b) vs F2 (model f)
#   2. Purebred (model d) vs F1 (model c)
#
# Usage:
#   Rscript plot_stacked_barplots.R <results_dir> <sim_params> <true_model_file> <output_pdf> [n_display]
#
# Arguments:
#   results_dir      Directory containing .m2out_N{10,100,1000} and .out files
#   sim_params       Parameter string (e.g., c20_m10_r50_h5_au1_hc0.1)
#   true_model_file  Path to true model labels file (one letter per line: a-f)
#   output_pdf       Output PDF filename
#   n_display        Number of individuals to show per panel (default: 100)
#
# Expected input files in results_dir:
#   <sim_params>.m2out_N10      Mongrail 2.0 output, N=10
#   <sim_params>.m2out_N100     Mongrail 2.0 output, N=100
#   <sim_params>.m2out_N1000    Mongrail 2.0 output, N=1000
#   <sim_params>.out            Original Mongrail output
#
# Example:
#   Rscript plot_stacked_barplots.R ./results/ c20_m10_r50_h5_au1_hc0.1 \
#       ../data/model_specified_10000.txt ./figures/barplots_r50_h5.pdf
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggh4x)
  library(RColorBrewer)
  library(reshape)
  library(ggpubr)
})

# --- Parse arguments ---
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  cat("Usage: Rscript plot_stacked_barplots.R <results_dir> <sim_params> <true_model_file> <output_pdf> [n_display]\n")
  cat("\nExample:\n")
  cat("  Rscript plot_stacked_barplots.R ./results/ c20_m10_r50_h5_au1_hc0.1 \\\n")
  cat("      ../data/model_specified_10000.txt ./figures/barplots_r50_h5.pdf\n")
  quit(status = 1)
}

results_dir    <- args[1]
sim_params     <- args[2]
true_model_file <- args[3]
output_pdf     <- args[4]
n_display      <- ifelse(length(args) >= 5, as.integer(args[5]), 100)

# --- Build input file paths ---
m2out_N10_file   <- file.path(results_dir, paste0(sim_params, ".m2out_N10"))
m2out_N100_file  <- file.path(results_dir, paste0(sim_params, ".m2out_N100"))
m2out_N1000_file <- file.path(results_dir, paste0(sim_params, ".m2out_N1000"))
mongrail_file    <- file.path(results_dir, paste0(sim_params, ".out"))

# --- Verify files exist ---
for (f in c(m2out_N10_file, m2out_N100_file, m2out_N1000_file, mongrail_file, true_model_file)) {
  if (!file.exists(f)) stop(paste("File not found:", f))
}

# --- Helper: extract and reshape posterior probabilities ---
extract_posteriors <- function(output_df, true_labels, target_model, n_show) {
  subset_df <- subset.data.frame(output_df, true_labels == target_model, select = seq(7, 12))
  colnames(subset_df) <- c("A", "B", "C", "D", "E", "F")
  n_available <- min(n_show, nrow(subset_df))
  melted <- melt(t(subset_df[1:n_available, ]))
  colnames(melted) <- c("Model", "indv_id", "posterior_prob")
  melted$indv_id <- as.factor(melted$indv_id)
  return(melted)
}

# --- Load data ---
cat(sprintf("Loading data for %s...\n", sim_params))

output_m2_N10   <- read.table(m2out_N10_file, header = TRUE)
output_m2_N100  <- read.table(m2out_N100_file, header = TRUE)
output_m2_N1000 <- read.table(m2out_N1000_file, header = TRUE)
output_mongrail <- read.table(mongrail_file, header = TRUE)
true_model      <- read.table(true_model_file, header = FALSE)

# --- Build panel for a given target model ---
method_labels <- c("Mongrail.2.0 (N=10)", "Mongrail.2.0 (N=100)",
                    "Mongrail.2.0 (N=1000)", "Mongrail")
n_per_method <- n_display * 6  # 6 models × n_display individuals

build_panel <- function(target_model) {
  d1 <- extract_posteriors(output_m2_N10,   true_model$V1, target_model, n_display)
  d2 <- extract_posteriors(output_m2_N100,  true_model$V1, target_model, n_display)
  d3 <- extract_posteriors(output_m2_N1000, true_model$V1, target_model, n_display)
  d4 <- extract_posteriors(output_mongrail, true_model$V1, target_model, n_display)

  merged <- rbind.data.frame(d1, d2, d3, d4)
  merged$method <- factor(
    rep(method_labels, each = n_per_method),
    levels = method_labels
  )
  return(merged)
}

# --- Plotting function ---
make_stacked_plot <- function(plot_data) {
  p <- ggplot(plot_data, aes(fill = Model, y = posterior_prob, x = indv_id)) +
    geom_bar(position = "fill", stat = "identity") +
    scale_fill_brewer(palette = "Set1", name = "Models",
                      labels = c("a", "b", "c", "d", "e", "f")) +
    facet_grid(method ~ gc, scales = "free_x", space = "free_x") +
    labs(y = "Posterior Probability", x = "Individuals") +
    theme(
      axis.text.x         = element_blank(),
      axis.ticks.x         = element_blank(),
      axis.text.y          = element_text(size = 15, family = "sans"),
      axis.title           = element_text(size = 18, family = "sans"),
      axis.title.y         = element_text(margin = margin(t = 0, r = 12, b = 0, l = 0)),
      axis.title.x         = element_text(margin = margin(t = 10, r = 0, b = 0, l = 0)),
      strip.text.x         = element_text(size = 14),
      strip.text.y         = element_text(size = 14),
      legend.position      = "right",
      legend.box           = "vertical",
      legend.text          = element_text(size = 18, family = "sans"),
      legend.title         = element_text(size = 18, family = "sans"),
      legend.title.align   = 0.5,
      legend.background    = element_rect(fill = "darkgray"),
      legend.margin        = margin(0.5, 0.5, 0.5, 0.5, "cm")
    )
  return(p)
}

# --- Figure 1: Backcross (b) vs F2 (f) ---
cat("Building Figure 1: Backcross (b) vs F2 (f)...\n")

merged_B <- build_panel("b")
merged_F <- build_panel("f")

all_b_f <- rbind.data.frame(merged_B, merged_F)
all_b_f$gc <- factor(
  rep(c("Backcross (model b)", "F2 (model f)"), each = nrow(merged_B)),
  levels = c("Backcross (model b)", "F2 (model f)")
)

# --- Figure 2: Purebred (d) vs F1 (c) ---
cat("Building Figure 2: Purebred (d) vs F1 (c)...\n")

merged_D <- build_panel("d")
merged_C <- build_panel("c")

all_d_c <- rbind.data.frame(merged_D, merged_C)
all_d_c$gc <- factor(
  rep(c("Purebred (model d)", "F1 (model c)"), each = nrow(merged_D)),
  levels = c("Purebred (model d)", "F1 (model c)")
)

# --- Save ---
cat(sprintf("Saving to %s...\n", output_pdf))

output_pdf_dir <- dirname(output_pdf)
if (!dir.exists(output_pdf_dir)) dir.create(output_pdf_dir, recursive = TRUE)

pdf(output_pdf, width = 14, height = 10)
print(make_stacked_plot(all_b_f))
print(make_stacked_plot(all_d_c))
dev.off()

cat("Done.\n")
