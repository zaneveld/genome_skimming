#!/usr/bin/env python3
"""
Assign a ground-truth source label to each assembled contig by mapping it
back (with minimap2) to the exact reference genomes used to simulate the
metagenome. Since these ARE the simulation source genomes, a contig should
map with very high identity to whichever genome(s) it was actually built
from -- this gives a truth label independent of anything Tiara or BLAST does
downstream, which is what makes it usable as a ground truth.

Inputs:
  --paf         : minimap2 PAF output, contigs (query) vs concatenated
                   reference genomes (target)
  --ref-groups  : two columns, reference_sequence_id <tab> group
                   (from refs/ref_groups.tsv, built by build_ref_groups.sh)
  --min-coverage-frac : minimum fraction of the contig's length that must be
                   covered by matching bases to the winning group, else the
                   contig is labeled "ambiguous_or_unmapped" rather than
                   forced into a group (default 0.5)

Output (to --outdir): contig_true_labels.tsv  (contig_id <tab> true_label)
                       this is the --labels/--true-labels input for the
                       downstream Tiara-scoring scripts.
"""
import argparse
from collections import defaultdict

import pandas as pd

PAF_COLS = [
    "qseqid", "qlen", "qstart", "qend", "strand",
    "sseqid", "slen", "sstart", "send",
    "n_matches", "aln_block_len", "mapq",
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--paf", required=True)
    ap.add_argument("--ref-groups", required=True)
    ap.add_argument("--min-coverage-frac", type=float, default=0.5)
    ap.add_argument("--outdir", required=True)
    args = ap.parse_args()

    paf = pd.read_csv(args.paf, sep="\t", header=None, usecols=range(12), names=PAF_COLS)
    ref_groups = pd.read_csv(args.ref_groups, sep="\t", header=None,
                              names=["sseqid", "group"])
    paf = paf.merge(ref_groups, on="sseqid", how="left")

    unmatched = paf["group"].isna().sum()
    if unmatched:
        print(f"WARNING: {unmatched} alignment rows had subject IDs missing "
              f"from --ref-groups; dropping those rows.")
        paf = paf.dropna(subset=["group"])

    # Sum matching bases per contig per group (a contig can have multiple
    # alignment blocks, possibly to multiple groups if chimeric/misassembled).
    matches_by_group = (
        paf.groupby(["qseqid", "group"])["n_matches"].sum().unstack(fill_value=0)
    )
    qlen = paf.groupby("qseqid")["qlen"].first()

    records = []
    for qseqid, row in matches_by_group.iterrows():
        total_len = qlen.loc[qseqid]
        best_group = row.idxmax()
        best_matches = row.max()
        coverage_frac = best_matches / total_len if total_len else 0
        if coverage_frac >= args.min_coverage_frac:
            records.append((qseqid, best_group))
        else:
            records.append((qseqid, "ambiguous_or_unmapped"))

    out = pd.DataFrame(records, columns=["sequence_id", "true_label"])
    out.to_csv(f"{args.outdir}/contig_true_labels.tsv", sep="\t",
               header=False, index=False)

    print(f"Wrote {len(out)} contig truth labels to "
          f"{args.outdir}/contig_true_labels.tsv")
    print(out["true_label"].value_counts().to_string())
    n_ambiguous = (out["true_label"] == "ambiguous_or_unmapped").sum()
    if n_ambiguous:
        print(f"\n{n_ambiguous} contigs ({n_ambiguous/len(out):.1%}) were "
              f"ambiguous/unmapped -- likely chimeric assemblies or low-coverage "
              f"fragments. These get excluded from FPR/FNR scoring; consider "
              f"inspecting a few if the count is large.")


if __name__ == "__main__":
    main()
