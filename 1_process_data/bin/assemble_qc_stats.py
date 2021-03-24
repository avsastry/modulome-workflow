#!/usr/local/bin/python

import argparse
import os
import re

import numpy as np
import pandas as pd


def main(mqc_dir):

    # Load stats tables
    df1 = pd.read_csv(
        os.path.join(mqc_dir, "multiqc_featureCounts.txt"), index_col=0, sep="\t"
    )
    df2 = pd.read_csv(
        os.path.join(mqc_dir, "multiqc_bowtie1.txt"), index_col=0, sep="\t"
    )
    df3 = pd.read_csv(
        os.path.join(mqc_dir, "multiqc_fastqc.txt"), index_col=0, sep="\t"
    )
    df4 = pd.read_csv(
        os.path.join(mqc_dir, "multiqc_cutadapt.txt"), index_col=0, sep="\t"
    )
    df5 = pd.read_csv(
        os.path.join(mqc_dir, "multiqc_rseqc_infer_experiment.txt"),
        index_col=0,
        sep="\t",
    )

    # Concat tables
    final_df = pd.concat([df1, df2, df3, df4, df5], axis=1, sort=True)

    # Sort sample IDs
    final_df = final_df.sort_index()

    # Save to csv
    final_df.to_csv("multiqc_stats.tsv", sep="\t")


if __name__ == "__main__":
    # Argument parsing
    p = argparse.ArgumentParser(
        description="Combines multiqc outputs into a single file"
    )
    p.add_argument("multiqc_dir", help="Directory containing multiqc results")
    args = p.parse_args()

    main(args.multiqc_dir)
