#!/bin/python

"""
Searches for the optimal dimensionality of independent components

OUT_DIR: Path to output directory
"""

import argparse
import os
import shutil

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from scipy import stats
from tqdm import tqdm


# ------------------------------------
# Argument parsing

parser = argparse.ArgumentParser(
    description="Searches for optimal dimensionality of independent components"
)

parser.add_argument(
    "-o",
    dest="out_dir",
    default="",
    help="Path to output file directory (default: current directory)",
)

args = parser.parse_args()

print()
print("Computing optimal set of independent components")
print()

# ------------------------------------
# Load data


def load_mat(dim, mat):
    df = pd.read_csv(
        os.path.join(args.out_dir, "ica_runs", str(dim), mat + ".csv"), index_col=0
    )
    df.columns = range(len(df.columns))
    return df.astype(float)

dims = sorted([int(x) for x in os.listdir(os.path.join(args.out_dir, "ica_runs"))])

M_data = [load_mat(dim, "M") for dim in dims]
A_data = [load_mat(dim, "A") for dim in dims]

# -----------------------------------
# Check large iModulon dimensions

final_a = A_data[-1]
while np.allclose(final_a, 0, atol=0.01):
    A_data = A_data[:-1]
    M_data = M_data[:-1]
    dims = dims[:-1]
    final_a = A_data[-1]

final_m = M_data[-1]

n_components = [m.shape[1] for m in M_data]

# -----------------------------------
# Get iModulon statistics

thresh = 0.7

n_final_mods = []
n_single_genes = []
for m in M_data:
    # Find iModulons similar to the highest dimension
    l2_final = np.sqrt(np.power(final_m, 2).sum(axis=0))
    l2_m = np.sqrt(np.power(m, 2).sum(axis=0))
    dist = (
        pd.DataFrame(abs(np.dot(final_m.T, m)))
        .divide(l2_final, axis=0)
        .divide(l2_m, axis=1)
    )
    n_final_mods.append(len(np.where(dist > thresh)[0]))

    # Find iModulons with single gene outliers
    counter = 0
    for col in m.columns:
        sorted_genes = abs(m[col]).sort_values(ascending=False)
        if sorted_genes.iloc[0] > 2 * sorted_genes.iloc[1]:
            counter += 1
    n_single_genes.append(counter)

non_single_components = np.array(n_components) - np.array(n_single_genes)

DF_stats = pd.DataFrame(
    [n_components, n_final_mods, non_single_components, n_single_genes],
    index=[
        "Robust Components",
        "Final Components",
        "Multi-gene Components",
        "Single Gene Components",
    ],
    columns=dims,
).T
DF_stats.sort_index(inplace=True)

dimensionality = (
    DF_stats[DF_stats["Final Components"] >= DF_stats["Multi-gene Components"]]
    .iloc[0]
    .name
)

print("Optimal Dimensionality:", dimensionality)
print()

# Plot dimensions
fig, ax = plt.subplots()
ax.plot(dims, n_components, label="Robust Components")
ax.plot(dims, n_final_mods, label="Final Components")
ax.plot(dims, non_single_components, label="Non-single-gene Components")
ax.plot(dims, n_single_genes, label="Single Gene Components")

ax.vlines(dimensionality, 0, max(n_components), linestyle="dashed")

ax.set_xlabel("Dimensionality")
ax.set_ylabel("# Components")
ax.legend(bbox_to_anchor=(1, 1))
plt.savefig(
    os.path.join(args.out_dir, "dimension_analysis.pdf"),
    bbox_inches="tight",
    transparent=True,
)

# Save final matrices
final_M_file = os.path.join(args.out_dir, "ica_runs", str(dimensionality), "M.csv")
final_A_file = os.path.join(args.out_dir, "ica_runs", str(dimensionality), "A.csv")

final_M_dest = os.path.join(args.out_dir, "M.csv")
final_A_dest = os.path.join(args.out_dir, "A.csv")
shutil.copyfile(final_M_file, final_M_dest)
shutil.copyfile(final_A_file, final_A_dest)
