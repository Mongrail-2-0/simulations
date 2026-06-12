# Simulation Study 2: Mongrail 2.0 vs Plug-in Posterior Mean

Compares Mongrail 2.0 against a "plug-in" approach: compute posterior mean haplotype
frequencies from the sampled counts, then run the original Mongrail using those
estimated frequencies as if they were known. The comparison is quantified using AUC
across all six hybridization models.

> **Prerequisite — run Study 1 first, for all combos and all N.** This study reads
> Study 1's working directories (`../simulation_study_1/individuals/` and
> `../simulation_study_1/panels/N{10,100,1000}/`), and the plot reads
> `../simulation_study_1/results/` (`.m2out_N*`). The run scripts check for these and
> exit early if they're missing.

## Run

```bash
../build.sh                              # once, from the repo root
../simulation_study_1/run_all_study1.sh  # Study 1 must run first

./run_all_study2.sh         # all 4 combos × N=10,100,1000
# or one combo at a time:
./run_study2.sh <recom_freq> <n_hap>     # e.g. ./run_study2.sh 50 5
```

This produces the **output files** in `results/` — it does *not* make the figure (see
[Plotting](#plotting-separate-step)). Optional env overrides: `N_REPLICATE`
(default 10000), `THREADS` (default 100).

Output per combo, in `results/`: `<combo>.out_N10`, `_N100`, `_N1000`
(plug-in Mongrail).

## What it does

For each N, `run_study2.sh` clears the (non-N-tagged, append-built) posterior-mean
files, then computes them and runs inference before moving to the next N:

```
count files ─→ [compute_posterior_means.sh] ─→ .postMeanA / .postMeanB
 (from Study 1)         │  (awk_scripts/, transpose.sh)        │
                        │                                      ↓
                        │                       [run_inference_plugin.sh] ─→ .out_N{10,100,1000}
                 chrom files, mongrail
```

1. **Posterior means** — `compute_posterior_means.sh`, for each replicate: extract the
   individual's haplotypes, take the union of unique haplotypes across popA/popB/the
   individual, and compute `(count + 1/K) / (N + 1)` (K = number of unique haplotypes).
2. **Plug-in inference** — `run_inference_plugin.sh` runs original Mongrail on those
   posterior-mean frequencies → `<combo>.out_N{N}`.

## Plotting (separate step)

The AUC figure is made **once, across all combos**, after both studies' inference is
done (needs `ggplot2`, `pROC`):

```bash
Rscript plot_auc.R \
    ../simulation_study_1/results/ ./results/ \
    ../data/model_specified_10000.txt ./figures/auc_comparison.pdf ./figures/auc.txt
```

Reads Mongrail 2.0 outputs (`.m2out_N*` from Study 1) and plug-in outputs (`.out_N*`
from this study), computes ROC/AUC per model × method × parameter combination, and
writes a faceted line plot plus a table. Combos with missing inputs are skipped.

## Scripts

| Script | Purpose |
|---|---|
| `run_all_study2.sh` | Run every parameter combination (calls `run_study2.sh`) |
| `run_study2.sh` | Run one combo across all N (posterior means → plug-in inference) |
| `compute_posterior_means.sh` | Posterior mean frequencies from count files |
| `run_inference_plugin.sh` | Original Mongrail on posterior means (parallel) |
| `transpose.sh` | Matrix transpose helper |
| `awk_scripts/count.awk` | Extract haplotype counts from count files |
| `awk_scripts/hap_frequency.awk` | Haplotype frequencies from individual genotypes |
| `awk_scripts/uniq_hap.awk` | Union of unique haplotypes |
| `awk_scripts/final_update_hap_freq.awk` | Posterior mean computation |
| `awk_scripts/adjusted_count.awk` | Adjust counts for missing haplotypes |
| `plot_auc.R` | AUC comparison figure (separate step) |

## Required R packages

```r
install.packages(c("ggplot2", "pROC"))
```
