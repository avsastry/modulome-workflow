#!/usr/local/bin/python3

import argparse

import pandas as pd


def main(infile, outfile):

    # Read in metadata with one SRR as row
    DF_SRR = pd.read_csv(infile, header=0)

    # Merge internal tables
    DF_SRR = DF_SRR[~DF_SRR.Run.isin(["", "Run"])]

    # Merge rows so it has one SRX per row
    agg_rules = {col: ";".join if col == "Run" else "last" for col in DF_SRR.columns}
    DF_SRX = DF_SRR.groupby("Experiment").agg(agg_rules)

    DF_SRX.set_index("Experiment", inplace=True)

    # Add R1 and R2 columns
    DF_SRX["R1"] = None
    DF_SRX["R2"] = None

    # Save to file
    DF_SRX.to_csv(outfile, sep="\t")


if __name__ == "__main__":
    # Argument parsing
    p = argparse.ArgumentParser(description="Clean raw SRA metadata")
    p.add_argument("-i", "--input", help="Input filename")
    p.add_argument("-o", "--output", help="Output filename")
    args = p.parse_args()

    main(args.input, args.output)
