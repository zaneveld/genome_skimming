#!/bin/bash
#SBATCH --job-name=tiara_classify
#SBATCH --account=<your_lab_account>
#SBATCH --partition=<your_lab_partition>
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --output=logs/03_tiara_%j.out
#SBATCH --error=logs/03_tiara_%j.err

set -euo pipefail
mkdir -p logs tiara

module load conda
ENV_BASE=/gscratch/bbiosci/zaneveld_bbio495_2025/kmer_binning_project/ngill2/envs
conda activate "${ENV_BASE}/tiara-env"

CONTIGS=assembly/megahit_out/final.contigs.fa
OUTDIR=tiara

tiara -i ${CONTIGS} \
      -o ${OUTDIR}/tiara_predictions.txt \
      -m 1000 \
      -t ${SLURM_CPUS_PER_TASK} \
      -p ${OUTDIR}/tiara_probabilities.txt

echo "Tiara done: ${OUTDIR}/tiara_predictions.txt"
