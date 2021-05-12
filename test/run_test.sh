#!/bin/sh

# Step 1: Download metadata
echo "Downloading metadata"
docker run --rm -it avsastry/get-all-rnaseq:latest "Bacillus subtilis" > full_test_metadata.tsv

python select_test_data.py
rm full_test_metadata.tsv

# Step 2: Process metadata
echo "Running nextflow"

rm -r nf_results

cd ../2_process_data
nextflow run main.nf --organism bacillus_subtilis --metadata ../test/test_metadata.tsv --sequence_dir ../test/sequence_files/ --outdir ../test/nf_results/

cd ../test

# Step 3: QC

# Step 4: Run ICA
echo "Running optICA"
cd ../4_optICA
./run_ica.sh -n 8 -o ../test/ica_test_results -v -s 50 -t 1e-3 --max-dim 200 ../example_data/processed_data/log_tpm_norm.csv
