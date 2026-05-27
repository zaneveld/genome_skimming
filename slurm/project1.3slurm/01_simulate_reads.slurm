#!/bin/bash
#SBATCH --job-name=simulate_reads
#SBATCH --account=bbiosci
#SBATCH --partition=compute
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --output=output/logs/simulate_reads.out
#SBATCH --error=output/logs/simulate_reads.err

cd /gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3/scripts

PROJECT=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project1.3

mkdir -p $PROJECT/output/logs
mkdir -p $PROJECT/input/data

# Sample 1
apptainer exec --bind $PROJECT:/data \
    insilicoseq.sif \
    iss generate \
    --genomes /data/input/genomes/cardinium.fa \
    --model hiseq \
    --n_reads 260000 \
    --output /data/input/data/sample1_cardinium

apptainer exec --bind $PROJECT:/data \
    insilicoseq.sif \
    iss generate \
    --genomes /data/input/genomes/cladocopium.fa \
    --model hiseq \
    --n_reads 260000 \
    --output /data/input/data/sample1_cladocopium

apptainer exec --bind $PROJECT:/data \
    insilicoseq.sif \
    iss generate \
    --genomes /data/input/genomes/endozoicomonas.fa \
    --model hiseq \
    --n_reads 260000 \
    --output /data/input/data/sample1_endozoicomonas

apptainer exec --bind $PROJECT:/data \
    insilicoseq.sif \
    iss generate \
    --genomes /data/input/genomes/symbiodinium.fa \
    --model hiseq \
    --n_reads 260000 \
    --output /data/input/data/sample1_symbiodinium

apptainer exec --bind $PROJECT:/data \
    insilicoseq.sif \
    iss generate \
    --genomes /data/input/genomes/nematostella.fa \
    --model hiseq \
    --n_reads 50000 \
    --output /data/input/data/sample1_nematostella

# Sample 2
apptainer exec --bind $PROJECT:/data \
    insilicoseq.sif \
    iss generate \
    --output /data/input/data/sample2_nematostella