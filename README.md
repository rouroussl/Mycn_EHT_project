### 1. Analysis Scripts
*   **`01_Extract_Mycn_transcripts.sh`**: A shell script used to extract specific *Mycn* transcript reads from the raw sequencing alignment files (BAM files) based on predefined genomic coordinates.
*   **`02_Mycn_Quantification.Rmd`**: An R Markdown script used for the quantification and statistical analysis of the extracted *Mycn* transcripts.
*   **`03_Mycn_project_script.Rmd`**: The main R Markdown script containing the comprehensive downstream scRNA-seq analysis workflow, including quality control, dimensionality reduction, clustering, differential expression analysis, and the generation of main/supplemental figures.

### 2. Genomic Coordinate Files (.bed)
These BED files define the specific genomic regions of the *Mycn* gene used for transcript extraction in the shell script:
*   **`Mycn_E1.bed`**: Genomic coordinates for *Mycn* Exon 1.
*   **`Mycn_E2_3.bed`**: Genomic coordinates for *Mycn* Exons 2 and 3.
*   **`Mycn_ST.bed`**: Genomic coordinates for specific *Mycn* transcript variants/regions.

### 3. Processed Data Objects (.rds)
These are fully processed Seurat objects (R data format) ready for downstream exploration and figure reproduction:
*   **`sub_combined.rds`**: Processed scRNA-seq Seurat object corresponding to the analysis and visualization presented in **Supplemental Fig 2A**.
*   **`y15_obj.rds`**: Processed scRNA-seq Seurat object corresponding to the analysis and visualization presented in **Supplemental Fig 5A**.
*   **`bm_seu.rds`**: Processed scRNA-seq Seurat object of donor bone marrow LSK (Lin⁻Sca1⁺c-Kit⁺) cells.
