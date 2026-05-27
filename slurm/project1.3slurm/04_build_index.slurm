#!/bin/bash
#SBATCH --job-name=bt2_index
#SBATCH --account=bbiosci
#SBATCH --partition=compute
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --output=output/logs/index.out
#SBATCH --error=output/logs/index.err

PROJECT=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3

mkdir -p $PROJECT/output/mapping

cd $PROJECT/scripts

apptainer exec --bind $PROJECT:/data \
    bowtie2.sif \
    bowtie2-build \
    /data/output/assembly/final.contigs.fa \
    /data/output/mapping/contigs_index