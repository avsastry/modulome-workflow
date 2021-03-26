# Download RNAseq metadata

This folder contains scripts to download and format all RNA-seq metadata for an organisms from NCBI Sequence Read Archive.

## Example usage

The following code finds all RNA-seq data for *Bacillus subtilis* and saves the data to the file `Bacillus_subtilis.tsv`. Note that the species name **must** be enclosed in quotes.

```bash
docker run --rm -it avsastry/get-all-rnaseq:latest "Bacillus subtilis" > Bacillus_subtilis.tsv
```
