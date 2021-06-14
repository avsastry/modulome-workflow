# modulome-workflow

This repository presents a computational workflow to compute and characterize all iModulons for a selected organism. This occurs in five steps:
1. Gather all publicly available RNA-seq data for the organism ([Step 1](1_download_metadata))
2. Process the RNA-seq data ([Step 2](2_process_data))
3. Inspect data to identify high-quality datasets ([Step 3](3_quality_control))
4. Compute iModulons ([Step 4](4_optICA))
5. Characterize iModulons using [PyModulon](https://github.com/SBRG/pymodulon) ([Step 5](5_characterization))

## Background
**iModulons** are **i**ndependently-**modul**ated group of genes that are computed through Independent Component Analysis (ICA) of a gene expression dataset. To learn more about iModulons or explore published iModulons, visit [iModulonDB](https://imodulondb.org) or see our publications for [*Escherichia coli*](https://www.nature.com/articles/s41467-019-13483-w), [*Staphylococcus aureus*](https://www.pnas.org/content/117/29/17228), or [*Bacillus subtilis*](https://www.nature.com/articles/s41467-020-20153-9).

Here, we introduce the concept of the **Modulome** for an organism, which is the set of all iModulons that can be computed for the organism based on publicly available RNA-seq data. The computational pipeline provides a step-by-step workflow to compute the Modulome for *Bacillus subtilis*.

## Setup

Pre-requisite software is listed within each step of the workflow. In addition, we have provided pre-built Docker containers with all necessary software.

To begin, install [Docker](https://docs.docker.com/get-docker/) and [Nextflow](https://www.nextflow.io/).

## Cite

A pre-print is being prepared for this tutorial workflow.
