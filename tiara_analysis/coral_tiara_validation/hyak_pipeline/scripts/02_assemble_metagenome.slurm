#!/bin/bash
#SBATCH --job-name=megahit_assembly
#SBATCH --account=<your_lab_account>
#SBATCH --partition=<your_lab_bigmem_partition>
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=350G
#SBATCH --time=48:00:00
#SBATCH --output=logs/02_megahit_%j.out
#SBATCH --error=logs/02_megahit_%j.err

set -euo pipefail
mkdir -p logs

module load conda
ENV_BASE=/gscratch/bbiosci/zaneveld_bbio495_2025/kmer_binning_project/ngill2/envs
conda activate "${ENV_BASE}/assembly-env"

R1=sim/mock_coral_metagenome_R1.fastq
R2=sim/mock_coral_metagenome_R2.fastq
OUTDIR=assembly/megahit_out

# A ~250M-read (~35-40 Gbp) co-assembly is genuinely heavy -- this requests a
# high-memory node. Check `hyakalloc` / `sinfo` for what memory tiers your
# group's partition (or the shared bigmem/ckpt-bigmem partition) actually has,
# and adjust --mem and --time accordingly. If the job dies from a maintenance
# window or time limit, rerun this same command with `--continue` appended
# and it will resume from the last checkpoint rather than starting over.
#
# --min-contig-len 1000 matches Tiara's practical minimum input length, so we
# don't waste space keeping fragments Tiara won't be able to classify anyway.
megahit -1 ${R1} -2 ${R2} \
        -t ${SLURM_CPUS_PER_TASK} \
        --memory 0.9 \
        --min-contig-len 1000 \
        -o ${OUTDIR}

echo "Assembly complete: ${OUTDIR}/final.contigs.fa"
grep -c ">" ${OUTDIR}/final.contigs.fa | xargs echo "Number of contigs:"
