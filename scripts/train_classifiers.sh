#!/usr/bin/env bash
# Trains naive Bayes classifiers on eHOMD 16S rRNA RefSeq V15.23 for the
# three amplicons most used in subgingival studies.
#
#   bash scripts/train_classifiers.sh <out_dir>
#
# Requires an activated QIIME 2 environment (q2-feature-classifier). Writes
# <out_dir>/ehomd-15.23-<region>-nb-classifier.qza, the reference files,
# versions.txt and SHA256SUMS. Classifiers are tied to the scikit-learn
# version that trained them: use them with the same QIIME 2 release.
#
# Primers
#   V4     515F GTGYCAGCMGCCGCGGTAA / 806R GGACTACNVGGGTWTCTAAT
#          (Parada et al. 2016; Apprill et al. 2015)
#   V3-V4  341F CCTACGGGNGGCWGCAG / 805R GACTACHVGGGTATCTAATCC
#          (Klindworth et al. 2013; the Illumina 16S protocol pair, used by
#          5 of the 8 V3-V4 cohorts of docs/VALIDATION.md)
#   V1-V2  27F AGAGTTTGATCMTGGCTCAG / 338R TGCTGCCTCCCGTAGGAGT
set -euo pipefail

OUT=$(mkdir -p "${1:?usage: train_classifiers.sh <out_dir>}" && cd "$1" && pwd)
THREADS=${THREADS:-4}
VERSION=15.23
BASE=https://www.homd.org/ftp/16S_rRNA_refseq/HOMD_16S_rRNA_RefSeq/V$VERSION
FASTA=HOMD_16S_rRNA_RefSeq_V$VERSION.p9.fasta
TAX=HOMD_16S_rRNA_RefSeq_V$VERSION.qiime.taxonomy
cd "$OUT"

[ -s "$FASTA" ] || curl -sf -o "$FASTA" "$BASE/$FASTA"
[ -s "$TAX" ] || curl -sf -o "$TAX" "$BASE/$TAX"
[ -s ehomd-$VERSION-seqs.qza ] || qiime tools import \
  --type 'FeatureData[Sequence]' --input-path "$FASTA" \
  --output-path ehomd-$VERSION-seqs.qza
[ -s ehomd-$VERSION-taxonomy.qza ] || qiime tools import \
  --type 'FeatureData[Taxonomy]' --input-format HeaderlessTSVTaxonomyFormat \
  --input-path "$TAX" --output-path ehomd-$VERSION-taxonomy.qza

train() {
  local region=$1 fwd=$2 rev=$3
  local reads=ehomd-$VERSION-$region-seqs.qza
  local clf=ehomd-$VERSION-$region-nb-classifier.qza
  [ -s "$clf" ] && return
  echo "$(date +%H:%M) $region"
  qiime feature-classifier extract-reads --i-sequences ehomd-$VERSION-seqs.qza \
    --p-f-primer "$fwd" --p-r-primer "$rev" --p-n-jobs "$THREADS" \
    --o-reads "$reads"
  qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads "$reads" \
    --i-reference-taxonomy ehomd-$VERSION-taxonomy.qza --o-classifier "$clf"
}

train V4 GTGYCAGCMGCCGCGGTAA GGACTACNVGGGTWTCTAAT
train V3-V4 CCTACGGGNGGCWGCAG GACTACHVGGGTATCTAATCC
train V1-V2 AGAGTTTGATCMTGGCTCAG TGCTGCCTCCCGTAGGAGT

{
  echo "eHOMD 16S rRNA RefSeq: V$VERSION ($BASE)"
  echo "date: $(date -u +%Y-%m-%d)"
  qiime --version | head -1
  qiime info | grep -E "feature-classifier|q2-types"
  python -c "import sklearn, sys; print('scikit-learn', sklearn.__version__); print('python', sys.version.split()[0])"
} > versions.txt
sha256sum "$FASTA" "$TAX" ./*.qza > SHA256SUMS
cat versions.txt
