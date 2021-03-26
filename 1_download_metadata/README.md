# Download RNAseq metadata

This folder contains scripts to download and format the metadata for all RNA-seq data available at NCBI SRA.

## Example usage

The following code finds all RNA-seq data for *Bacillus subtilis* and saves the data to the file `Bacillus_subtilis.tsv`. Note that the species name **must** be enclosed in quotes.

```bash
docker run --rm -it avsastry/modulome_download_rnaseq:latest "Bacillus subtilis" > Bacillus_subtilis.tsv
```
