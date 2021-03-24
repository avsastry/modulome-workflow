# OptICA
This folder contains all scripts required to run ICA at the optimal dimensionality to identify robust components (optICA). Description and benchmarking of optICA is coming soon.

OptICA may take hours to run using default arguments. This can be accelerated by (a) using more processors (i.e. a supercomputer), (b) loosening the tolerance, or (c) increasing the dimensionality step size.

## Usage
```
Usage: run_ica.sh [ARGS] FILE

Arguments
  -i|--iter <n_iter>	      Number of random restarts (default: 100)
  -t|--tolerance <tol>        Tolerance (default: 1e-7)
  -n|--n-cores <n_cores>      Number of cores to use (default: 8)
  -d|--max-dim <max_dim>      Maximum dimensionality for search (default: n_samples)
  -s|--step-size <step_size>  Dimensionality step size
  -o|--outdir <path>          Output directory for files (default: current directory)
  -l|--logfile                Name of log file to use if verbose is off (default: ica.log)
  -v|--verbose                Send output to stdout rather than writing to file
  -h|--help                   Display help information
```
## Example Usage
```bash
./run_ica.sh -n 8 -o ../example_data/interim/ica_runs/ -v ../example_data/processed_data/log_tpm_norm.csv
```
