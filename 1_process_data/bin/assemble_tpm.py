#!/usr/local/bin/python

import argparse
import os
import re

import numpy as np
import pandas as pd


def main(results_dir, outdir):

    # Get all results files
    results = []
    for filename in os.listdir(results_dir):
        if filename.endswith("_cds.txt"):
            transcripts = pd.read_csv(
                os.path.join(results_dir, filename), sep="\t", skiprows=1
            )
            transcripts.set_index("Geneid", inplace=True)
            results.append(transcripts.iloc[:, -1])

    # Get gene lenghts
    lengths = transcripts["Length"]

    # Merge dataframes
    counts = pd.concat(results, axis=1)
    counts.columns = [name[:-4] for name in counts.columns]

    # Calculate TPM
    fpk = counts.divide(lengths, axis=0)
    tpm = fpk.divide(fpk.sum() / 1e6)
    log_tpm = np.log2(tpm.astype(float) + 1)

    # Re-order columns
    log_tpm = log_tpm[sorted(log_tpm.columns)]

    # Save to csv
    log_tpm.to_csv(os.path.join(outdir, "log_tpm.csv"))
    counts.to_csv(os.path.join(outdir, "counts.csv"))


if __name__ == "__main__":
    # Argument parsing
    p = argparse.ArgumentParser(
        description="Combines featureCount files into one TPM file"
    )
    p.add_argument(
        "-d", "--results-dir", help="Directory containing all featureCount results"
    )
    p.add_argument("-o", "--outdir", help="Output directory for log-TPM file")
    args = p.parse_args()

    main(args.results_dir, args.outdir)
