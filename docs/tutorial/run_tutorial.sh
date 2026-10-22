#!/usr/bin/env bash
# q2-periodontitis tutorial: 18 subgingival plaque samples of Chen et al.
# (2018, SRA SRP075100), from raw reads to complexes, SMDI and deltas.
#
#   bash docs/tutorial/run_tutorial.sh <work_dir>
#
# Needs an activated QIIME 2 environment with q2-periodontitis, curl and
# about 1 GB of disk. Downloads ~45 MB of reads and the eHOMD reference
# (~5 MB). Runs in a few minutes on 4 cores.
set -euo pipefail

WORK=${1:?usage: run_tutorial.sh <work_dir>}
HERE=$(cd "$(dirname "$0")" && pwd)
THREADS=${THREADS:-4}
EHOMD=https://www.homd.org/ftp/16S_rRNA_refseq/HOMD_16S_rRNA_RefSeq/V15.23
mkdir -p "$WORK/fastq"
cd "$WORK"

# 1. Reads (MD5-checked) and metadata
tail -n +2 "$HERE/samples.tsv" | while IFS=$'\t' read -r id run _ _ _ _ url md5; do
  f=fastq/$run.fastq.gz
  [ -s "$f" ] && [ "$(md5sum "$f" | cut -d' ' -f1)" = "$md5" ] && continue
  curl -sf --retry 3 -o "$f" "$url"
  [ "$(md5sum "$f" | cut -d' ' -f1)" = "$md5" ] || { echo "MD5 mismatch: $f"; exit 1; }
done
awk -F'\t' -v d="$PWD/fastq" 'BEGIN {OFS="\t"; print "sample-id", "absolute-filepath"}
  NR > 1 {print $1, d "/" $2 ".fastq.gz"}' "$HERE/samples.tsv" > manifest.tsv
cut -f1-6 "$HERE/samples.tsv" > metadata.tsv

# 2. Reads are merged, primer-free V4 (515F/806R, ~253 nt)
qiime tools import --type 'SampleData[SequencesWithQuality]' \
  --input-format SingleEndFastqManifestPhred33V2 \
  --input-path manifest.tsv --output-path demux.qza
qiime dada2 denoise-single --i-demultiplexed-seqs demux.qza \
  --p-trim-left 0 --p-trunc-len 250 --p-n-threads "$THREADS" \
  --o-table table.qza --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats denoising-stats.qza

# 3. Taxonomy against eHOMD: VSEARCH consensus of the top hits at >= 98 %
#    identity (or use a naive Bayes classifier trained with
#    scripts/train_classifiers.sh)
[ -s ehomd.fasta ] || curl -sf -o ehomd.fasta "$EHOMD/HOMD_16S_rRNA_RefSeq_V15.23.p9.fasta"
[ -s ehomd.tsv ] || curl -sf -o ehomd.tsv "$EHOMD/HOMD_16S_rRNA_RefSeq_V15.23.qiime.taxonomy"
qiime tools import --type 'FeatureData[Sequence]' --input-path ehomd.fasta \
  --output-path ehomd-seqs.qza
qiime tools import --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat --input-path ehomd.tsv \
  --output-path ehomd-taxonomy.qza
qiime feature-classifier classify-consensus-vsearch --i-query rep-seqs.qza \
  --i-reference-reads ehomd-seqs.qza --i-reference-taxonomy ehomd-taxonomy.qza \
  --p-perc-identity 0.98 --p-query-cov 0.9 --p-maxaccepts all \
  --p-top-hits-only --p-min-consensus 0.51 --p-threads "$THREADS" \
  --o-classification taxonomy.qza --o-search-results vsearch-hits.qza

# 4. q2-periodontitis
qiime periodontitis collapse-complexes --i-table table.qza \
  --i-taxonomy taxonomy.qza --o-complex-table complexes.qza \
  --o-indices indices.qza --o-mapping mapping.qza
qiime periodontitis summarize --i-complexes complexes.qza \
  --i-indices indices.qza --i-mapping mapping.qza \
  --m-metadata-file metadata.tsv --p-group-column group \
  --p-subject-column subject --o-visualization summary.qzv
qiime periodontitis delta-indices --i-indices indices.qza \
  --m-metadata-file metadata.tsv --p-subject-col site --p-group-col visit \
  --p-baseline-group before --p-target-group after \
  --o-delta-table deltas.qza

qiime tools export --input-path indices.qza --output-path export/indices
qiime tools export --input-path deltas.qza --output-path export/deltas
echo "Done. Open summary.qzv at https://view.qiime2.org;"
echo "indices: export/indices/indices.tsv, deltas: export/deltas/deltas.tsv"
