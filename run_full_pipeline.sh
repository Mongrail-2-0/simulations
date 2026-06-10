#!/bin/bash
# =============================================================================
# run_full_pipeline.sh
# =============================================================================
# Master script that runs both simulation studies end-to-end for all
# parameter combinations. Reproduces all figures from the paper.
#
# Usage:
#   ./run_full_pipeline.sh
#
# Prerequisites:
#   - Compiled mongrail and mongrail2 binaries (run make in src/)
#   - R with required packages (see README.md)
#
# Estimated runtime:
#   Several hours on a multi-core machine (10,000 replicates × 4 combos)
# =============================================================================

set -euo pipefail

# ==========================
# CONFIGURATION
# ==========================
N_REPLICATE=10000
THREADS=100
SAMPLE_SIZES=(10 100 1000)
RECOM_FREQS=(1 50)
HAP_COUNTS=(5 15)

# --- Paths (relative to repo root) ---
MONGRAIL_BIN="./src/mongrail/mongrail"
MONGRAIL2_BIN="./src/mongrail2/mongrail2"
DATA_DIR="./data"
CHROM_DIR="${DATA_DIR}/chrom_files"
POP_DIR="${DATA_DIR}/pop_files"
SIM_DIR="${DATA_DIR}/sim_files"
TRUE_MODEL="${DATA_DIR}/model_specified_10000.txt"

# --- Working directories (created during pipeline) ---
WORK_DIR="./work"
PANELS_DIR="${WORK_DIR}/panels"
INDV_DIR="${WORK_DIR}/individuals"
POSTMEAN_DIR="${WORK_DIR}/posterior_means"

# --- Output directories ---
RESULTS_S1="${WORK_DIR}/results_study1"
RESULTS_S2="${WORK_DIR}/results_study2"
FIGURES_DIR="./figures"

# --- Script directories ---
S1_DIR="./simulation_study_1"
S2_DIR="./simulation_study_2"

echo "============================================================"
echo "  Mongrail 2.0 — Full Simulation Pipeline"
echo "============================================================"
echo "  Replicates:    ${N_REPLICATE}"
echo "  Threads:       ${THREADS}"
echo "  Sample sizes:  ${SAMPLE_SIZES[*]}"
echo "  Recom freqs:   ${RECOM_FREQS[*]}"
echo "  Haplotypes:    ${HAP_COUNTS[*]}"
echo "============================================================"
echo ""

# --- Verify binaries exist ---
if [[ ! -x "${MONGRAIL_BIN}" ]]; then
    echo "Error: mongrail binary not found at ${MONGRAIL_BIN}"
    echo "Run: cd src/mongrail && make"
    exit 1
fi

if [[ ! -x "${MONGRAIL2_BIN}" ]]; then
    echo "Error: mongrail2 binary not found at ${MONGRAIL2_BIN}"
    echo "Run: cd src/mongrail2 && make"
    exit 1
fi

mkdir -p "${FIGURES_DIR}"

# =============================================================
#  SIMULATION STUDY 1
# =============================================================
echo ""
echo "############################################################"
echo "  SIMULATION STUDY 1: Mongrail 2.0 vs Original Mongrail"
echo "############################################################"
echo ""

for h in "${HAP_COUNTS[@]}"; do
    for r in "${RECOM_FREQS[@]}"; do

        pop_params="c20_m10_h${h}_au1_hc0.1"
        sim_params="c20_m10_r${r}_h${h}_au1_hc0.1"
        sim_file="${SIM_DIR}/${sim_params}.sim"

        echo "=== Processing: r=${r}, h=${h} (${sim_params}) ==="
        echo ""

        # --- Step 1: Generate multinomial-sampled reference panels ---
        echo "--- Step 1: Sampling reference panels ---"
        for N in "${SAMPLE_SIZES[@]}"; do
            panel_subdir="${PANELS_DIR}/N${N}"
            mkdir -p "${panel_subdir}"

            echo "  popA, N=${N}..."
            Rscript "${S1_DIR}/sample_reference_panels.R" \
                "${POP_DIR}/${pop_params}.popA" ${N} ${N_REPLICATE} "${panel_subdir}"

            echo "  popB, N=${N}..."
            Rscript "${S1_DIR}/sample_reference_panels.R" \
                "${POP_DIR}/${pop_params}.popB" ${N} ${N_REPLICATE} "${panel_subdir}"
        done

        # --- Step 2: Split simulated individuals ---
        echo "--- Step 2: Splitting individuals ---"
        indv_subdir="${INDV_DIR}/r${r}_h${h}"
        bash "${S1_DIR}/split_individuals.sh" "${sim_file}" "${indv_subdir}"

        # --- Step 3: Run Mongrail 2.0 inference for each N ---
        echo "--- Step 3: Running Mongrail 2.0 ---"
        mkdir -p "${RESULTS_S1}"
        for N in "${SAMPLE_SIZES[@]}"; do
            echo "  N=${N}..."
            bash "${S1_DIR}/run_inference.sh" \
                ${r} ${h} ${N} ${N_REPLICATE} ${THREADS} \
                "${MONGRAIL2_BIN}" "${CHROM_DIR}" \
                "${PANELS_DIR}/N${N}" "${indv_subdir}" "${RESULTS_S1}"
        done

        # --- Step 4: Run original Mongrail with known frequencies ---
        echo "--- Step 4: Running Mongrail (known frequencies) ---"
        bash "${S1_DIR}/run_inference_known_freqs.sh" \
            ${r} ${h} ${N_REPLICATE} ${THREADS} \
            "${MONGRAIL_BIN}" "${CHROM_DIR}" "${POP_DIR}" \
            "${indv_subdir}" "${RESULTS_S1}"

        # --- Step 5: Generate stacked barplots ---
        echo "--- Step 5: Generating stacked barplots ---"
        Rscript "${S1_DIR}/plot_stacked_barplots.R" \
            "${RESULTS_S1}" "${sim_params}" "${TRUE_MODEL}" \
            "${FIGURES_DIR}/barplots_r${r}_h${h}.pdf"

        echo ""
    done
done

# =============================================================
#  SIMULATION STUDY 2
# =============================================================
echo ""
echo "############################################################"
echo "  SIMULATION STUDY 2: Mongrail 2.0 vs Plug-in Posterior Mean"
echo "############################################################"
echo ""

for h in "${HAP_COUNTS[@]}"; do
    for r in "${RECOM_FREQS[@]}"; do

        sim_params="c20_m10_r${r}_h${h}_au1_hc0.1"
        indv_subdir="${INDV_DIR}/r${r}_h${h}"

        echo "=== Processing: r=${r}, h=${h} (${sim_params}) ==="
        echo ""

        for N in "${SAMPLE_SIZES[@]}"; do
            pm_subdir="${POSTMEAN_DIR}/N${N}_r${r}_h${h}"

            # --- Step 1: Compute posterior means ---
            echo "--- Step 1: Computing posterior means (N=${N}) ---"
            bash "${S2_DIR}/compute_posterior_means.sh" \
                ${r} ${h} ${N} ${N_REPLICATE} \
                "${indv_subdir}" "${PANELS_DIR}/N${N}" \
                "${pm_subdir}" "${S2_DIR}/awk_scripts"

            # --- Step 2: Run Mongrail on posterior means ---
            echo "--- Step 2: Running Mongrail on posterior means (N=${N}) ---"
            mkdir -p "${RESULTS_S2}"
            bash "${S2_DIR}/run_inference_plugin.sh" \
                ${r} ${h} ${N} ${N_REPLICATE} ${THREADS} \
                "${MONGRAIL_BIN}" "${CHROM_DIR}" \
                "${pm_subdir}" "${indv_subdir}" "${RESULTS_S2}"
        done

        echo ""
    done
done

# --- Step 3: Generate AUC comparison figure ---
echo "--- Generating AUC comparison figure ---"
Rscript "${S2_DIR}/plot_auc.R" \
    "${RESULTS_S1}" "${RESULTS_S2}" "${TRUE_MODEL}" \
    "${FIGURES_DIR}/auc_comparison.pdf" \
    "${FIGURES_DIR}/auc.txt"

echo ""
echo "============================================================"
echo "  Pipeline complete!"
echo "============================================================"
echo "  Figures saved in: ${FIGURES_DIR}/"
echo "============================================================"
