#!/bin/bash

# Paths
WORKDIR=/home/student.aau.dk/gu57sy/Working_Directory
ANTI=$WORKDIR/antismash_raw
OUT=$WORKDIR/bigscape_output
PFAM=/home/student.aau.dk/gu57sy/Working_Directory/PfamDB/Pfam-A.hmm

# CPUs
CORES=8

# Create output directory
mkdir -p $OUT

# Load conda commands
eval "$(conda shell.bash hook)"
conda activate bigscape

# Activate BiG-SCAPE environment
BIGSCAPE_ENV="bigscape"
conda activate $BIGSCAPE_ENV

echo "=== Unzipping antiSMASH files ==="
cd $ANTI
for z in *.zip; do
    [ -e "$z" ] || continue
    outdir="${z%.zip}"
    if [ ! -d "$outdir" ]; then
        echo "Unzipping $z ..."
        unzip "$z" -d "$outdir"
    else
        echo "$outdir already exists - skipping unzip"
    fi
done

echo "=== Running BiG_SCAPE ==="

# Run Big-SCAPE
bigscape cluster \
    --input-dir $ANTI/*/ \
    --output-dir $OUT \
    --cores $CORES \
    --input-mode recursive \
    --pfam-path $PFAM \
    --verbose
