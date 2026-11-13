# `q2-periobiome`

**Socransky complexes and dysbiosis indices for subgingival 16S rRNA data — a QIIME 2 plugin**

[![CI](https://github.com/LaBiOmicS/q2-periobiome/actions/workflows/ci.yml/badge.svg)](https://github.com/LaBiOmicS/q2-periobiome/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/LaBiOmicS/q2-periobiome/blob/main/LICENSE)
[![QIIME 2](https://img.shields.io/badge/QIIME%202-2024.10%20%7C%202026.10-purple.svg)](https://qiime2.org)
[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB.svg)](https://www.python.org)

**Website:** <https://labiomics.github.io/q2-periobiome/>

`q2-periobiome` turns a feature table and its taxonomy into published,
literature-traceable measures of subgingival dysbiosis. For every sample it
reports:

* the relative abundance of the **Socransky complexes** (Red, Orange,
  Yellow, Green, Purple, Blue). Only species that Socransky et al. (1998)
  and Socransky & Haffajee (2002) actually tested are assigned, and every
  entry of the reference cites the figure or sentence that supports it;
* the **SMDI** (Subgingival Microbial Dysbiosis Index; Chen, Marsh &
  Al-Hebshi 2022), both the 49-species index and the simplified
  three-genus index, computed exactly as in the original implementation;
* **PC2014_moderate**, the fraction of reads from the 17 taxa with moderate
  evidence of association with periodontitis (Pérez-Chaparro et al. 2014);
* **quality-control measures**: sequencing depth, the fraction of reads
  assigned to a complex and the fraction of reads named to species, so
  that unreliable profiles are visible.

The plugin does not introduce a new method. Its value is a single,
auditable and reproducible implementation of measures that are otherwise
computed by hand, each in its own way: historical names are resolved,
unnamed eHOMD phylotypes are matched by HMT number, and the SMDI
reproduces a detail of the original code (the pseudocount) that the paper
describes differently.

> **Research use only.** The indices summarize microbial composition. They
> are not diagnostic or prognostic tests and do not replace a clinical
> periodontal examination.

## What the validation shows

The indices were evaluated on **16 public 16S datasets** processed from raw
reads, following a pre-specified plan ([docs/ANALYSIS_PLAN.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/ANALYSIS_PLAN.md)).
Full results: [docs/VALIDATION.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/VALIDATION.md) and
[validation/results/](https://github.com/LaBiOmicS/q2-periobiome/tree/main/validation/results/).

Across six independent case-control cohorts, the SMDI, its simplified form,
the Red complex and PC2014_moderate were consistently higher in
periodontitis than in periodontal health, although individual values
overlapped between groups:

| Measure (6 independent cohorts) | Pooled AUC (95% CI) | I² |
|---|---|---|
| SMDI (49 species) | 0.94 (0.91–0.98) | 52% |
| SMDI_simplified | 0.92 (0.89–0.94) | 0% |
| Red complex | 0.91 (0.88–0.94) | 0% |
| PC2014_moderate | 0.90 (0.86–0.94) | 31% |
| Blue complex (*Actinomyces*) | 0.18 (0.13–0.24) | 7% |
| Yellow complex | 0.19 (0.11–0.26) | 51% |

AUC = P(index in periodontitis > index in health); values below 0.5 mean
higher in health. Random-effects meta-analysis (REML with Hartung-Knapp-Sidik-Jonkman).

In short:

* **Consistent:** gain of the Red complex and loss of early colonizers
  (above all *Actinomyces*) in periodontitis, across V4, V3-V4 and V1-V3
  and two taxonomic classifiers.
* **Severity and therapy:** the SMDI correlates with probing depth,
  attachment loss and bleeding (Spearman ρ 0.60–0.76 in the two cohorts
  with clinical data). Its median fell after periodontal therapy in all six
  treated cohorts (p < 0.05 in four), while it rose in an untreated
  control arm.
* **Small gain over the Red complex:** the SMDI adds +0.02 AUC
  (0.008–0.038); SMDI_simplified does not differ from it.
* **Not supported:** predicting which patients will not respond to therapy
  (AUC ≈ 0.5 in both cohorts that tested it).

---

## 1. Installation

`q2-periobiome` is tested in CI against **QIIME 2 2026.10** and the
**QIIME 2 amplicon 2024.10** distribution. Since 2026.4 the amplicon
plugins ship in the main QIIME 2 distribution.

```bash
# QIIME 2 2026.10
wget https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.10/qiime2/released/rachis-qiime2-linux-64-conda.yml
conda env create -n qiime2-2026.10 --file rachis-qiime2-linux-64-conda.yml
conda activate qiime2-2026.10
pip install --no-deps git+https://github.com/LaBiOmicS/q2-periobiome.git
qiime dev refresh-cache
qiime periobiome --help
```

For QIIME 2 amplicon 2024.10, use
`https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml`
as the environment file. Every runtime dependency of the plugin is part of
both distributions, hence `--no-deps`. Ready-made environment files that
include the plugin are in [environment-files/](https://github.com/LaBiOmicS/q2-periobiome/tree/main/environment-files/).

For development:

```bash
git clone https://github.com/LaBiOmicS/q2-periobiome.git
cd q2-periobiome
conda env update -n qiime2-2026.10 --file environment.yml   # pytest, pytest-cov, flake8
pip install -e . --no-deps
pytest && flake8
```

## 2. Recommended input

* A feature table of **raw counts** (do not rarefy or normalize).
* A taxonomy classified to **species** against an **oral** reference,
  ideally eHOMD. [scripts/train_classifiers.sh](https://github.com/LaBiOmicS/q2-periobiome/blob/main/scripts/train_classifiers.sh)
  trains naive Bayes classifiers on eHOMD V15.23 for V4 (515F/806R), V3-V4
  (341F/805R) and V1-V2 (27F/338R). A classifier is tied to the
  scikit-learn version that trained it, so train it in the QIIME 2
  environment you will classify with. Alternatively, use
  `classify-consensus-vsearch` against full-length eHOMD, as in the
  [tutorial](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/TUTORIAL.md). With generic databases, fewer reads reach
  species level, and the complex profiles then cover a smaller part of the
  community. The `qc_*` columns show how much.

Every action has usage examples (`qiime periobiome <action> --example-data <dir>`
writes them out, and they are run by the test suite).

## 3. Usage

### 3.1 `collapse-complexes`

```bash
qiime periobiome collapse-complexes \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --o-complex-table complexes.qza \
  --o-indices indices.qza \
  --o-mapping mapping.qza
```

| Option | Type | Description |
| :--- | :--- | :--- |
| `--i-table` | `FeatureTable[Frequency]` | Raw counts. |
| `--i-taxonomy` | `FeatureData[Taxonomy]` | `Taxon` and, optionally, `Confidence`. |
| `--i-custom-mapping` | `SocranskyReference` (optional) | Extra or overriding taxon→complex entries (`taxon`, `complex`, optional `level` = `species`/`genus`). |
| `--i-smdi-signature` | `DysbiosisSignature` (optional) | An additional signature (`taxon`, `direction` = `dysbiotic`/`normobiotic`, `level`), computed with the SMDI method as `SMDI_custom`. |
| `--p-min-confidence` | `Float` 0–1 (default 0) | Features below this classifier confidence go to `Other` (`low-confidence`) and are not counted as SMDI or PC2014 taxa. |
| `--p-smdi-pseudocount` | `Float` in (0, 1) (default: not set) | Fixed pseudocount for the SMDI CLR. When it is not set, the published definition is used: half the smallest non-zero relative abundance of the table. A fixed value makes each sample's SMDI independent of the other samples of the table. |

**Outputs**

* `complexes` (`SocranskyComplexes`): Red, Orange, Yellow, Green, Purple, Blue and Other per sample; rows sum to 1.
* `indices` (`PeriodontalIndices`): `SMDI`, `SMDI_simplified`, `SMDI_custom` (with a signature), `PC2014_moderate`, `qc_depth`, `qc_assigned_fraction`, `qc_species_fraction`. Undefined values (e.g. empty samples) are NaN. A warning lists the SMDI taxa absent from the table, since they enter the index as zeros.
* `mapping` (`SocranskyMapping`): for each feature, the parsed genus and species, the complex, the resolution (`species`, `genus`, `ambiguous`, `unassigned`, `low-confidence`) and whether it belongs to the Pérez-Chaparro list.

**Custom signatures.** To compute another published or in-house signature with the SMDI method:

```text
taxon	direction	level
Treponema denticola	dysbiotic	species
Streptococcus sanguinis	normobiotic	species
```

```bash
qiime tools import --type DysbiosisSignature \
  --input-path my-signature.tsv --output-path my-signature.qza
qiime periobiome collapse-complexes ... --i-smdi-signature my-signature.qza
```

### 3.2 `summarize`

```bash
qiime periobiome summarize \
  --i-complexes complexes.qza --i-indices indices.qza --i-mapping mapping.qza \
  --m-metadata-file metadata.tsv \
  --p-group-column status \
  --p-subject-column subject \
  --o-visualization summary.qzv
```

The report shows the complex profiles, the distribution of each index by group, and the quality-control summary. Tests run only for `--p-group-column`: Mann-Whitney U with AUC for two groups, Kruskal-Wallis with epsilon-squared for more, and Benjamini-Hochberg q-values. Set `--p-subject-column` whenever a subject contributed several samples (sites, visits). Their values are then averaged, so each subject counts once. The report works offline (Vega libraries are bundled).

### 3.3 `delta-indices`

```bash
qiime periobiome delta-indices \
  --i-indices indices.qza --m-metadata-file metadata.tsv \
  --p-subject-col subject --p-group-col visit \
  --p-baseline-group baseline --p-target-group follow-up \
  --o-delta-table deltas.qza
```

Gives follow-up minus baseline for every index, one row per subject. For site-level change, pass a column that combines subject and site as `--p-subject-col`. Several samples of one unit in a group are averaged, and units without both visits are skipped.

## 4. Semantic types

| Type | Content | File |
| :--- | :--- | :--- |
| `SocranskyComplexes` | Complex relative abundances per sample | `complexes.tsv` |
| `PeriodontalIndices` | Indices and QC columns per sample | `indices.tsv` |
| `SampleData[PeriodontalIndicesDelta]` | Per-subject deltas (`subject-id`) | `deltas.tsv` |
| `SocranskyMapping` | Per-feature assignment audit | `mapping.tsv` |
| `SocranskyReference` | Custom taxon→complex entries | `reference.tsv` |
| `DysbiosisSignature` | SMDI signature taxa | `signature.tsv` |

Complexes, indices, deltas and mapping can be used as QIIME 2 Metadata, e.g. with `qiime metadata tabulate` or `qiime longitudinal linear-mixed-effects --p-metric SMDI_simplified`.

## 5. Documentation

| Document | Content |
|---|---|
| [docs/THEORY.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/THEORY.md) | Scientific basis, formulas, reference curation and limits |
| [docs/TUTORIAL.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/TUTORIAL.md) | End-to-end run on public subgingival data |
| [docs/VALIDATION.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/VALIDATION.md) | Multi-cohort external validation |
| [docs/ANALYSIS_PLAN.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/ANALYSIS_PLAN.md) | Pre-specified validation plan |
| [docs/SPEC.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/docs/SPEC.md) | Code layout and file formats |
| [validation/README.md](https://github.com/LaBiOmicS/q2-periobiome/blob/main/validation/README.md) | How to reproduce the validation |

## 6. Citations

Run `qiime periobiome --citations` for BibTeX. The key references are:

1. Socransky SS, Haffajee AD, Cugini MA, Smith C, Kent RL Jr (1998). Microbial complexes in subgingival plaque. *J Clin Periodontol* 25:134–144. https://doi.org/10.1111/j.1600-051X.1998.tb02419.x
2. Socransky SS, Haffajee AD (2002). Dental biofilms: difficult therapeutic targets. *Periodontol 2000* 28:12–55. https://doi.org/10.1034/j.1600-0757.2002.280102.x
3. Chen T, Marsh PD, Al-Hebshi NN (2022). SMDI: an index for measuring subgingival microbial dysbiosis. *J Dent Res* 101:331–338. https://doi.org/10.1177/00220345211035775
4. Pérez-Chaparro PJ, Gonçalves C, Figueiredo LC, et al. (2014). Newly identified pathogens associated with periodontitis: a systematic review. *J Dent Res* 93:846–858. https://doi.org/10.1177/0022034514542468

To cite the plugin itself, see [CITATION.cff](https://github.com/LaBiOmicS/q2-periobiome/blob/main/CITATION.cff).

## 7. License

MIT ([LICENSE](https://github.com/LaBiOmicS/q2-periobiome/blob/main/LICENSE)). Developed at LaBiOmicS — Laboratory of Bioinformatics and Omics Sciences, University of Mogi das Cruzes. The bundled Vega, Vega-Lite and Vega-Embed libraries are BSD-3-Clause (`q2_periobiome/assets/web/js/`).
