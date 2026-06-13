#!/bin/bash
# =============================================================================
# run_all_study1.sh  —  run EVERY parameter combination through Study 1
# =============================================================================
# Sequentially calls run_study1.sh for all four combinations. Each combo runs
# at full speed one after another (no parallel slowdown). This is the single
# "main script" for Study 1; it produces all output files but no figures
# (plot with plot_stacked_barplots.R afterwards).
#
#   ../build.sh
#   ./run_all_study1.sh
#
# Environment overrides (N_REPLICATE, THREADS, SMOKE_N) are passed through to
# run_study1.sh. To run a single combo instead, call:  ./run_study1.sh <r> <h>
# =============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# the four parameter combinations: "recom_freq n_hap"
for combo in "1 5" "1 15" "50 5" "50 15"; do
    "$HERE/run_study1.sh" $combo
done

echo "All Study 1 combinations complete -> $HERE/results/"
