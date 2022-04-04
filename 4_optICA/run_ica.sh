#!/bin/bash

set -e

function usage {
    printf "\nUsage: run_ica.sh [ARGS] FILE\n"
    printf "\n"
    printf "Arguments\n"
    printf "  -i|--iter <n_iter>	      Number of random restarts (default: 100)\n"
    printf "  -t|--tolerance <tol>        Tolerance (default: 1e-7)\n"
    printf "  -n|--n-cores <n_cores>      Number of cores to use (default: 8)\n"
    printf "  -d|--max-dim <max_dim>      Maximum dimensionality for search (default: n_samples)\n"
    printf "  -m|--min-dim <min_dim>      Minimum dimensionality for search (default: 20)\n"
    printf "  -s|--step-size <step_size>  Dimensionality step size (default: n_samples/25)\n"
    printf "  -o|--outdir <path>          Output directory for files (default: current directory)\n"
    printf "  -l|--logfile                Name of log file to use if verbose is off (default: ica.log)\n"
    printf "  -v|--verbose                Send output to stdout rather than writing to file\n"
    printf "  -h|--help                   Display help information\n"
    printf "\n"
    exit 1
}

# Handle arguments

OUTDIR=$(pwd)
TOL="1e-7"
ITER=100
STEP=0
MAXDIM=0
MINDIM=20
CORES=8
VERBOSE=false
LOGFILE="ica.log"

POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case $1 in
	-i|--iter)
        ITER=$2
	    shift;
        shift;;
        -o|--out)
            OUTDIR=$2
            shift;
            shift;;
        -t|--tolerance)
            TOL=$2
            shift;
            shift;;
        -m|--min-dim)
            MINDIM=$2
            shift;
            shift;;
        -d|--max-dim)
            MAXDIM=$2
            shift;
            shift;;
        -s|--step-size)
            STEP=$2
            shift;
            shift;;
        -n|--n-cores)
            CORES=$2
            shift;
            shift;;
        -l|--logfile)
            LOGFILE=$2
            shift;
            shift;;
        -v|--verbose)
            VERBOSE=true
            shift;;
        -h|--help)
            usage;;
        --)
            shift;
            break;;
        *)
            POSITIONAL+=("$1")
            shift;;
    esac
done

set -- "${POSITIONAL[@]}"

FILE="$1"

# Error checking

if [ "$FILE" = "" ]; then
    printf "Filename for expression data is required\n"
    usage
fi

if [ ! -f $FILE ]; then
    printf "ERROR: $FILE does not exist\n"
    exit 1
fi

# Get number of samples in file
n_samples=$(head -1 $FILE | sed 's/[^,]//g' | tr -d '\n' | wc -c)

if [ "$MAXDIM" -eq 0 ]; then
    MAXDIM=$n_samples
fi

if [ "$STEP" -eq 0 ]; then
    STEP=$((($n_samples / 250 + 1) * 10))
fi

# Verbosity wrapper

redirect_cmd() {
    # if verbose, write to std and log else only write to log 
	if [ "$VERBOSE" = true ]; then
        "$@" | tee -a $LOGFILE
    else
        "$@" >> $LOGFILE 2>&1
    fi
}

echo "" > $LOGFILE

# Run code

for dim in $(seq $MINDIM $STEP $MAXDIM); do

    bar="############################${dim//[0-9]/'#'}${MAXDIM//[0-9]/'#'}"

    # Make output subdirectory
    outsubdir=$OUTDIR/ica_runs/$dim

    if [ ! -f $outsubdir ]; then
        mkdir -p $outsubdir
    fi

    redirect_cmd echo ""
    redirect_cmd echo $bar
    redirect_cmd echo "# Computing dimension $dim of $MAXDIM #"
    redirect_cmd echo $bar
    redirect_cmd echo ""

    redirect_cmd mpiexec -n $CORES python -u random_restart_ica.py -f $FILE -i $ITER -o $outsubdir -t $TOL -d $dim 2>&1
    redirect_cmd mpiexec -n $CORES python -u compute_distance.py -i $ITER -o $outsubdir 2>&1
    redirect_cmd mpiexec -n $CORES python -u cluster_components.py -i $ITER -o $outsubdir 2>&1

    redirect_cmd echo ""

done

# Identify best dimension
if [ "$VERBOSE" = true ]; then
    python get_dimension.py -o $OUTDIR 2>&1
else
    python get_dimension.py -o $OUTDIR >> $LOGFILE 2>&1
fi
