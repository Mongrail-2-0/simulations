#!/bin/bash
# =============================================================================
# run_study2.sh  —  Simulation Study 2, end to end (one command)
# =============================================================================
# Mongrail 2.0 vs the plug-in posterior-mean approach (estimate frequencies
# from sampled counts, then run original Mongrail on them). Produces an AUC
# comparison across all models, sample sizes, and parameter combinations.
#
# PREREQUISITE: run Study 1 FIRST for all combos and all N — this study reads
#   ../simulation_study_1/{individuals,panels/N*,results}/ . Those are working
#   directories (gitignored), so they only exist after Study 1 has been run.
#
#   ../build.sh
#   ../simulation_study_1/run_study1.sh
#   ./run_study2.sh
#
# Smoke test (mirror the Study 1 smoke-test settings exactly):
#   COMBOS="50:5" SAMPLE_SIZES="10 100 1000" N_REPLICATE=5 THREADS=2 ./run_study2.sh
# =============================================================================
set -euo pipefail

read -r -a SAMPLE_SIZES <<< "${SAMPLE_SIZES:-10 100 1000}"
read -r -a COMBOS       <<< "${COMBOS:-1:5 1:15 50:5 50:15}"
N_REPLICATE="${N_REPLICATE:-10000}"
THREADS="${THREADS:-100}"

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DATA="$ROOT/data"
M1="$ROOT/src/mongrail/mongrail"
S1="$ROOT/simulation_study_1"

PM="$HERE/posterior_means"; RES="$HERE/results"; FIG="$HERE/figures"
mkdir -p "$PM" "$RES" "$FIG"

[[ -x "$M1" ]]              || { echo "ERROR: $M1 missing — run ../build.sh first"; exit 1; }
[[ -d "$S1/individuals" ]] || { echo "ERROR: $S1/individuals missing — run run_study1.sh first"; exit 1; }
[[ -d "$S1/results" ]]     || { echo "ERROR: $S1/results missing — run run_study1.sh first"; exit 1; }

for combo in "${COMBOS[@]}"; do
    r="${combo%%:*}"; h="${combo##*:}"
    sp="c20_m10_r${r}_h${h}_au1_hc0.1"
    echo ""; echo "######## Study 2 — combo r=${r}, h=${h} (${sp}) ########"

    for N in "${SAMPLE_SIZES[@]}"; do
        # The .postMean files are NOT tagged by N (named by sim params only) and
        # compute_posterior_means APPENDS. So we MUST clear → compute → infer
        # within each N iteration, never compute all N then infer.
        rm -f "$PM/${sp}.postMeanA_rep"* "$PM/${sp}.postMeanB_rep"*

        "$HERE/compute_posterior_means.sh" \
            "$r" "$h" "$N" "$N_REPLICATE" \
            "$S1/individuals/" "$S1/panels/N${N}/" "$PM/" "$HERE/awk_scripts/"

        "$HERE/run_inference_plugin.sh" \
            "$r" "$h" "$N" "$N_REPLICATE" "$THREADS" \
            "$M1" "$DATA/chrom_files" "$PM/" "$S1/individuals/" "$RES/"
    done
done

# AUC figure is computed once across every combo/N read from both studies.
echo ""; echo "==> Plotting AUC comparison ..."
Rscript "$HERE/plot_auc.R" \
    "$S1/results/" "$RES/" "$DATA/model_specified_10000.txt" \
    "$FIG/auc_comparison.pdf" "$FIG/auc.txt"

echo ""; echo "==> Study 2 done. Figure + table in $FIG/"
