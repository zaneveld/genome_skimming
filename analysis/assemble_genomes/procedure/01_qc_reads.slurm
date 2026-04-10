#!/bin/bash
#SBATCH --job-name=fastp_qc
#SBATCH --output=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs/01_qc_reads_%j.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
#SBATCH --mem=8G

set -euo pipefail

FASTP_SIF=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Procedure/Scripts/fastp.sif

mkdir -p /gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/qc
mkdir -p /gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs

apptainer exec \
    --bind /gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project:/project \
    $FASTP_SIF fastp \
    -i /project/Input/Data/merged_cnidaria_genome_read1.fastq \
    -o /project/Output/qc/reads_clean.fastq \
    -h /project/Output/Logs/01_qc_reads_report.html