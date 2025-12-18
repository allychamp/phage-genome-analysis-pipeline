#!/bin/bash
#SBATCH --mail-type=END,FAIL
#SBATCH -D /lustre06/project/def-labolcf/labolcf/<</path/to/analysis/folder>>
#SBATCH -o /lustre06/project/def-labolcf/labolcf/<</path/to/analysis/folder>>/log/pg-%A_%a.slurm.out
#SBATCH --time=24:00:00
#SBATCH --mem=10G
#SBATCH -N 1
#SBATCH -n 24
#SBATCH -A def-labolcf
#SBATCH -J ph_gen


## EDIT these lines and set SBATCH attributess accordingly
export data_folder_path=/lustre06/project/def-labolcf/analysis_path/Data
export analysis_folder_path=/lustre06/project/def-labolcf/analysis_path/Result
mkdir -p ${analysis_folder_path}

export sample_dir=$(ls -d ${data_folder_path}/* | awk "NR==$SLURM_ARRAY_TASK_ID")
export sample=$(basename ${sample_dir})

export gbk=${analysis_folder_path}/gbk_file/${sample}_phold.gbk
export phold=${analysis_folder_path}/${sample}/Phold
export fa=${path}/multifasta/${sample}_consensus.fasta

# run pharokka on sample
echo "running pharokka on ${sample}"
# db installed to default path, not needed
# if required set with following value: /lustre06/project/6001941/programs/phage-genome-analysis-pipeline/venv/pharokka_venv/databases/
# log outputted to /lustre06/project/def-labolcf/labolcf/<</path/to/analysis/folder>>/log/pg-%A_%a.slurm.out
module purge && module load StdEnv/2020 python/3.10.2 gcc/9.3.0 java/17.0.2 blast+/2.10.1 diamond/0.9.36 mcl/14.137
source /lustre06/project/def-labolcf/programs/phage-genome-analysis-pipeline/venv/pharokka_venv/bin/activate
mkdir -p "${analysis_folder_path}/${sample}/Pharokka/"
pharokka.py --threads 24 \
-i ${sample_dir}/Consensus.fasta \
--dnaapler -e "1e-3" \
-p ${sample} \
-l Pharokka_${sample} \
-o "${analysis_folder_path}/${sample}/Pharokka/"
deactivate

# run phold on sample
echo "running phold on ${sample}"
# log outputted to /lustre06/project/def-labolcf/labolcf/<</path/to/analysis/folder>>/log/pg-%A_%a.slurm.out
# try cpu version first. If too slow, we would need to change submittion sbatch parameters to use gpu nodes
module purge && module load StdEnv/2023 arrow/19.0.1 python/3.11.5
source /home/jflucier/projects/def-labolcf/programs/phage-genome-analysis-pipeline/venv/phold_venv/bin/activate
mkdir -p "${analysis_folder_path}/${sample}/Phold"
phold run --cpu --threads 24 \
-i "${analysis_folder_path}/${sample}/Pharokka/${sample}.gbk" \
-o "${analysis_folder_path}/${sample}/Phold" \
-d /lustre06/project/6001941/programs/phage-genome-analysis-pipeline/venv/phold_venv/lib/python3.11/site-packages/phold/database
deactivate

echo "copying aafasta"
mkdir -p "${analysis_folder_path}/multifasta/"
cp "${analysis_folder_path}/${sample}/Phold/phold.gbk" "${analysis_folder_path}/multifasta/${sample}_consensus.fasta"

echo "running blast"
ml StdEnv/2023 blast+/2.14.1
mkdir "${analysis_folder_path}/${sample}/blast/"
blastn -num_threads 24 \
-db /cvmfs/bio.data.computecanada.ca/content/databases/Core/blast_dbs/2022_03_23/nt \
-query "${analysis_folder_path}/${sample}/Pharokka/${sample}_dnaapler_reoriented.fasta" \
-out "${analysis_folder_path}/${sample}/blast/${sample}_blast.out" \
-best_hit_overhang 0.01  -outfmt "7 qseqid stitle sseqid evalue pident qcovs length score bitscore mismatch gapopen qstart qend sstart send"

echo "running gen MultiFasta_prot"
cat ${analysis_folder_path}/*/Phold/phold_aa.fasta > ${analysis_folder_path}/multifasta/all_samples_prot.fasta

echo "done"
