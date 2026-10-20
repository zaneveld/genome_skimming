#!/bin/bash
#SBATCH --job-name=score_tiara
#SBATCH --account=<your_lab_account>
#SBATCH --partition=<your_lab_partition>
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=logs/05_score_%j.out
#SBATCH --error=logs/05_score_%j.err

set -euo pipefail
mkdir -p logs results

module load conda
ENV_BASE=/gscratch/bbiosci/zaneveld_bbio495_2025/kmer_binning_project/ngill2/envs
conda activate "${ENV_BASE}/tiara-env"

# --positive-true-labels lists which true_label values in truth/contig_true_labels.tsv
# count as "eukaryotic" for this benchmark. Edit to match whatever groups you
# actually included in refs/genome_manifest.tsv (e.g. add macroalgae,crustacean
# if you simulated those too).
python scripts/score_tiara_eukaryote_call.py \
    --predictions tiara/tiara_predictions.txt \
    --labels truth/contig_true_labels.tsv \
    --positive-true-labels coral,symbiodiniaceae \
    --positive-predicted-classes eukarya,organelle \
    --outdir results

echo "Scoring complete -- see results/metrics_summary.tsv and results/confusion_matrix.png"
