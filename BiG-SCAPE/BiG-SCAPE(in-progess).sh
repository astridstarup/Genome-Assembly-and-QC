#!/bin/bash
set -euo pipefail

# Paths
WORKDIR="/home/student.aau.dk/gu57sy/Working_Directory" # Set as your own WD
ANTI="$WORKDIR/antismash_raw" # Upload all your data to a directory called antismash_raw
BGCS="$WORKDIR/bgc_input"
OUT="$WORKDIR/bigscape_results"
PFAM="$WORKDIR/PfamDB/Pfam-A.hmm"
MIBIG_IN="$WORKDIR/mibig_input/mibig_gbk_4.0" 

# CPUs
CORES=8

# Create output directory
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

# Run BiG-SCAPE dereplicate
echo "=== Running BiG-SCAPE dereplicate ==="
DEREP="$OUT/derep_output"
mkdir -p "$DEREP"
bigscape dereplicate \
    --input-dir "$BGC" \
    --input-mode flat \
    --output-dir "$DEREP" \
    --cores "$CORES" \
    --pfam-path "$PFAM" \
    --verbose

# Running BiG-SCAPE
for cutoff in 0.3 0.5 0.7; do
    echo "=== Running BiG-SCAPE ==="
    bigscape cluster \
        --input-dir "$BGCS" \
        --input-mode flat \
        --output-dir "$OUT/cluster_c${cutoff}" \
        --cores "$CORES" \
        --pfam-path "$PFAM" \
        --gcf-cutoffs $cutoff \
        --verbose
done

# Run BiG-SCAPE query against MIGBiG
bigscape query \
    --input-dir "$BGCS" \
    --reference-dir "$MIBIG_IN" \
    --output-dir "$OUT/query_results" \
    --cores "$CORES" \
    --pfam-path "$PFAM" \
    --verbose 

# Run BiG-SCAPE benchmark
echo "=== Running BiG-SCAPE benchmark ==="
bigscape benchmark \
    --input-dir "$DEREP" \
    --reference-dir "$MIBIG_IN" \
    --output-dir "$OUT/benchmark_results" \
    --cores "$CORES" \
    --pfam-path "$PFAM"
    --verbose

# Summary
echo "=== Summary of results ==="
echo "Original BGC count: $(ls $BGCS/*.gbk | wc -l)"
echo "Dereplicated BGC count: $(ls $DEREP/*.gbk | wc -l)"
for cutoff in 0.3 0.5 0.7; do
    gcf_count=$(find "$OUT/cluster_derep_c${cutoff}" -type f -name "*.tsv" | wc -l)
    echo "Cutoff $cutoff: $gcf_count GCF files"
done
mibig_count=$(find "$OUT/query_derep_results" -type f -name "*.tsv" | wc -l)
echo "MIBiG query: $mibig_count match files"
