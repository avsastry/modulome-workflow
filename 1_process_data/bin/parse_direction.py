#!/usr/local/bin/python

import argparse


def main(rseqc_out, layout):

    with open(rseqc_out, "r") as f:
        lines = f.readlines()

    if lines[0] == "Unknown Data type\n":
        # TODO: Sometimes nothing is mapped, not sure why
        setting = ""
        return setting

    # Get % of reads explained in both directions
    dir1 = float(lines[4].split(":")[-1])
    dir2 = float(lines[5].split(":")[-1])

    # If one direction has over 2x the reads than the other direction, call it stranded

    if dir1 > 2 * dir2:
        setting = "-s 1"
    elif dir2 > 2 * dir1:
        setting = "-s 2"
    else:
        setting = "-s 0"

    print(setting)


if __name__ == "__main__":
    # Argument parsing
    p = argparse.ArgumentParser(
        description="Converts output of infer_experiment to argument for Rockhopper"
    )
    p.add_argument("rseqc_out", type=str, help="RSEQC output file")
    p.add_argument(
        "layout", type=str, help="Single-end (SINGLE) or Paired-end (PAIRED)"
    )
    args = p.parse_args()

    main(args.rseqc_out, args.layout)
