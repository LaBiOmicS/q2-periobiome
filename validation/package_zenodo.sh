#!/usr/bin/env bash
# Assembles the validation package for Zenodo (it does not upload it).
#
#   bash validation/package_zenodo.sh <data_dir> <out_dir>
#
# Copies, for every processed cohort, the small intermediate artifacts
# (feature table, representative sequences, taxonomies, q2-periodontitis
# outputs, denoising statistics, standardised metadata) - no reads - plus
# validation/results/, the pipeline scripts, the locked environment(s) and
# SHA256 checksums.
set -euo pipefail
DATA=$(readlink -f "${1:?usage: package_zenodo.sh <data_dir> <out_dir>}")
OUT=$(mkdir -p "${2:?usage: package_zenodo.sh <data_dir> <out_dir>}" && cd "$2" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
ENV=${Q2_ENV:-q2-amplicon-2024.10}

mkdir -p "$OUT/cohorts" "$OUT/environment"
for cohort in $(tail -n +2 "$HERE/cohorts.tsv" | cut -f1); do
  src=$DATA/$cohort/out
  [ -s "$src/table.qza" ] || continue
  dst=$OUT/cohorts/$cohort
  mkdir -p "$dst"
  cp "$DATA/$cohort/metadata.tsv" "$dst/"
  for a in table rep-seqs taxonomy-nb taxonomy-vsearch denoising-stats \
           complexes-nb complexes-vsearch indices-nb indices-vsearch \
           mapping-nb mapping-vsearch; do
    [ -e "$src/$a.qza" ] && cp -L "$src/$a.qza" "$dst/"
  done
  [ -s "$src/versions.txt" ] && cp "$src/versions.txt" "$dst/"
  cp "$HERE/configs/$cohort.sh" "$dst/config.sh"
done
rsync -a --exclude '__pycache__' "$HERE/results/" "$OUT/results/"
rsync -a --exclude '__pycache__' --exclude results "$HERE/" "$OUT/pipeline/"
micromamba env export -n "$ENV" > "$OUT/environment/$ENV.yml"
micromamba env export -n "$ENV" --explicit > "$OUT/environment/$ENV.explicit.txt" \
  2>/dev/null || true
git -C "$HERE" rev-parse HEAD > "$OUT/pipeline/GIT_COMMIT"
(cd "$OUT" && find . -type f ! -name SHA256SUMS -print0 | sort -z \
  | xargs -0 sha256sum > SHA256SUMS)
du -sh "$OUT"
