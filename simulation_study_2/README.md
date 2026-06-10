# Simulation Study 2: Mongrail 2.0 vs Plug-in Posterior Mean

Compares Mongrail 2.0 against a "plug-in" approach: compute posterior mean haplotype frequencies from the sampled counts, then run the original Mongrail using those estimated frequencies as if they were known. The comparison is quantified using AUC across all six hybridization models.

> **To run everything in one command (after Study 1):** `./run_study2.sh`
> Runs all 4 combinations across all three sample sizes and writes the AUC
> figure + table to `figures/`. Requires Study 1 to have been run first.

**Prerequisite — run Study 1 first, for all combos and all N.** This study
   reads the following Study 1 working directories (created by run_study1.sh):
   - `../simulation_study_1/individuals/`   (per-individual .sim files)
   - `../simulation_study_1/panels/N{10,100,1000}/`   (count files)
   - `../simulation_study_1/results/`   (.m2out_N* — read by plot_auc.R)
   If these are absent, Study 2 will fail mid-run.

## Pipeline

```
count files ──→ [compute_posterior_means.sh] ──→ .postMeanA / .postMeanB
   (from Study 1)         │                              │
                     awk_scripts/                         │
                     transpose.sh                         ↓
                                        [run_inference_plugin.sh] ──→ .out_N{10,100,1000}
                                                │                          │
                                        chrom files                        ↓
                                        mongrail binary       Study 1 .m2out + .out ──→ [plot_auc.R] ──→ PDF
```

### Step 1: Compute posterior mean frequencies

```bash
./compute_posterior_means.sh 50 5 1000 10000 \
    ../simulation_study_1/individuals/ \
    ../simulation_study_1/panels/N1000/ \
    ./posterior_means/ \
    ./awk_scripts/
```

For each replicate, this:
1. Extracts haplotypes from the individual's phased genotypes
2. Finds the union of unique haplotypes across popA, popB, and the individual
3. Computes posterior mean: (count + 1/K) / (N + 1), where K is the number of unique haplotypes

Produces: `posterior_means/c20_m10_r50_h5_au1_hc0.1.postMeanA_rep{1..10000}` (and postMeanB).

### Step 2: Run original Mongrail on posterior mean frequencies

```bash
./run_inference_plugin.sh 50 5 1000 10000 100 \
    ../src/mongrail/mongrail \
    ../data/chrom_files \
    ./posterior_means/ \
    ../simulation_study_1/individuals/ \
    ./results/
```

Produces: `results/c20_m10_r50_h5_au1_hc0.1.out_N1000`

**Run Steps 1–2 together, for all sample sizes:**
( the .postMean files are NOT tagged by N and the scripts append, so they
  must be interleaved per N — not all of Step 1 then all of Step 2 )

```bash
for N in 10 100 1000; do
  rm -f ./posterior_means/c20_m10_r50_h5_au1_hc0.1.postMean*_rep*
  ./compute_posterior_means.sh 50 5 $N 10000 \
      ../simulation_study_1/individuals/ ../simulation_study_1/panels/N$N/ \
      ./posterior_means/ ./awk_scripts/
  ./run_inference_plugin.sh 50 5 $N 10000 100 \
      ../src/mongrail/mongrail ../data/chrom_files ./posterior_means/ \
      ../simulation_study_1/individuals/ ./results/
done
```

### Step 3: AUC comparison

```bash
Rscript plot_auc.R \
    ../simulation_study_1/results/ \
    ./results/ \
    ../data/model_specified_10000.txt \
    ./figures/auc_comparison.pdf \
    ./figures/auc.txt
```

Reads Mongrail 2.0 outputs (`.m2out_N*` from Study 1) and plug-in Mongrail outputs (`.out_N*` from Step 2), computes ROC/AUC for each model × method × parameter combination, and produces a faceted line plot.

## Scripts

| Script | Purpose |
|---|---|
| `compute_posterior_means.sh` | Posterior mean frequencies from count files |
| `run_inference_plugin.sh` | Run original Mongrail on posterior means (parallel) |
| `plot_auc.R` | AUC comparison figure |
| `transpose.sh` | Matrix transpose helper |
| `awk_scripts/count.awk` | Extract haplotype counts from count files |
| `awk_scripts/hap_frequency.awk` | Haplotype frequencies from individual genotypes |
| `awk_scripts/uniq_hap.awk` | Union of unique haplotypes |
| `awk_scripts/final_update_hap_freq.awk` | Posterior mean computation |
| `awk_scripts/adjusted_count.awk` | Adjust counts for missing haplotypes |

## Required R packages

```r
install.packages(c("ggplot2", "pROC"))
```
