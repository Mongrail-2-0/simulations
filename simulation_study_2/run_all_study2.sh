#!/bin/bash
# =============================================================================
# run_all_study2.sh  —  run EVERY parameter combination through Study 2
# =============================================================================
# Sequentially calls run_study2.sh for all four combinations. Requires Study 1
# to have been run first (for all combos and all N). Produces the plug-in
# output files but no figure; plot once afterwards with plot_auc.R.
#
#   ../build.sh
#   ../simulation_study_1/run_all_study1.sh
#   ./run_all_study2.sh
#
# Environment overrides (N_REPLICATE, THREADS, SMOKE_N) pass through.
# =============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

for combo in "1 5" "1 15" "50 5" "50 15"; do
    "$HERE/run_study2.sh" $combo
done

echo "All Study 2 combinations complete -> $HERE/results/"
echo "Next: Rscript plot_auc.R (once, across all combos)"
