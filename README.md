# modulome-nextflow
Nextflow pipeline to download and process microbial RNA-seq data from NCBI SRA

## Setup
1. Install [Nextflow](https://www.nextflow.io/)
    1. Check that Java 8 or later is installed using: `java -version`
    1. Download nextflow to your current directory: `curl -s https://get.nextflow.io | bash`
    1. Test installation by running: `./nextflow run hello`
1. Install [Docker](https://docs.docker.com/get-docker/)
1. Prepare the metadata file for your dataset. Use the `download_metadata` script to get all metadata for a specified organism. To append local data, you can add new rows to the tsv file and fill out the following columns:
    1. `Experiment`: For public data, this is your SRX ID. For local data, data should be named with a standardized ID (e.g. ecoli_0001)
    1. `LibraryLayout`: Either PAIRED or SINGLE
    1. `Platform`: Usually ILLUMINA, ABI_SOLID, BGISEQ, or PACBIO_SMRT
    1. `Run`: One or more SRR numbers referring to individual lanes from a sequencer. This field is empty for local data.
    1. `R1`: For local data, the complete path to the R1 file. If files are stored on AWS S3, filenames should look like `s3://<bucket/path/to>.fastq.gz`. `R1` and `R2` columns are empty for public SRA data.
    1. `R2`: Same as R1. This will be empty for SINGLE end sequences.
1. Download your sequence files:
    1. Download FASTA and GFF3 files for your genome and plasmids (if relevant) from NCBI. 
    1. Put these in a folder named `sequence_files`, and make sure that this folder only contains files for one organism.
    1. Rename the genome files to `genome.fasta` and `genome.gff3`.
    1. Rename plasmid files to `plasmid_<name>.fasta` and `plasmid_<name>.gff3`.
1. Update the following fields in `conf/user.conf`:
    1. `params.organism`: Name of your organism, including strain information if relevant
    1. `params.metadata`: File path for your metadata file
    1. `params.sequence_dir`: Location of FASTA/GFF3 files

### Running Nextflow locally
1. Go through the steps described in [Setup](#Setup)
1. Run `nextflow run main.nf -profile local [ARGS]`
1. Once it's finished running, you may delete the `work` folder in this root directory to save space.

### Running Nextflow on cloud or high-performance computing
1. Go through the steps described in [Setup](#Setup)
1. Create a new config file for your cloud service/HPC scheduler (see [Nextflow executors](https://www.nextflow.io/docs/latest/executor.html)
1. Add a new profile in the [nextflow.config](nextflow.config) file.
1. Run `nextflow run main.nf -profile <new_profile> [ARGS]`

## Common errors

### Missing R1/R2 columns
If you get the error `Cannot invoke method split() on null object`, this means you are missing the R1 and R2 columns from your metadata file.

### Exceeding requirements
If you get the error `Process requirement exceed available CPUs` or `Process requirements exceed available memory` when using `-profile local`, then edit `conf/local.config` and change the CPU and memory requirements to ensure these are within your local computer's parameters.
