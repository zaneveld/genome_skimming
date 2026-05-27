#!/bin/bash
#SBATCH --job-name=map_s2
#SBATCH --account=bbiosci
#SBATCH --partition=compute
#SBATCH --time=04:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=8
#SBATCH --output=output/logs/map_s2.out
#SBATCH --error=output/logs/map_s2.err

PROJECT=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3

cd $PROJECT/scripts

apptainer exec --bind $PROJECT:/data \
    bowtie2.sif \
    bowtie2 \
    -x /data/output/mapping/contigs_index \
    -1 /data/input/data/sample2_combined_R1.fastq \
    -2 /data/input/data/sample2_combined_R2.fastq \
    -S /data/output/mapping/sample2.sam