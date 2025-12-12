#!/bin/bash
set -euo pipefail

# Paths
WORKDIR="/home/student.aau.dk/gu57sy/Working_Directory"
ANTI="$WORKDIR/antismash_raw"
BGCS="$WORKDIR/bgc_input"
OUT="$WORKDIR/bigscape_results"
PFAM="$WORKDIR/PfamDB/Pfam-A.hmm"

# CPUs
CORES=8

# Create output directories
mkdir -p "$OUT"
mkdir -p "$BGCS"

# Load conda and activate environment
eval "$(conda shell.bash hook)"
BIGSCAPE_ENV="bigscape_env"   # brug det faktiske navn på dit miljø
conda activate "$BIGSCAPE_ENV"

# Check Pfam database
if [ ! -f "$PFAM.h3i" ]; then
    echo "Pfam database is not indexed. Run 'hmmpress $PFAM' first."
    exit 1
fi

echo "=== Unzipping antiSMASH files ==="
cd "$ANTI"
for z in *.zip; do
    [ -e "$z" ] || continue
    outdir="${z%.zip}"
    if [ ! -d "$outdir" ]; then
        echo "Unzipping $z ..."
        unzip -q "$z" -d "$outdir"
    else
        echo "$outdir already exists - skipping unzip"
    fi
done

# Collect gbk files into bgc_input
echo "=== Collecting and renaming gbk files into $BGCS ==="
rm -f "$BGCS"/*.gbk
find "$ANTI" -type f -name "*.gbk" | while read filepath; do
    foldername=$(basename "$(dirname "$filepath")")
    filename=$(basename "$filepath")
    cp "$filepath" "$BGCS/${foldername}_${filename}"
done

# Running BiG-SCAPE cluster
for cutoff in 0.3 0.5 0.7; do
    echo "=== Running BiG-SCAPE cluster at cutoff $cutoff ==="
    bigscape cluster \
        --input-dir "$BGCS" \
        --input-mode flat \
        --output-dir "$OUT" \
        --cores "$CORES" \
        --pfam-path "$PFAM" \
        --gcf-cutoffs $cutoff \
        --verbose
done

echo "=== Cluster runs finished ==="
