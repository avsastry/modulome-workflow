#!/bin/bash

id=$1

cds=${id}_cds.txt.summary
rrna=${id}_rRNA.txt.summary

line1=$(head -n 1 $cds)

cds_line=$(sed -n 2p $cds)
num_cds=${cds_line:9}

rrna_line=$(sed -n 2p $rrna)
num_rrna=${rrna_line:9}

nofeat=$(sed -n 13p $cds)
num_nofeat=$((${nofeat:22}-$num_rrna))

rest1=$(sed -n '3,12p' $cds)
rest2=$(tail -n 2 $cds)

printf "${line1}\nAssigned\t${num_cds}\nUnassigned_rRNA\t${num_rrna}\n${rest1}\nUnassigned_NoFeatures\t${num_nofeat}\n${rest2}" > ${id}_all.txt.summary
