# Multi-cohort validation of q2-periodontitis

Reproducible re-analysis of public subgingival 16S rRNA amplicon cohorts,
following the pre-specified plan in
[`docs/ANALYSIS_PLAN.md`](../docs/ANALYSIS_PLAN.md). The results and the
deviations from the plan are reported in
[`docs/VALIDATION.md`](../docs/VALIDATION.md).

## Cohorts

[`cohorts.tsv`](cohorts.tsv) registers every cohort: SRA/ENA accession,
design, independence from the SMDI's derivation, the analyses it enters,
region and platform. The cohort search and screening are in
[`search/`](search/).

| Cohort | Design | Region | Independent of the SMDI | Publication |
|---|---|---|---|---|
| SRP075100 | health vs periodontitis; same tooth after therapy | V4 | yes | Chen et al. 2018, doi:10.1038/s41396-017-0037-1 |
| PRJNA863881 | health, gingivitis, stage I-IV; clinical measures | V3-V4 | yes | Iniesta et al. 2023, doi:10.1111/jcpe.13793 |
| PRJEB83770 | health, gingivitis, periodontitis | V3-V4 | yes | (PERIDYSSEQ; ENA description only) |
| PRJNA1470369 | health vs stage I-IV | V3-V4 | yes | Liu et al. 2026, doi:10.3389/fcimb.2026.1864541 |
| PRJNA773202 | health vs periodontitis; clinical measures | V3-V4 | yes | (BioProject description only) |
| PRJNA773195 | same samples as PRJNA773202 | V1-V3 | yes | (BioProject description only) |
| PRJNA726254 | health vs periodontitis; after therapy | V4 | yes | Lee et al. 2021, doi:10.3389/fimmu.2021.691216 |
| PRJNA1294584 | gingivitis vs stage II-IV (no health group) | V3-V4 | yes | Sawangpanyangkura et al. 2026, doi:10.1111/jcpe.70147 |
| PRJNA786436 | non-responding vs responding sites, 3 months | V4 | yes | Byrne et al. 2022, doi:10.1080/20002297.2022.2043595 |
| PRJNA736618 | day 0, 1, 7, 90 after debridement | V3-V4 | yes | Johnston et al. 2021, doi:10.1038/s41598-021-89002-z |
| PRJEB106816 | therapy vs waiting-list control, 3 months | V3-V4 | yes | (ENA description only) |
| SRP051201 | health vs periodontitis | V1-V3 | no (SMDI training) | Kirst et al. 2015, doi:10.1128/aem.02712-14 |
| SRP009299 (V1-V2, V4) | health vs periodontitis | V1-V2, V4 | no (SMDI training) | Griffen et al. 2012, doi:10.1038/ismej.2011.191 |
| SRP226726 | health vs periodontitis | V3-V4 | no (SMDI test) | Pei et al. 2020, doi:10.1007/s13167-020-00202-5 |
| SRP062274 | therapy ± antibiotics, 3-12 months | V5-V7 | no (SMDI test, baseline) | Bizzarro et al. 2016, doi:10.1038/srep20205 |

## Reproducing

Requirements: micromamba (or conda), the QIIME 2 amplicon 2024.10
environment with q2-periodontitis installed (`pip install -e . --no-deps`
from the repository root), curl, about 60 GB of free disk while raw reads
are present, and about a day on 4 cores.

```bash
# everything: download, process, analyse
bash validation/run_all.sh /path/to/data

# or one cohort at a time, then the analysis
bash validation/run_cohort.sh PRJNA863881 /path/to/data
bash validation/analysis/analyse.sh /path/to/data validation/results
```

Environment variables: `Q2_ENV` (micromamba environment, default
`q2-amplicon-2024.10`), `THREADS` (default 4), `REF_DIR` (eHOMD reference,
default `<data>/ehomd`). Every step skips outputs that already exist, so a
run can be resumed. Python that reads downloaded data runs isolated
(`python -I`).

## Pipeline

| Step | Script | What it does |
|---|---|---|
| Download | `download.sh` | ENA file report and FASTQ, MD5-checked |
| Metadata | `prepare.py` | QIIME 2 manifest and standardised metadata (`subject`, `status`, `time`, `unit`, `arm`, `response`, `stage`, clinical measures) from SRA/BioSample records, cached in `<data>/<accession>/biosamples.json` |
| Read QC | `read_qc.py` | Primer positions and quality quartiles; used to fix trimming in `configs/<cohort>.sh` before any index is computed |
| Processing | `process_dataset.sh` | Optional cutadapt; DADA2 (paired, single or pyro) or Deblur (reads without real qualities); naive Bayes on eHOMD V15.23 trimmed to the primers and VSEARCH (≥ 98 %, top hits) against full-length eHOMD; `qiime periodontitis collapse-complexes` |
| Analysis | `analysis/collect.py`, `analysis/run_analysis.py` | Sample tables, QC flags and the pre-specified statistics |
| Robustness | `analysis/robustness.py` | Fixed SMDI pseudocount and rarefaction |
| Figures, report | `analysis/figures.py`, `analysis/report.py` | `results/figures/`, `results/REPORT.md` |

The statistics (`analysis/stats.py`) are tested against metafor and pROC
(`analysis/tests/`, run by the repository's test suite).

## Results layout

* `results/qc.tsv`: per cohort and classifier, samples, depth, reads
  retained, assigned and species fractions, SMDI species absent, QC
  flags.
* `results/samples/<cohort>-<classifier>.tsv`: per-sample indices,
  complexes and standardised metadata.
* `results/tables/*.tsv`: one table per analysis (see the docstring of
  `analysis/run_analysis.py`).
* `results/figures/`: PNG and SVG.
* `results/REPORT.md`: all tables formatted.
