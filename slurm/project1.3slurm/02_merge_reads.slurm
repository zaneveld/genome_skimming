#!/bin/bash
#SBATCH --job-name=merge_reads
#SBATCH --account=bbiosci
#SBATCH --partition=compute
#SBATCH --time=00:30:00
#SBATCH --mem=4G
#SBATCH --output=output/logs/merge_reads.out
#SBATCH --error=output/logs/merge_reads.err

PROJECT=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3

cd $PROJECT/input/data

cat sample1_*_R1.fastq > sample1_combined_R1.fastq
cat sample1_*_R2.fastq > sample1_combined_R2.fastq

cat sample2_*_R1.fastq > sample2_combined_R1.fastq
cat sample2_*_R2.fastq > sample2_combined_R2.fastq