#   conda activate ncbi-env
#   bash scripts/download_reference_genomes.sh

set -euo pipefail
mkdir -p refs/downloads
cd refs/downloads

# --- Coral host genome(s) ---
# Search https://www.ncbi.nlm.nih.gov/datasets/genome/ for your species of
# interest first to confirm the current assembly accession (these get
# superseded over time). Example for Acropora millepora:
datasets download genome accession GCA_013753865.1 --include genome --filename acropora_millepora.zip
unzip -o acropora_millepora.zip -d acropora_millepora
find acropora_millepora -name "*.fna" -exec cp {} ../coral_host.fasta \;

# --- Symbiodiniaceae genomes ---
# The four genera below are the standard reference set used in coral
# holobiont contamination-filtering studies (e.g. Liew et al. 2016; Shoguchi
# et al. 2013; Liu et al. 2018; Dougan et al. 2022). They're hosted on
# reefgenomics.org (http://symbs.reefgenomics.org and related subdomains) as
# direct fasta downloads -- NOT via the datasets CLI, since reefgenomics
# is a standalone site, not part of NCBI. Confirm current download links on
# reefgenomics.org itself, as exact URLs occasionally move.
#
# Illustrative (verify current link before running):
# wget http://symbs.reefgenomics.org/download/symbB.v1.0.genome.fa.gz -O ../symbiodinium.fasta.gz
# gunzip ../symbiodinium.fasta.gz
#
# Repeat similarly for Breviolum minutum, Cladocopium goreaui, and
# Durusdinium trenchii -- reefgenomics.org's "Browse all datasets" page
# lists what's currently hosted, and some of these are also mirrored on NCBI
# under their own BioProjects (searchable via `datasets download genome taxon
# "Cladocopium goreaui"` etc.)

# --- Coral-associated bacteria (background contamination) ---
# Rather than hand-picking specific coral-microbiome taxa, the simplest
# approach is to let InSilicoSeq pull a random sample of real bacterial
# genomes directly from NCBI at simulation time -- see the note in
# 01_simulate_metagenome.slurm about combining --ncbi with --draft.
# If you'd rather use specific named taxa (e.g. Endozoicomonas, Vibrio
# coralliilyticus) for a more realistic microbiome background:
# datasets download genome taxon "Endozoicomonas" --reference --filename endozoicomonas.zip

echo "Reference genomes downloaded to refs/downloads/. Copy/rename the"
echo "relevant fasta files up into refs/ to match refs/genome_manifest.tsv,"
echo "then run scripts/build_ref_groups.sh."
