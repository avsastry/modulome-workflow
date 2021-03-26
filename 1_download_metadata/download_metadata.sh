#!/bin/bash

set -e


# Usage string
function usage {
    echo ""
    echo " Usage: download_metadata ORGANISM [-o OUTPUT] [--force]"
    echo ""
    echo "  required arguments:"
    echo "    ORGANISM                 Name of organism in quotes (e.g. \"Escherichia coli\")"
    echo ""
    echo "  optional arguments:"
    echo "    -o, --output OUTPUT    Name of output file (default: <organism>_<date>.tsv)"
    echo "    -h, --help             Show help message and exit"
}

# Process arguments

ORGANISM="$1"
shift

if [[ $ORGANISM = "" ]] || [[ ${ORGANISM::1} = "-" ]]; then
    usage; exit
fi

DATE=$(date +'%Y_%m_%d')
pattern=" "
repl="_"
OUTPUT="${ORGANISM/$pattern/$repl}_${DATE}.tsv"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -o|--outfile)
            OUTPUT="$2"
            shift; shift
            ;;
        -h|--help)
            usage; exit
            ;;
        *)
            echo "\nInvalid option provided. Did you put the organism name in quotes?"
            usage; exit
            ;;
    esac
done

# Make tmp dir

tmp_dir="tmp"
if [ ! -d $tmp_dir ]; then
    mkdir $tmp_dir
fi

tmp_file="$tmp_dir/tmp.tsv"

esearch_query="\\\"${ORGANISM}\\\"[Organism] AND \\\"rna seq\\\"[Strategy] AND \\\"transcriptomic\\\"[Source]"
esearch_script="esearch -db sra -query '${esearch_query}'"
efetch_script="efetch -db sra -format runinfo"

/bin/sh -c "${esearch_script} | ${efetch_script}" > $tmp_file

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
python3 $script_dir/clean_metadata_file.py -i $tmp_file -o $OUTPUT

cat $OUTPUT
