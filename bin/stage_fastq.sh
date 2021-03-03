#!/bin/bash

while [ $# -gt 0 ] ; do
    case $1 in
        -n | --name) sample_id=$2 ;;
        -r1) R1=$2 ;;
        -r2) R2=$2 ;;
        \? ) echo 'Usage: stage_fastq -name [NAME] -1 "[R1 files]" -2 "[R2 files]"';;
    esac
    shift
done

if [[ $R1 != *.gz ]]; then
    pigz -c $R1 > "$sample_id"_1.fastq.gz
else
    cat $R1 > "$sample_id"_1.fastq.gz
fi

# Only process R2 data if it exists
if [ ! -z "$R2" ]; then
    if [[ $R2 != *.gz ]]; then
        pigz -c $R2 > "$sample_id"_2.fastq.gz
    else
        cat $R2 > "$sample_id"_2.fastq.gz
    fi
fi
