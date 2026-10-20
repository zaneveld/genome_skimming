#!/usr/bin/env python3
"""
Stage 1 validation: does Tiara reliably separate EUKARYOTIC DNA (coral host +
Symbiodiniaceae + any other eukaryotic contaminants) from NON-eukaryotic DNA
(bacteria, archaea, viruses)?

This does NOT try to distinguish coral from Symbiodiniaceae -- that's stage 2
(BLAST-based, see classify_coral_vs_symbiodiniaceae.py). Here we're only asking
"did Tiara correctly flag this as eukaryotic in origin at all."

Inputs:
  --predictions : Tiara output tsv (sequence_id, class_fst_stage[, class_snd_stage])
  --labels      : two-column tsv, sequence_id <tab> true_label
                  true_label should be the FINE-GRAINED true source, e.g.:
                  coral, symbiodiniaceae, macroalgae, crustacean, bacteria, archaea, virus
  --positive-true-labels   : comma-separated list of true_label values that ARE eukaryotic
                             (default: coral,symbiodiniaceae,macroalgae,crustacean)
  --positive-predicted-classes : comma-separated Tiara classes counted as "eukaryotic call"
                             (default: eukarya,organelle -- organelle DNA is still
                             eukaryotic-origin, so it's a correct call for this question
                             even though Tiara buckets it separately from "eukarya")

Outputs (to --outdir): confusion_matrix.tsv, metrics_summary.tsv,
                        per_true_label_breakdown.tsv, confusion_matrix.png
"""
import argparse
import sys
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def load_predictions(path, positive_classes):
    df = pd.read_csv(path, sep="\t")
    df.columns = [c.strip() for c in df.columns]
    id_col = df.columns[0]
    class_col = "class_fst_stage" if "class_fst_stage" in df.columns else df.columns[1]
    df = df.rename(columns={id_col: "sequence_id", class_col: "predicted_class"})
    df["predicted_class"] = df["predicted_class"].str.lower().str.strip()
    df["predicted_binary"] = df["predicted_class"].apply(
        lambda x: "eukaryote" if x in positive_classes else "non_eukaryote"
    )
    return df[["sequence_id", "predicted_class", "predicted_binary"]]


def load_labels(path, positive_labels):
    df = pd.read_csv(path, sep="\t", header=None, names=["sequence_id", "true_label"])
    df["true_label"] = df["true_label"].str.lower().str.strip()
    df["true_binary"] = df["true_label"].apply(
        lambda x: "eukaryote" if x in positive_labels else "non_eukaryote"
    )
    return df


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--predictions", required=True)
    ap.add_argument("--labels", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--positive-true-labels",
                     default="coral,symbiodiniaceae,macroalgae,crustacean")
    ap.add_argument("--positive-predicted-classes", default="eukarya,organelle")
    args = ap.parse_args()

    positive_labels = {s.strip().lower() for s in args.positive_true_labels.split(",")}
    positive_classes = {s.strip().lower() for s in args.positive_predicted_classes.split(",")}

    preds = load_predictions(args.predictions, positive_classes)
    truth = load_labels(args.labels, positive_labels)

    merged = truth.merge(preds, on="sequence_id", how="left")
    missing = merged["predicted_binary"].isna().sum()
    if missing:
        print(f"WARNING: {missing} sequences had no Tiara prediction "
              f"(likely below the -m length cutoff). Excluding from scoring.", file=sys.stderr)
        merged = merged.dropna(subset=["predicted_binary"])

    tp = ((merged.true_binary == "eukaryote") & (merged.predicted_binary == "eukaryote")).sum()
    fn = ((merged.true_binary == "eukaryote") & (merged.predicted_binary == "non_eukaryote")).sum()
    fp = ((merged.true_binary == "non_eukaryote") & (merged.predicted_binary == "eukaryote")).sum()
    tn = ((merged.true_binary == "non_eukaryote") & (merged.predicted_binary == "non_eukaryote")).sum()

    n_euk_true = tp + fn
    n_noneuk_true = fp + tn
    fpr = fp / n_noneuk_true if n_noneuk_true else float("nan")
    fnr = fn / n_euk_true if n_euk_true else float("nan")
    precision = tp / (tp + fp) if (tp + fp) else float("nan")
    recall = tp / (tp + fn) if (tp + fn) else float("nan")
    accuracy = (tp + tn) / len(merged) if len(merged) else float("nan")
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) else float("nan")

    conf = pd.DataFrame(
        [[tp, fn], [fp, tn]],
        index=["true_eukaryote", "true_non_eukaryote"],
        columns=["predicted_eukaryote", "predicted_non_eukaryote"],
    )
    conf.to_csv(f"{args.outdir}/confusion_matrix.tsv", sep="\t")

    summary = pd.DataFrame({
        "metric": ["n_sequences_scored", "accuracy", "false_positive_rate",
                   "false_negative_rate", "precision", "recall_sensitivity", "f1_score"],
        "value": [len(merged), accuracy, fpr, fnr, precision, recall, f1],
    })
    summary.to_csv(f"{args.outdir}/metrics_summary.tsv", sep="\t", index=False)

    # This is the important diagnostic table for you: does Symbiodiniaceae get
    # correctly called eukaryotic (it should, at high rate), and separately, is
    # anything unexpected (e.g. crustacean contigs) falling into non_eukaryote?
    breakdown = (
        merged.groupby(["true_label", "predicted_class"]).size().unstack(fill_value=0)
    )
    breakdown_pct = breakdown.div(breakdown.sum(axis=1), axis=0) * 100
    breakdown_pct.to_csv(f"{args.outdir}/per_true_label_breakdown.tsv", sep="\t")

    fig, ax = plt.subplots(figsize=(4, 4))
    im = ax.imshow(conf.values, cmap="Blues")
    ax.set_xticks([0, 1]); ax.set_xticklabels(conf.columns, rotation=20)
    ax.set_yticks([0, 1]); ax.set_yticklabels(conf.index)
    for i in range(2):
        for j in range(2):
            ax.text(j, i, str(conf.values[i, j]), ha="center", va="center",
                     color="white" if conf.values[i, j] > conf.values.max() / 2 else "black")
    ax.set_title("Tiara: eukaryote vs non-eukaryote")
    fig.colorbar(im, fraction=0.046, pad=0.04)
    fig.tight_layout()
    fig.savefig(f"{args.outdir}/confusion_matrix.png", dpi=150)

    print("\n=== Stage 1 (Tiara eukaryote-call) summary ===")
    print(summary.to_string(index=False))
    print(f"\nFalse positive rate (non-eukaryotic called eukaryotic): {fpr:.2%}")
    print(f"False negative rate (eukaryotic called non-eukaryotic): {fnr:.2%}")
    print("\nSee per_true_label_breakdown.tsv to check specifically how "
          "Symbiodiniaceae fragments were classified.")


if __name__ == "__main__":
    main()
