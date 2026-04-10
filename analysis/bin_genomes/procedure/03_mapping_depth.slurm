#!/bin/bash
#SBATCH --job-name=mapping_depth
#SBATCH --partition=compute
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G
#SBATCH --time=04:00:00
#SBATCH --output=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs/03_mapping_depth_%j.out
#SBATCH --error=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project/Output/Logs/03_mapping_depth_%j.err

set -euo pipefail

# ---- Define project directory ----
PROJECT_DIR=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/raneeth/metabat_pipeline/project

# ---- Define container paths ----
BOWTIE2_SIF=$PROJECT_DIR/Procedure/Scripts/bowtie2.sif
SAMTOOLS_SIF=$PROJECT_DIR/Procedure/Scripts/samtools.sif
METABAT2_SIF=$PROJECT_DIR/Procedure/Scripts/metabat2.sif

# ---- Define input/output paths (inside container as /project) ----
CONTIGS=/project/Output/assembly/final.contigs.fa
READS=/project/Output/qc/reads_clean.fastq
INDEX_PREFIX=/project/Output/mapping/contigs
BAM_OUT=/project/Output/mapping/aligned.bam
DEPTH_OUT=/project/Output/depth/contig_depth.txt

# ---- Create output directories ----
mkdir -p $PROJECT_DIR/Output/mapping
mkdir -p $PROJECT_DIR/Output/depth
mkdir -p $PROJECT_DIR/Output/Logs

echo "Building Bowtie2 index..."

apptainer exec \
  --bind $PROJECT_DIR:/project \
  $BOWTIE2_SIF bowtie2-build \
  $CONTIGS \
  $INDEX_PREFIX

echo "Mapping reads and sorting BAM..."

apptainer exec \
  --bind $PROJECT_DIR:/project \
  $BOWTIE2_SIF bowtie2 \
  -x $INDEX_PREFIX \
  -U $READS \
  -p 16 | \
apptainer exec \
  --bind $PROJECT_DIR:/project \
  $SAMTOOLS_SIF samtools sort \
  -@ 16 \
  -o $BAM_OUT

echo "Indexing BAM..."

apptainer exec \
  --bind $PROJECT_DIR:/project \
  $SAMTOOLS_SIF samtools index \
  $BAM_OUT
echo "Generating contig depth table..."

apptainer exec \
  --bind $PROJECT_DIR:/project \
  $METABAT2_SIF jgi_summarize_bam_contig_depths \
  --outputDepth $DEPTH_OUT \
  $BAM_OUT

echo "Step 3 completed successfully."