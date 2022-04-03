# OptICA
This folder contains all scripts required to run ICA at the optimal dimensionality to identify robust components (optICA). Description and benchmarking of optICA is coming soon.

OptICA may take dozens of hours to run using default arguments, depending on the size of your dataset. This can be accelerated by
1. using more processors (i.e. a supercomputer),
1. loosening the tolerance (e.g. `-t 1e-3`), or
1. increasing the dimensionality step size (e.g. `--step-size 20`).

Also, if your dataset has over 500 datasets, we recommend limiting the maximum dimensionality to the number of unique conditions in your dataset.

The `run_ica.sh` script produces three files and a subdirectory:
- `M.csv`: The **M** matrix
- `A.csv`: The **A** matrix
- `dimension_analysis.pdf`: Plot showing the optimal ICA dimensionality
- `ica_runs/`: A subdirectory containing all the **M** and **A** matrices for all dimensions

## Usage
```
Usage: run_ica.sh [ARGS] FILE

Arguments
  -i|--iter <n_iter>	      Number of random restarts (default: 100)
  -t|--tolerance <tol>        Tolerance (default: 1e-7)
  -n|--n-cores <n_cores>      Number of cores to use (default: 8)
  -d|--max-dim <max_dim>      Maximum dimensionality for search (default: n_samples)
  -m|--min-dim <min_dim>      Minimum dimensionality for search (default: 20)
  -s|--step-size <step_size>  Dimensionality step size
  -o|--outdir <path>          Output directory for files (default: current directory)
  -l|--logfile                Name of log file to use if verbose is off (default: ica.log)
  -v|--verbose                Send output to stdout rather than writing to file
  -h|--help                   Display help information
```
## Example Usage
```bash
./run_ica.sh -n 8 -o ../data/interim/ -v ../data/processed_data/log_tpm_norm.csv
```
