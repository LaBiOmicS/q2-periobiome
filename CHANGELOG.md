# Changelog

All notable changes to `q2-periobiome` are documented in this file. The
project follows the QIIME 2 calendar versioning (`YYYY.MM.patch`).

## [2026.10.0] — first public release

### Actions
- `collapse-complexes`: relative abundance of the Socransky complexes
  (Red, Orange, Yellow, Green, Purple, Blue, Other), the SMDI (49 species)
  and SMDI_simplified (3 genera) of Chen, Marsh & Al-Hebshi (2022),
  `PC2014_moderate` (Pérez-Chaparro et al. 2014), per-sample quality
  control (`qc_depth`, `qc_assigned_fraction`, `qc_species_fraction`) and
  a per-feature assignment audit.
- `summarize`: offline HTML report with complex profiles, index
  distributions by group and quality control; a single pre-specified group
  test (Mann-Whitney U with AUC, or Kruskal-Wallis with epsilon-squared,
  Benjamini-Hochberg q-values), with optional averaging per subject.
- `delta-indices`: follow-up minus baseline for every index, per subject
  or per site.

### Reference data
- Socransky complexes restricted to the species of Socransky et al.
  (1998) and Socransky & Haffajee (2002, Fig. 1 and Fig. 11); every row
  cites its source. Historical names resolved through `synonyms_map.tsv`.
- SMDI computed as in the original implementation (R *microbiome* 1.6.0
  CLR, table-dependent pseudocount); an optional fixed pseudocount
  (`--p-smdi-pseudocount`) makes each sample independent of the table.
- eHOMD label parsing: bracketed genera, `[G-n]` placeholders, HMT
  numbers, subspecies and 16S clades; unnamed phylotypes matched by HMT
  number.
- Custom complex mappings (`SocranskyReference`) and dysbiosis signatures
  (`DysbiosisSignature`, reported as `SMDI_custom`).

### Validation and tooling
- Multi-cohort external validation on 16 public 16S datasets
  (`validation/`, `docs/VALIDATION.md`), following the pre-specified plan
  in `docs/ANALYSIS_PLAN.md`.
- Naive Bayes classifiers on eHOMD V15.23 for V4, V3-V4 and V1-V2
  (`scripts/train_classifiers.sh`) and a real-data tutorial
  (`docs/TUTORIAL.md`).
- Tested on QIIME 2 2026.10 and QIIME 2 amplicon 2024.10; usage examples
  for every action; conda recipe and QIIME 2 Library environment files.
