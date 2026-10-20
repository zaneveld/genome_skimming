#!/bin/bash
# Run this ONCE on the login node after populating refs/genome_manifest.tsv
# and placing the actual reference fasta files it points to in refs/.
# Lightweight file manipulation only -- fine on the login node.
#
#   cd hyak_pipeline
#   bash scripts/build_ref_groups.sh

set -euo pipefail

MANIFEST=refs/genome_manifest.tsv
REF_GROUPS_OUT=refs/ref_groups.tsv       # sequence_id -> group (used for ground truth)
CONCAT_OUT=refs/all_source_genomes.fasta  # all refs combined (used for minimap2 truth mapping)
ABUNDANCE_OUT=refs/abundance.tsv          # genome_id -> fractional abundance (used by InSilicoSeq)

> "${REF_GROUPS_OUT}"
> "${CONCAT_OUT}"

n_genomes=$(wc -l < "${MANIFEST}")

while IFS=$'\t' read -r filepath group; do
    # Every sequence header inside this file is labeled with this file's group,
    # for ground-truth purposes (mapping assembled contigs back to source).
    grep ">" "${filepath}" | sed 's/^>//' | awk -F' ' -v g="${group}" '{print $1"\t"g}' >> "${REF_GROUPS_OUT}"
    cat "${filepath}" >> "${CONCAT_OUT}"
done < "${MANIFEST}"

echo "Wrote ${REF_GROUPS_OUT} (sequence-level truth labels for minimap2 step)"
echo "Wrote ${CONCAT_OUT} (concatenated reference for minimap2 mapping)"

# Starter abundance file: equal weight per genome file, keyed by file basename
# (this is the ID InSilicoSeq uses internally for --draft genomes). EDIT the
# values below to reflect realistic host:symbiont:bacteria ratios -- values
# must sum to 1. Check sim/*_abundance.txt after your first (small test) run
# to confirm these IDs match what InSilicoSeq actually used.
weight=$(python3 -c "print(1/${n_genomes})")
> "${ABUNDANCE_OUT}"
while IFS=$'\t' read -r filepath group; do
    id=$(basename "${filepath}" .fasta)
    printf "%s\t%s\n" "${id}" "${weight}" >> "${ABUNDANCE_OUT}"
done < "${MANIFEST}"

echo "Wrote ${ABUNDANCE_OUT} with equal weighting -- EDIT before running the simulation"
echo "so it reflects a realistic coral:symbiont:bacteria mixture (e.g. coral higher,"
echo "each Symbiodiniaceae genus lower, bacteria distributed across many species)."
