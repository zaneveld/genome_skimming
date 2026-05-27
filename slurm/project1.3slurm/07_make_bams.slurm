#!/bin/bash
#SBATCH --job-name=make_bams
#SBATCH --account=bbiosci
#SBATCH --partition=compute
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --output=output/logs/bams.out
#SBATCH --error=output/logs/bams.err

PROJECT=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3

cd $PROJECT/scripts

# Sample 1
apptainer exec --bind $PROJECT:/data \
    samtools.sif \
    samtools view -bS /data/output/mapping/sample1.sam | \
apptainer exec --bind $PROJECT:/data \
    samtools.sif \
    samtools sort -o /data/output/mapping/sample1.sorted.bam

# Sample 2
apptainer exec --bind $PROJECT:/data \
    samtools.sif \
    samtools view -bS /data/output/mapping/sample2.sam | \
apptainer exec --bind $PROJECT:/data \
    samtools.sif \
    samtools sort -o /data/output/mapping/sample2.sorted.bam