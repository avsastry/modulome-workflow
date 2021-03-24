#!/bin/sh

# Step 0: Download metadata
../0_download_metadata/download_metadata.sh "Bacillus subtilis" -o "full_test_metadata.tsv"

python select_test_data.py
rm full_test_metadata.tsv

# Step 1: Process metadata
cd ../1_process_data
nextflow run main.nf --organism bacillus_subtilis --metadata ../test/test_metadata.tsv --sequence_dir ../test/sequence_files/ --outdir ../test/nf_results/
