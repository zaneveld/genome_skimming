#!/bin/bash
#SBATCH --job-name=megahit
#SBATCH --account=bbiosci
#SBATCH --partition=compute
#SBATCH --time=06:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH --output=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3/output/logs/megahit.out
#SBATCH --error=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3/output/logs/megahit.err

PROJECT=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3

mkdir -p $PROJECT/output/logs

# Remove old assembly automatically if it exists
rm -rf $PROJECT/output/assembly

cd $PROJECT/procedure/scripts

apptainer exec --bind $PROJECT:/data \
    megahit.sif \
    megahit \
    -1 /data/input/data/sample1_combined_R1.fastq,/data/input/data/sample2_combined_R1.fastq \
    -2 /data/input/data/sample1_combined_R2.fastq,/data/input/data/sample2_combined_R2.fastq \
    -o /data/output/assembly \
    --min-contig-len 1000