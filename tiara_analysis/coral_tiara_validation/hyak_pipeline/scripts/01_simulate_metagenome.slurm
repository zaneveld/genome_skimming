#!/bin/bash
#SBATCH --job-name=iss_simulate
#SBATCH --account=<your_lab_account>
#SBATCH --partition=<your_lab_partition>
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --output=logs/01_iss_simulate_%j.out
#SBATCH --error=logs/01_iss_simulate_%j.err

set -euo pipefail
mkdir -p logs sim

module load conda
ENV_BASE=/gscratch/bbiosci/zaneveld_bbio495_2025/kmer_binning_project/ngill2/envs
conda activate "${ENV_BASE}/iss-env"

REF_DIR=refs
OUTPREFIX=sim/mock_coral_metagenome

# --draft: each fasta file is one "genome" (may be multi-contig draft assembly).
# --abundance_file: fractional abundance per genome (must sum to 1, see
#   refs/abundance.tsv built by scripts/build_ref_groups.sh).
# --n_reads: total read count across both mates. 250M ~ 125M read pairs.
#   STRONGLY recommend a pilot run first (e.g. --n_reads 2M) to confirm the
#   whole pipeline works end-to-end before committing a 24h+ allocation to this.
iss generate \
    --draft ${REF_DIR}/coral_host.fasta \
            ${REF_DIR}/symbiodinium.fasta \
            ${REF_DIR}/breviolum.fasta \
            ${REF_DIR}/cladocopium.fasta \
            ${REF_DIR}/durusdinium.fasta \
            ${REF_DIR}/bacteria_1.fasta \
            ${REF_DIR}/bacteria_2.fasta \
            ${REF_DIR}/bacteria_3.fasta \
    --abundance_file ${REF_DIR}/abundance.tsv \
    --n_reads 250M \
    --model novaseq \
    --cpus ${SLURM_CPUS_PER_TASK} \
    --output ${OUTPREFIX}

echo "Simulation complete."
echo "Reads: ${OUTPREFIX}_R1.fastq / ${OUTPREFIX}_R2.fastq"
echo "IMPORTANT: check ${OUTPREFIX}_abundance.txt for the exact genome IDs used --"
echo "these must match the keys in refs/ref_groups.tsv / refs/abundance.tsv."
