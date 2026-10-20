#   bash 00_setup_environments.sh

set -euo pipefail

module load conda

ENV_BASE=/gscratch/bbiosci/zaneveld/zaneveld_bbio495_2025/kmer_binning_project/ngill2/envs
mkdir -p "${ENV_BASE}"

if command -v mamba &> /dev/null; then
    SOLVER=mamba
else
    echo "mamba not found after 'module load conda'."
    SOLVER=conda
fi

${SOLVER} create -y --prefix "${ENV_BASE}/iss-env"      -c bioconda -c conda-forge insilicoseq
${SOLVER} create -y --prefix "${ENV_BASE}/assembly-env" -c bioconda -c conda-forge megahit minimap2 samtools seqkit blast pandas
${SOLVER} create -y --prefix "${ENV_BASE}/tiara-env"    -c bioconda -c conda-forge tiara pandas matplotlib scikit-learn
${SOLVER} create -y --prefix "${ENV_BASE}/ncbi-env"     -c conda-forge ncbi-datasets-cli

echo "Done."

