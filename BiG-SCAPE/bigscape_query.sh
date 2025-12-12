#!/bin/bash
set -uo pipefail   # fortsæt selvom én query fejler

# Paths
WORKDIR="/home/student.aau.dk/gu57sy/Working_Directory" #Set to your own WD
QUERY_BGCS="$WORKDIR/bgc_input"          # The extracted BGCs
OUT="$WORKDIR/bigscape_query_results"    # Creates a specific directory for the query results
PFAM="$WORKDIR/PfamDB/Pfam-A.hmm"        # Set path to /home/student.aau.dk/gu57sy/Working_Directory/PfamDB
MIBIG_IN="$WORKDIR/mibig_input/mibig_gbk_4.0" # Set path to /home/student.aau.dk/gu57sy/Working_Directory/mibig_input/mibig_gbk_4.0

# CPUs 
CORES=8

# Create output directory
mkdir -p "$OUT"

# Load conda and activate environment
eval "$(conda shell.bash hook)"
BIGSCAPE_ENV="bigscape_env"
conda activate "$BIGSCAPE_ENV"

# Check Pfam database
if [ ! -f "$PFAM.h3i" ]; then
    echo "Pfam database is not indexed. Run 'hmmpress $PFAM' first."
    exit 1
fi

# Logfile
LOGFILE="$OUT/query_log.txt"
echo "=== BiG-SCAPE query run started $(date) ===" > "$LOGFILE"

echo "=== Running BiG-SCAPE query on all gbk files ==="
for gbk in "$QUERY_BGCS"/*.gbk; do
    name=$(basename "$gbk" .gbk)
    echo ">>> Querying $name"
    {
        bigscape query \
            --query-bgc-path "$gbk" \
            --input-dir "$MIBIG_IN" \
            --output-dir "$OUT/${name}_query" \
            --cores "$CORES" \
            --pfam-path "$PFAM" \
            --verbose
        echo "SUCCESS: $name" >> "$LOGFILE"
    } || {
        echo "FAILED: $name" >> "$LOGFILE"
    }
done

echo "=== All queries finished ==="
echo "=== BiG-SCAPE query run ended $(date) ===" >> "$LOGFILE"
