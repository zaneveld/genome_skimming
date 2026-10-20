#!/bin/bash
#SBATCH --job-name=blast_host_classify
#SBATCH --account=<your_lab_account>
#SBATCH --partition=<your_lab_partition>
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=logs/06_blast_classify_%j.out
#SBATCH --error=logs/06_blast_classify_%j.err

set -euo pipefail
mkdir -p logs blast_out

module load conda
ENV_BASE=/gscratch/bbiosci/zaneveld_bbio495_2025/kmer_binning_project/ngill2/envs
conda activate "${ENV_BASE}/assembly-env"   # needs seqkit + blast+

CONTIGS=assembly/megahit_out/final.contigs.fa
TIARA_PRED=tiara/tiara_predictions.txt
REF_FASTA=refs/all_source_genomes.fasta   # same file built by build_ref_groups.sh -- no need to rebuild
DB_NAME=refs/coral_holobiont_refdb
OUTDIR=blast_out

# --- Step A: pull out only the contigs Tiara called eukaryotic ---
# (class_fst_stage column may be named differently across Tiara versions --
#  check the header of tiara_predictions.txt if this awk doesn't match anything)
awk -F'\t' 'NR==1{for(i=1;i<=NF;i++) if($i=="class_fst_stage") c=i; next}
            ($c=="eukarya" || $c=="organelle"){print $1}' ${TIARA_PRED} \
    > ${OUTDIR}/eukaryotic_contig_ids.txt

seqkit grep -f ${OUTDIR}/eukaryotic_contig_ids.txt ${CONTIGS} \
    > ${OUTDIR}/eukaryotic_contigs.fasta

n_euk=$(grep -c ">" ${OUTDIR}/eukaryotic_contigs.fasta)
echo "Tiara called ${n_euk} contigs eukaryotic; these move to stage 2."

# --- Step B: build BLAST db from the same reference genomes used for truth mapping ---
makeblastdb -in ${REF_FASTA} -dbtype nucl -out ${DB_NAME}

# --- Step C: BLAST the eukaryotic contigs against coral + Symbiodiniaceae refs ---
blastn -query ${OUTDIR}/eukaryotic_contigs.fasta \
       -db ${DB_NAME} \
       -task dc-megablast \
       -outfmt '6 qseqid sseqid pident length evalue bitscore' \
       -evalue 1e-10 \
       -max_target_seqs 50 \
       -num_threads ${SLURM_CPUS_PER_TASK} \
       -out ${OUTDIR}/blast_results.tsv

echo "BLAST finished. Classifying by best hit..."

# --- Step D: classify by best-hit group and score against the SAME ground truth
#             built in step 4 (truth/contig_true_labels.tsv) ---
conda activate "${ENV_BASE}/tiara-env"   # needs pandas
python scripts/classify_coral_vs_symbiodiniaceae.py \
       --blast-results ${OUTDIR}/blast_results.tsv \
       --ref-groups refs/ref_groups.tsv \
       --true-labels truth/contig_true_labels.tsv \
       --margin 0.10 \
       --outdir ${OUTDIR}

echo "Stage 2 results: ${OUTDIR}/metrics_summary.tsv"
