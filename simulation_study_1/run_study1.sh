#!/bin/bash
# =============================================================================
# run_study1.sh  —  Simulation Study 1, end to end (one command)
# =============================================================================
# Mongrail 2.0 (sampled panels, N = 10/100/1000) vs original Mongrail (known
# frequencies). Runs every parameter combination and every sample size, then
# produces the stacked-barplot figures.
#
#   ../build.sh          # build the binaries first (once)
#   ./run_study1.sh      # then run this
#
# Override any setting from the environment, e.g. a fast smoke test:
#   COMBOS="50:5" SAMPLE_SIZES="10 100 1000" N_REPLICATE=5 THREADS=2 \
#       N_DISPLAY=5 ./run_study1.sh
#
# NOTE: the figure step requires all three N (the plot script hard-codes
#       .m2out_N10/_N100/_N1000), so keep all three in SAMPLE_SIZES if you
#       want a PDF out of a smoke test.
# =============================================================================
set -euo pipefail

# --- Config (all overridable via environment) ---
read -r -a SAMPLE_SIZES <<< "${SAMPLE_SIZES:-10 100 1000}"
read -r -a COMBOS       <<< "${COMBOS:-1:5 1:15 50:5 50:15}"   # "recom:n_hap"
N_REPLICATE="${N_REPLICATE:-10000}"
THREADS="${THREADS:-100}"
N_DISPLAY="${N_DISPLAY:-100}"

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DATA="$ROOT/data"
M1="$ROOT/src/mongrail/mongrail"
M2="$ROOT/src/mongrail2/mongrail2"

PANELS="$HERE/panels"; INDV="$HERE/individuals"; RES="$HERE/results"; FIG="$HERE/figures"
mkdir -p "$INDV" "$RES" "$FIG"

[[ -x "$M1" ]] || { echo "ERROR: $M1 missing — run ../build.sh first"; exit 1; }
[[ -x "$M2" ]] || { echo "ERROR: $M2 missing — run ../build.sh first"; exit 1; }

for combo in "${COMBOS[@]}"; do
    r="${combo%%:*}"; h="${combo##*:}"
    sp="c20_m10_r${r}_h${h}_au1_hc0.1"
    pop="c20_m10_h${h}_au1_hc0.1"
    echo ""; echo "######## Study 1 — combo r=${r}, h=${h} (${sp}) ########"

    # 1) Split the simulated individuals (independent of N)
    "$HERE/split_individuals.sh" "$DATA/sim_files/${sp}.sim" "$INDV/"

    # 2) Mongrail1 BASELINE → .out  (this is the step the README was missing)
    "$HERE/run_inference_known_freqs.sh" \
        "$r" "$h" "$N_REPLICATE" "$THREADS" \
        "$M1" "$DATA/chrom_files" "$DATA/pop_files" "$INDV/" "$RES/"

    # 3) Mongrail 2.0 across every sample size
    for N in "${SAMPLE_SIZES[@]}"; do
        pdir="$PANELS/N${N}"; mkdir -p "$pdir"
        # IMPORTANT: the panel sampler APPENDS. Clear this combo's count files
        # first so re-runs (and combos that share the same h) don't corrupt them.
        rm -f "$pdir/${pop}.countA_rep"* "$pdir/${pop}.countB_rep"*

        Rscript "$HERE/sample_reference_panels.R" "$DATA/pop_files/${pop}.popA" "$N" "$N_REPLICATE" "$pdir/"
        Rscript "$HERE/sample_reference_panels.R" "$DATA/pop_files/${pop}.popB" "$N" "$N_REPLICATE" "$pdir/"

        "$HERE/run_inference.sh" \
            "$r" "$h" "$N" "$N_REPLICATE" "$THREADS" \
            "$M2" "$DATA/chrom_files" "$pdir/" "$INDV/" "$RES/"
    done

    # 4) Figure
    Rscript "$HERE/plot_stacked_barplots.R" \
        "$RES/" "$sp" "$DATA/model_specified_10000.txt" \
        "$FIG/barplots_r${r}_h${h}.pdf" "$N_DISPLAY"
done

echo ""; echo "==> Study 1 done. Figures in $FIG/"
