# Simulation Study 1: Mongrail 2.0 vs Original Mongrail

Compares Mongrail 2.0 (which integrates over sampling uncertainty in reference panels) against the original Mongrail (which uses known population frequencies). Mongrail 2.0 is evaluated at three reference panel sample sizes: N = 10, 100, 1000.

## Pipeline

```
pop files ──→ [sample_reference_panels.R] ──→ count files (panels)
                                                       │
sim file  ──→ [split_individuals.sh] ──→ individual files ──→ [run_inference.sh] ──→ .m2out_N{10,100,1000}
                                                       │                                     │
                                              chrom files ──────────┘                         │
                                                                                              ↓
                                              true model file + .out ──→ [plot_stacked_barplots.R] ──→ PDF
```

### Step 1: Generate multinomial-sampled reference panels

```bash
# Run for each population × sample size combination
# Example: popA with N=10
Rscript sample_reference_panels.R ../data/pop_files/c20_m10_h5_au1_hc0.1.popA 10 10000 ./panels/

# Full set for one parameter combo (h5):
for POP in popA popB; do
  for N in 10 100 1000; do
    Rscript sample_reference_panels.R \
      ../data/pop_files/c20_m10_h5_au1_hc0.1.${POP} ${N} 10000 ./panels/N${N}/
  done
done
```

Produces: `panels/N10/c20_m10_h5_au1_hc0.1.countA_rep1` ... `_rep10000` (and countB).

### Step 2: Split simulated individuals

```bash
./split_individuals.sh ../data/sim_files/c20_m10_r50_h5_au1_hc0.1.sim ./individuals/
```

Produces: `individuals/c20_m10_r50_h5_au1_hc0.1.sim_i1` ... `_i10000`

### Step 3: Run Mongrail 2.0 inference

```bash
# Arguments: recom_freq n_hap sample_size n_replicate threads mongrail2_bin chrom_dir panel_dir indv_dir output_dir
./run_inference.sh 50 5 10 10000 100 \
    ../src/mongrail2/mongrail2 \
    ../data/chrom_files \
    ./panels/N10/ \
    ./individuals/ \
    ./results/
```

Produces: `results/c20_m10_r50_h5_au1_hc0.1.m2out_N10`

Run for each sample size (N=10, 100, 1000) to get all three output files.

### Step 4: Generate stacked barplot figures

```bash
Rscript plot_stacked_barplots.R \
    ./results/ \
    c20_m10_r50_h5_au1_hc0.1 \
    ../data/model_specified_10000.txt \
    ./figures/barplots_r50_h5.pdf
```

Requires the original Mongrail output (`c20_m10_r50_h5_au1_hc0.1.out`) to also be in `results/`.

Produces a PDF with two pages:
- Page 1: Backcross (model b) vs F2 (model f)
- Page 2: Purebred (model d) vs F1 (model c)

## Running all 4 parameter combinations

Repeat the above steps for each combination:

| recom_freq | n_hap | sim_params |
|---|---|---|
| 1 | 5 | `c20_m10_r1_h5_au1_hc0.1` |
| 1 | 15 | `c20_m10_r1_h15_au1_hc0.1` |
| 50 | 5 | `c20_m10_r50_h5_au1_hc0.1` |
| 50 | 15 | `c20_m10_r50_h15_au1_hc0.1` |

## Scripts

| Script | Purpose |
|---|---|
| `sample_reference_panels.R` | Multinomial sampling of reference panels from population frequencies |
| `split_individuals.sh` | Split multi-individual .sim file into per-individual files |
| `run_inference.sh` | Parallel Mongrail 2.0 inference + concatenation |
| `plot_stacked_barplots.R` | Stacked barplot comparison figures |

## Required R packages

```r
install.packages(c("ggplot2", "ggh4x", "RColorBrewer", "reshape", "ggpubr"))
```
