#!/usr/bin/env Rscript
# =============================================================================
# plot_auc.R
# =============================================================================
# Computes AUC (area under ROC curve) for each model (a-f) comparing
# Mongrail 2.0 vs plug-in Mongrail across all parameter combinations.
# Produces a faceted line plot and an AUC summary table.
#
# Usage:
#   Rscript plot_auc.R <m2out_dir> <plugin_dir> <true_model_file> <output_pdf> <output_table>
#
# Arguments:
#   m2out_dir        Directory with Mongrail 2.0 outputs (.m2out_N{10,100,1000})
#   plugin_dir       Directory with plug-in Mongrail outputs (.out_N{10,100,1000})
#   true_model_file  Path to true model labels file
#   output_pdf       Output PDF filename
#   output_table     Output AUC table filename
#
# Expected files in m2out_dir (from Study 1):
#   c20_m10_r{1,50}_h{5,15}_au1_hc0.1.m2out_N{10,100,1000}
#
# Expected files in plugin_dir (from Study 2):
#   c20_m10_r{1,50}_h{5,15}_au1_hc0.1.out_N{10,100,1000}
#
# Example:
#   Rscript plot_auc.R \
#       ../simulation_study_1/results/ \
#       ./results/ \
#       ../data/model_specified_10000.txt \
#       ./figures/auc_comparison.pdf \
#       ./figures/auc.txt
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(pROC)
})

# --- Parse arguments ---
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 5) {
  cat("Usage: Rscript plot_auc.R <m2out_dir> <plugin_dir> <true_model_file> <output_pdf> <output_table>\n")
  quit(status = 1)
}

m2out_dir       <- args[1]
plugin_dir      <- args[2]
true_model_file <- args[3]
output_pdf      <- args[4]
output_table    <- args[5]

# --- Load true model labels ---
true_model <- read.table(true_model_file, header = FALSE)
colnames(true_model) <- "model_name"

# --- Compute AUC across all combinations ---
models       <- c("a", "b", "c", "d", "e", "f")
post_cols    <- c("post_prob_A", "post_prob_B", "post_prob_C",
                  "post_prob_D", "post_prob_E", "post_prob_F")
sample_sizes <- c(10, 100, 1000)
recom_freqs  <- c(1, 50)
hap_counts   <- c(5, 15)

results <- data.frame()

for (h in hap_counts) {
  for (r in recom_freqs) {
    sim_params <- sprintf("c20_m10_r%d_h%d_au1_hc0.1", r, h)

    for (N in sample_sizes) {
      # Load Mongrail 2.0 output (from Study 1)
      m2_file <- file.path(m2out_dir, sprintf("%s.m2out_N%d", sim_params, N))
      pi_file <- file.path(plugin_dir, sprintf("%s.out_N%d", sim_params, N))

      if (!file.exists(m2_file)) { cat("Skipping (not found):", m2_file, "\n"); next }
      if (!file.exists(pi_file)) { cat("Skipping (not found):", pi_file, "\n"); next }

      output_m2 <- read.table(m2_file, header = TRUE)
      output_pi <- read.table(pi_file, header = TRUE)

      for (k in seq_along(models)) {
        binary_label <- factor(ifelse(true_model$model_name == models[k], 1, 0))

        roc_m2 <- roc(binary_label, output_m2[[post_cols[k]]], auc = TRUE, quiet = TRUE)
        roc_pi <- roc(binary_label, output_pi[[post_cols[k]]], auc = TRUE, quiet = TRUE)

        results <- rbind(results, data.frame(
          values_auc  = c(as.numeric(roc_m2$auc), as.numeric(roc_pi$auc)),
          recom_freq  = rep(sprintf("r%d", r), 2),
          method      = c("Mongrail 2.0", "Mongrail"),
          model       = rep(models[k], 2),
          sample_size = rep(sprintf("N%d", N), 2),
          hap_count   = rep(sprintf("h%d", h), 2)
        ))
      }

      cat(sprintf("  Processed: r=%d, h=%d, N=%d\n", r, h, N))
    }
  }
}

# --- Set factor levels ---
results$recom_freq  <- factor(results$recom_freq, levels = c("r1", "r50"))
results$method      <- factor(results$method, levels = c("Mongrail 2.0", "Mongrail"))
results$model       <- factor(results$model, levels = c("a", "b", "c", "d", "e", "f"))
results$sample_size <- factor(results$sample_size, levels = c("N10", "N100", "N1000"))
results$hap_count   <- factor(results$hap_count, levels = c("h15", "h5"))

# --- Plot ---
cat("Generating figure...\n")

figure <- ggplot(results, aes(x = sample_size, y = values_auc,
                               color = method, linetype = recom_freq,
                               group = interaction(method, recom_freq))) +
  geom_line() +
  geom_point() +
  facet_grid(hap_count ~ model,
             labeller = labeller(
               hap_count = c("h15" = "h = 15", "h5" = "h = 5")
             )) +
  labs(y = "Area under the Curve (AUC)", x = "Multinomial sample sizes (N)") +
  scale_x_discrete(labels = c("N10" = "10", "N100" = "100", "N1000" = "1000")) +
  scale_color_discrete(name = "Method") +
  scale_linetype_discrete(name = "R", labels = c("1cM", "50cM")) +
  theme(
    legend.text         = element_text(size = 15),
    legend.title        = element_text(size = 16),
    legend.box          = "vertical",
    legend.title.align  = 0.5,
    legend.background   = element_rect(fill = "darkgray"),
    legend.margin        = margin(0.3, 0.3, 0.3, 0.3, "cm"),
    axis.title          = element_text(size = 18),
    axis.text.x         = element_text(size = 18),
    axis.text.y         = element_text(size = 16),
    strip.text.x        = element_text(size = 16),
    strip.text.y        = element_text(size = 16),
    strip.background    = element_rect(fill = "lightblue")
  )

# --- Save ---
output_pdf_dir <- dirname(output_pdf)
if (!dir.exists(output_pdf_dir)) dir.create(output_pdf_dir, recursive = TRUE)

pdf(output_pdf, width = 14, height = 8)
print(figure)
dev.off()

write.table(results, output_table, quote = FALSE, row.names = FALSE)

cat(sprintf("Figure saved: %s\n", output_pdf))
cat(sprintf("Table saved:  %s\n", output_table))
cat("Done.\n")
