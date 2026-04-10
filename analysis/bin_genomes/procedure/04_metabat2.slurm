#!/bin/bash
#SBATCH --job-name=metabat2
#SBATCH --partition=compute
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:30:00
#SBATCH --output=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs/04_metabat2_%j.out
#SBATCH --error=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs/04_metabat2_%j.err

set -euo pipefail

# ---- Define project directory ----
PROJECT_DIR=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project

# ---- Input paths ----
CONTIGS=$PROJECT_DIR/Output/assembly/final.contigs.fa
DEPTH=$PROJECT_DIR/Output/depth/contig_depth.txt

# ---- Output path ----
BINS_DIR=$PROJECT_DIR/Output/bins

# ---- Apptainer container path ----
METABAT2_SIF=$PROJECT_DIR/Procedure/Scripts/metabat2.sif

# ---- Create output directory ----
mkdir -p $BINS_DIR

echo "Running MetaBAT2 (regular mode, min contig 1000 bp)..."

apptainer exec \
  --bind $PROJECT_DIR:/project \
  $METABAT2_SIF metabat2 \
  -i /project/Output/assembly/final.contigs.fa \
  -a /project/Output/depth/contig_depth.txt \
  -o /project/Output/bins/bin \
  -m 500 \
  -t 8

echo "MetaBAT2 binning completed."