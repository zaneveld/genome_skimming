#!/bin/bash
#SBATCH --job-name=assemble_contigs
#SBATCH --output=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs/02_assemble_contigs_%j.log
#SBATCH --error=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs/02_assemble_contigs_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=12:00:00
#SBATCH --mem=32G

set -e
set -o pipefail

PROJECT_DIR=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project

MEGAHIT_SIF=$PROJECT_DIR/Procedure/Scripts/megahit.sif
SEQKIT_SIF=$PROJECT_DIR/Procedure/Scripts/seqkit.sif

INPUT_FASTQ=/project/Output/qc/reads_clean.fastq
ASSEMBLY_PARENT=/project/Output/assembly
ASSEMBLY_DIR=$ASSEMBLY_PARENT/job_${SLURM_JOB_ID}

mkdir -p "$PROJECT_DIR/Output/assembly"

apptainer exec \
  --bind $PROJECT_DIR:/project \
  $MEGAHIT_SIF megahit \
  -r "$INPUT_FASTQ" \
  -o "$ASSEMBLY_DIR" \
  --num-cpu-threads 4

if [ -f "$SEQKIT_SIF" ]; then
  apptainer exec \
    --bind $PROJECT_DIR:/project \
    $SEQKIT_SIF seqkit stats \
    "$ASSEMBLY_DIR/final.contigs.fa" \
    > "$ASSEMBLY_DIR/contigs_stats.txt"
fi