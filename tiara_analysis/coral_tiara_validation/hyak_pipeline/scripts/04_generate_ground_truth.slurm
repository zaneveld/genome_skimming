#!/bin/bash
#SBATCH --job-name=ground_truth_mapping
#SBATCH --account=<your_lab_account>
#SBATCH --partition=<your_lab_partition>
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=06:00:00
#SBATCH --output=logs/04_ground_truth_%j.out
#SBATCH --error=logs/04_ground_truth_%j.err

set -euo pipefail
mkdir -p logs truth

module load conda
ENV_BASE=/gscratch/bbiosci/zaneveld_bbio495_2025/kmer_binning_project/ngill2/envs
conda activate "${ENV_BASE}/assembly-env"

CONTIGS=assembly/megahit_out/final.contigs.fa
REFS_CONCAT=refs/all_source_genomes.fasta   # built by scripts/build_ref_groups.sh
OUTDIR=truth

# asm10 preset: designed for assembly-to-reference alignment at ~90%+ identity,
# appropriate here since contigs should closely match their true source genome.
minimap2 -x asm10 -t ${SLURM_CPUS_PER_TASK} \
    ${REFS_CONCAT} ${CONTIGS} > ${OUTDIR}/contigs_vs_refs.paf

# Needs pandas -- reuse tiara-env (or add pandas to assembly-env) rather than
# switching environments mid-script.
conda activate "${ENV_BASE}/tiara-env"
python scripts/assign_truth_labels.py \
    --paf ${OUTDIR}/contigs_vs_refs.paf \
    --ref-groups refs/ref_groups.tsv \
    --outdir ${OUTDIR}

echo "Ground truth labels: ${OUTDIR}/contig_true_labels.tsv"
