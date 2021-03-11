# Download RNAseq metadata

Use the `download_metadata.sh` script to download a metadata table for a specific organism. This requires [installing docker](https://docs.docker.com/get-docker/) and Python3.

## Usage
```bash
 Usage: download_metadata.sh ORGANISM [-o OUTPUT] [--force]

  required arguments:
    ORGANISM                 Name of organism in quotes (e.g. "Escherichia coli")

  optional arguments:
    -o, --output OUTPUT    Name of output file (default: <organism>_<date>.tsv)
    -h, --help             Show help message and exit
```


### Example: Download all Bacillus subtilis datasets

```bash
./download_metadata "Bacillus subtilis"
```
