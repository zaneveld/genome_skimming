#!/usr/bin/env python3
"""
Stage 2 validation: among eukaryotic contigs, classify each by which reference
group (coral / symbiodiniaceae / macroalgae / crustacean / other) it best matches
via BLAST bitscore, then score against known ground truth.

This is the metric that actually matters for your goal: what fraction of a
"coral bin" built this way would still be contaminating Symbiodiniaceae DNA
(false positive, from the coral-bin perspective), and what fraction of true
coral contigs get lost to the symbiont bin or to "ambiguous" (false negative).

Inputs:
  --blast-results : blastn -outfmt 6 output with columns
                     qseqid sseqid pident length evalue bitscore
  --ref-groups    : two columns, sseqid <tab> group  (maps each reference
                     sequence used to build the BLAST db to its source group)
  --true-labels   : two columns, qseqid <tab> true_label (ground truth for
                     each test contig, e.g. "coral" or "symbiodiniaceae")
  --margin        : minimum fractional bitscore advantage the top group must
                     have over the runner-up group to be called confidently,
                     e.g. 0.10 = top group's best bitscore must be >=10% higher
                     than the next group's best bitscore, else -> "ambiguous"
                     (default 0.10)

Outputs (to --outdir): per_contig_calls.tsv, confusion_matrix_coral_vs_symb.tsv,
                        metrics_summary.tsv
"""
import argparse
import sys
import pandas as pd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--blast-results", required=True)
    ap.add_argument("--ref-groups", required=True)
    ap.add_argument("--true-labels", required=True)
    ap.add_argument("--margin", type=float, default=0.10)
    ap.add_argument("--outdir", required=True)
    args = ap.parse_args()

    cols = ["qseqid", "sseqid", "pident", "length", "evalue", "bitscore"]
    blast = pd.read_csv(args.blast_results, sep="\t", header=None, names=cols)

    ref_groups = pd.read_csv(args.ref_groups, sep="\t", header=None,
                              names=["sseqid", "group"])
    ref_groups["group"] = ref_groups["group"].str.lower().str.strip()

    truth = pd.read_csv(args.true_labels, sep="\t", header=None,
                         names=["qseqid", "true_label"])
    truth["true_label"] = truth["true_label"].str.lower().str.strip()

    blast = blast.merge(ref_groups, on="sseqid", how="left")
    if blast["group"].isna().any():
        n = blast["group"].isna().sum()
        print(f"WARNING: {n} blast hits had subject IDs not found in "
              f"--ref-groups; dropping those rows.", file=sys.stderr)
        blast = blast.dropna(subset=["group"])

    # Best bitscore per query per group
    best_per_group = (
        blast.groupby(["qseqid", "group"])["bitscore"].max().unstack()
    )

    def call_row(row):
        row = row.dropna()
        if row.empty:
            return "no_hit"
        ranked = row.sort_values(ascending=False)
        top_group, top_score = ranked.index[0], ranked.iloc[0]
        if len(ranked) == 1:
            return top_group
        runner_up_score = ranked.iloc[1]
        margin_observed = (top_score - runner_up_score) / top_score
        return top_group if margin_observed >= args.margin else "ambiguous"

    calls = best_per_group.apply(call_row, axis=1).rename("predicted_group")
    result = truth.merge(calls, on="qseqid", how="left")
    result["predicted_group"] = result["predicted_group"].fillna("no_hit")
    result.to_csv(f"{args.outdir}/per_contig_calls.tsv", sep="\t", index=False)

    # --- Focus metric: coral vs symbiodiniaceae confusion ---
    # Anything not confidently called "coral" is, from the coral-bin's
    # perspective, excluded -- which is the conservative/safe outcome for your
    # use case (better to lose a coral contig than keep a symbiont one), but
    # worth reporting explicitly as its own rate.
    sub = result[result.true_label.isin(["coral", "symbiodiniaceae"])].copy()

    tp = ((sub.true_label == "coral") & (sub.predicted_group == "coral")).sum()
    fn_to_symb = ((sub.true_label == "coral") & (sub.predicted_group == "symbiodiniaceae")).sum()
    fn_other = ((sub.true_label == "coral") & ~sub.predicted_group.isin(["coral", "symbiodiniaceae"])).sum()
    fp = ((sub.true_label == "symbiodiniaceae") & (sub.predicted_group == "coral")).sum()
    tn = ((sub.true_label == "symbiodiniaceae") & (sub.predicted_group != "coral")).sum()

    n_coral_true = (sub.true_label == "coral").sum()
    n_symb_true = (sub.true_label == "symbiodiniaceae").sum()

    # Contamination rate: the number that matters most for your TIR-gene counting --
    # of everything that ends up assigned to the coral bin, what fraction is truly
    # coral vs. secretly Symbiodiniaceae?
    n_called_coral = (sub.predicted_group == "coral").sum()
    contamination_rate = fp / n_called_coral if n_called_coral else float("nan")

    fpr = fp / n_symb_true if n_symb_true else float("nan")   # symbiont leaking into coral bin
    fnr_strict = fn_to_symb / n_coral_true if n_coral_true else float("nan")  # coral lost to symb bin specifically
    fnr_total = (fn_to_symb + fn_other) / n_coral_true if n_coral_true else float("nan")  # coral lost to anywhere else

    conf = pd.DataFrame(
        [[tp, fn_to_symb, fn_other], [fp, tn, 0]],
        index=["true_coral", "true_symbiodiniaceae"],
        columns=["called_coral", "called_symbiodiniaceae", "called_other_or_ambiguous"],
    )
    conf.to_csv(f"{args.outdir}/confusion_matrix_coral_vs_symb.tsv", sep="\t")

    summary = pd.DataFrame({
        "metric": [
            "n_true_coral", "n_true_symbiodiniaceae",
            "false_positive_rate_symbiont_called_coral",
            "false_negative_rate_coral_called_symbiont",
            "false_negative_rate_coral_lost_total (symb+ambiguous+other)",
            "contamination_rate_of_final_coral_bin",
        ],
        "value": [n_coral_true, n_symb_true, fpr, fnr_strict, fnr_total, contamination_rate],
    })
    summary.to_csv(f"{args.outdir}/metrics_summary.tsv", sep="\t", index=False)

    print("\n=== Stage 2 (coral vs Symbiodiniaceae) summary ===")
    print(summary.to_string(index=False))
    print(f"\nOf contigs ultimately assigned to the coral bin, "
          f"{contamination_rate:.2%} are actually Symbiodiniaceae (contamination rate).")
    print(f"{fnr_total:.2%} of true coral contigs were excluded from the coral bin "
          f"(lost to symbiont bin, ambiguous, or no-hit).")


if __name__ == "__main__":
    main()
