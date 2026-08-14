# Pipeline for phage genome analysis 
<div style="display" flex; justify-content: space-between; align="center">
  <p>
  <strong>This repository contains a pipeline used for phage DNA analysis. Genomes are analysed using <em>Pharokka</em>, <em>Phold</em> and <em>Empathi</em>. Output files are generated and grouped so that subsequent steps are easy to carry out.</strong>
  </p>
  <img src="Images/logo_lab.png" alt="Lab's logo" width="15%" style="margin-left: 10px;">
</div>

*<div align="center">
    By Ally Champoux, Université de Sherbrooke, 14/08/2026*
</div>

<div align="center">
  
  <a href="https://www.gnu.org/software/bash/">![Bash](https://img.shields.io/badge/Shell_script-black?style=for-the-badge&logo=gnubash&logoColor=white)</a>
  <a href="https://snakemake.github.io/">![Snakemake](https://img.shields.io/badge/snakemake-white?style=for-the-badge&logo=data:image/png;base64,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)</a>
<a href="https://www.python.org/">![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)</a>

</div>


## Installation 
This repository contains the following tree: 
```bash
.
├── Images
│   └── logo_lab.jpg
├── LICENSE
├── README.md
├── Requirements
│   ├── empathi_env.yml
│   ├── pharokka.yml
│   ├── vcontact2.yml
│   └── vir_genome.yml
├── Snakefile
├── Visualisation
│   ├── clinker.py
│   ├── updated_gbk_from_empathi_annot.py
    ├── gene_to_genome_vcontact2.py
│   └── vcontact2.py
├── empathi
```
You can do so by using the following command: 
```bash
git clone https://github.com/allychamp/phage-genome-analysis-pipeline.git
cd ./nanopore-genome-assembly-pipeline/
```
Note that you should have [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) or [miniconda](https://docs.anaconda.com/miniconda/) installed to run this pipeline. You also need snakemake which can be installed from [here](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) or from the `snakemake.yml` in the `./Requirements/` directory:
```bash
conda env create --name snakemake --file=Requirements/snakemake.yml # This path is only valid if you are in the repository directory
```
Make sure to activate this environnement to execute the pipeline:
```bash
conda activate snakemake
```
The rest of the dependencies should be installed in the appropriate conda environnements while executing the pipeline.

## Repository content
### `./Snakefile`
This is the code for the pipeline itself. It contains all the rules to execute the pipeline. Please note that you have to open and assign the variables `data_folder_path` and `analysis_folder_path` to the appropriate paths to your data and the output directory, respectively.

### `./Requirements/`
This folder contains all the requirements for each conda environment. The snakemake pipeline creates the environments itself. Only the `./Requirements/` folder is needed in your working directory.

### `./Visualisation`
This folder contains python scripts usefull in the next steps of the analysis: the connectome (using vContact2 and Cytoscape) and the genomes' alignment (homemade tool, keep an eye open for publication). They do not launch the analysis directly. Each script is use to create and format input files needed for each of the analyses. They are not used by the snakefile, but feel free to use them if needed. The description and usage is specified in each file.

## Usage
### Input
To work, the pipeline needs DNA fasta files containing phage genome assemblies. The pipeline will take the name of your fasta file as the name of the sample. Please make sure there is one file per sample and that the files' names are distinct.

### Defining variable
First, define the variable `data_folder_path` at the beginning of the snakefile so the workflow can locate the data. Then, the path for the desired output directory should be assigned to the `analysis_folder_path` variable just below the `data_folder_path` variable in the snakefile. Feel free to modify the database path also. 

### Running the snakefile 
Once all the paths are set up, make sure to be in the `./phage-genome-analysis-pipeline/` directory and run the pipeline using this command: 
```bash
snakemake --use-conda -j 1  --cores 32 --resources mem_mb=15000
```
Please adapt the --cores and --resources options for your computer. In a Linux exploitation system, you can always run :
``` 
free -h
nproc
```
To know exactly how many cores and memory are available on your computer. Please use appropriate commands for other exploitation systems. Also note that this script is optimised to work with a GPU, it might need adjustments if not provided.

## Output
The pipeline will ouput a lot of files. Each sample will have a file looking like this (note that only the main files are represented here; please see documentation of each tool for more information on the output file):
```bash
├── Empathi
│   ├── sample
│   │   └── predictions_sample.csv
├── Pharokka
│   ├── dnaapler
│   │   ├── dnaapler_reoriented.fasta
│   │   ├── logs
│   ├── logs
│   ├── sample.gbk
├── Phold
│   ├── logs
│   ├── phold.gbk
└── log
    ├── Empathi
    │   └── sample.log
    ├── Pharokka
    │   └── Phold_sample.log
    └── Phold
        └── Phold_sample.log
```


## References
If you use this repo in your own work, please don't forget to cite it accordingly: 

Please also cite all the tools used in that work: 
### Pharokka:
Bouras, G., Nepal R., Houtak, G., et al. Pharokka: a fast scalable bacteriophage annotation tool, Bioinformatics, Volume 39, Issue 1, January 2023, btac776, https://doi.org/10.1093/bioinformatics/btac776

### Phold :
Bouras, G., Nepal R., Houtak, G., et al., Pharokka: a fast scalable bacteriophage annotation tool, Bioinformatics, Volume 39, Issue 1, January 2023, btac776, https://doi.org/10.1093/bioinformatics/btac776

### Empathi : 
Boulay, A., Leprince, A., Enault, F. et al. Empathi: embedding-based phage protein annotation tool by hierarchical assignment. Nat Commun 16, 9114 (2025). https://doi.org/10.1038/s41467-025-64177-5

### vContact2 : (2019).
Bin Jang, H., Bolduc, B., Zablocki, O., et al., Taxonomic assignment of uncultivated prokaryotic virus genomes is enabled by gene-sharing networks. Nat. Biotechnol. 37, 632–639 (2019). https://doi.org/10.1038/s41587-019-0100-8
