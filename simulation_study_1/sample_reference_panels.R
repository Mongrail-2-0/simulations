#!/usr/bin/env Rscript
# =============================================================================
# sample_reference_panels.R
# =============================================================================
# Generates multinomial-sampled reference panels from population haplotype
# frequency files (.popA / .popB). For each replicate, haplotype counts are
# drawn from Multinomial(N, p) where p is the frequency vector per chromosome.
#
# Usage:
#   Rscript sample_reference_panels.R <pop_file> <sample_size> <n_replicates> <output_dir>
#
# Arguments:
#   pop_file       Path to .popA or .popB file
#   sample_size    Reference panel size N (e.g., 10, 100, 1000)
#   n_replicates   Number of replicates (e.g., 10000)
#   output_dir     Output directory for count files
#
# Output:
#   One file per replicate: <output_dir>/<base>.count{A|B}_rep{i}
#
# Examples:
#   Rscript sample_reference_panels.R ../data/pop_files/c20_m10_h5_au1_hc0.1.popA 10 10000 ./panels/
#   Rscript sample_reference_panels.R ../data/pop_files/c20_m10_h5_au1_hc0.1.popB 100 10000 ./panels/
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  cat("Usage: Rscript sample_reference_panels.R <pop_file> <sample_size> <n_replicates> <output_dir>\n")
  cat("\nArguments:\n")
  cat("  pop_file       Path to .popA or .popB file\n")
  cat("  sample_size    Reference panel size N (e.g., 10, 100, 1000)\n")
  cat("  n_replicates   Number of replicates (e.g., 10000)\n")
  cat("  output_dir     Output directory\n")
  quit(status = 1)
}

pop_file   <- args[1]
N          <- as.integer(args[2])
reps       <- as.integer(args[3])
output_dir <- args[4]

# --- Validate inputs ---
if (!file.exists(pop_file)) stop(paste("File not found:", pop_file))
if (N <= 0) stop("Sample size must be positive")
if (reps <= 0) stop("Number of replicates must be positive")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# --- Determine output naming ---
basename_full <- basename(pop_file)

if (grepl("\\.popA$", basename_full)) {
  base <- sub("\\.popA$", "", basename_full)
  suffix <- "countA"
} else if (grepl("\\.popB$", basename_full)) {
  base <- sub("\\.popB$", "", basename_full)
  suffix <- "countB"
} else {
  stop("Input file must end in .popA or .popB")
}

output_base <- paste(base, suffix, sep = ".")

# --- Read population frequencies ---
input <- read.table(pop_file, header = FALSE)

cat(sprintf("Input:      %s\n", basename_full))
cat(sprintf("Chromosomes: %d, Haplotypes: %d\n", nrow(input), ncol(input) - 1))
cat(sprintf("N = %d, Replicates = %d\n", N, reps))
cat(sprintf("Output dir: %s\n\n", output_dir))

# --- Generate replicates ---
for (i in 1:reps) {
  rep_filename <- file.path(output_dir, paste0(output_base, "_rep", i))

  for (j in 1:nrow(input)) {
    haplotypes <- c()
    hap_frequency <- c()

    for (k in 2:ncol(input)) {
      parts <- unlist(strsplit(input[j, k], split = ":"))
      haplotypes <- c(haplotypes, parts[1])
      hap_frequency <- c(hap_frequency, as.double(parts[2]))
    }

    sampled_counts <- rmultinom(1, N, prob = hap_frequency)

    line <- paste(haplotypes, c(sampled_counts), sep = ":", collapse = "\t")
    cat(input[j, 1], line, file = rep_filename, append = TRUE)
    cat("\n", file = rep_filename, append = TRUE)
  }

  if (i %% 1000 == 0) {
    cat(sprintf("  %d / %d replicates done\n", i, reps))
  }
}

cat("Done.\n")
