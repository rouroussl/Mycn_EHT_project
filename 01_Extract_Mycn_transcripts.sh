#!/usr/bin/env bash

# ==============================================================================
# Description: Extract specific genomic regions from 10X Genomics and STRT-seq 
#              BAM files, generate BigWig coverage tracks, and extract Cell 
#              Barcodes (CB) and UMIs (UB) for downstream analysis.
#
# Dependencies: 
#   - bedtools (v2.31.1)
#   - samtools (v1.23.1)
#   - deeptools (v3.5.6,bamCoverage)
#   - awk
#
# Usage: 
#   1. Modify the paths in the [Configuration] section.
#   2. Run: bash extract_scRNA_features.sh
# ==============================================================================

# 1. Global Configuration
# ==============================================================================

# Output and BED directories (can be overridden via environment variables)
OUT_DIR="${OUT_DIR:-../results}"
BED_DIR="${BED_DIR:-../data/beds}"

# Paths to 10X Genomics Hash BAM files (replace with actual paths)
HASH_BAM_1="/path/to/10X/hash1/possorted_genome_bam.bam"
HASH_BAM_2="/path/to/10X/hash2/possorted_genome_bam.bam"

# Directory containing STRT-seq BAM files (replace with actual path)
STRT_DIR="/path/to/STRT_seq_mapping_dir"

# Target genes/regions (must correspond to .bed files in BED_DIR)
BEDS=("Mycn_ST" "MycnE2_3" "MycnE1")

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"


# ==============================================================================
# 2. Core Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Function: process_bam
# Description: Process a single BAM file: extract regions, calculate coverage, 
#              and extract barcodes.
# Arguments:
#   $1 - in_bam:   Absolute path to the input BAM file
#   $2 - prefix:   Prefix for the output files
#   $3 - seq_type: Sequencing technology type ("10x" or "strt", default: "10x")
# Outputs:
#   - ${prefix}_${bed}.bam (Temporary file, deleted after processing)
#   - ${prefix}_${bed}.bw  (BigWig coverage file)
#   - ${prefix}_${bed}.txt (Two-column text file containing CB and UMI)
# ------------------------------------------------------------------------------
process_bam() {
    local in_bam="$1" 
    local prefix="$2" 
    local seq_type="${3:-10x}"
    
    # Check if input BAM exists; skip if not found
    [[ ! -f "$in_bam" ]] && { echo "[WARNING] Skip: $in_bam not found"; return 0; }

    # Iterate over all target BED regions
    for b in "${BEDS[@]}"; do
        local bed="${BED_DIR}/${b}.bed"
        local tmp="${OUT_DIR}/${prefix}_${b}.bam"
        
        echo "[INFO] Processing $prefix -> $b (Type: $seq_type)"
        
        # Step 1: Intersect
        # Extract reads intersecting with the target BED region
        bedtools intersect -abam "$in_bam" -b "$bed" > "$tmp"
        
        # Step 2: Coverage
        # Index the temporary BAM and generate a BigWig (.bw) file for visualization
        samtools index "$tmp"
        bamCoverage -b "$tmp" -o "${OUT_DIR}/${prefix}_${b}.bw"
        
        # Step 3: Extract Cell Barcode (CB) & UMI (UB)
        # Parse BAM records based on sequencing type
        samtools view -h "$tmp" | awk -v type="$seq_type" '
        BEGIN { OFS="\t" }
        {
            if (type == "10x") {
                # 10X data: Extract CB:Z and UB:Z from optional BAM tags
                cb="-"; ub="-"
                for(i=12; i<=NF; i++) {
                    if($i~/^CB:Z:/) cb=substr($i,6)
                    if($i~/^UB:Z:/) ub=substr($i,6)
                }
                if(cb!="-" && ub!="-") print cb, ub
            } 
            else if (type == "strt") {
                # STRT-seq data: Extract the first 16 bases from the Read Name ($1)
                # First 8 bases are Cell Barcode (CB), next 8 bases are UMI (UB)
                if (match($1, /[ACGTN]{16}/)) {
                    full_bc = substr($1, RSTART, 16)
                    cb = substr(full_bc, 1, 8)  
                    ub = substr(full_bc, 9, 8)  
                    print cb, ub
                }
            }
        }' > "${OUT_DIR}/${prefix}_${b}.txt"
        
        # Step 4: Cleanup
        # Remove temporary BAM and its index
        rm "$tmp" "${tmp}.bai"
    done
}


# ==============================================================================
# 3. Main Execution Logic
# ==============================================================================

echo "[INFO] Pipeline started."

# ------------------------------------------------------------------------------
# Task 1: Process 10X Hash samples
# ------------------------------------------------------------------------------
echo "[INFO] Starting 10X Hash samples processing..."
process_bam "$HASH_BAM_1" "10X_hash_1" "10x"
process_bam "$HASH_BAM_2" "10X_hash_2" "10x"

# ------------------------------------------------------------------------------
# Task 2: Process STRT-seq samples
# ------------------------------------------------------------------------------
echo "[INFO] Starting STRT-seq samples processing..."

# Enable nullglob so that empty directories don't pass the literal wildcard string
shopt -s nullglob 

for bam in "$STRT_DIR"/*mapped.sorted.bam; do
    # Extract base name as prefix (remove '_mapped.sorted.bam' suffix)
    name=$(basename "$bam" _mapped.sorted.bam)
    process_bam "$bam" "${name}_STRT" "strt"
done

echo "[INFO] All tasks finished successfully!"
