# Importing the needed module
import os

# Enter here the file path to your data. 
# `data_folder_path` should be assigned to the path containing the data that is to be analysed. see README for more info on the appropriate organisation¸
# of your data
data_folder_path = "/home/champa/BIOINFO_Linux/PHAGE_genome_analysis/Denault_N/All_data/Data"
# `analysis_folder_path` should contain a list of one path (in string) to the desired output directory 
analysis_folder_path = ["/home/champa/BIOINFO_Linux/PHAGE_genome_analysis/Denault_N/Result"] # This absolutely needs to be a list
DB = "/home/champa/BIOINFO_Linux/DataBase"

# # Defining the path for all the conda envs. It doesn't need to be changed if the working directory is in the repository file.
vir_genome = "Requirements/vir_genome.yml"
# genome_analysis = "Requirements/bact_genome_analysis.yml"
# genomad = "Requirements/genomad.yml" # This tool needs to be in its own envs to prevent dependency errors when executing the tool

# First the data is being organized so the pipeline will be executed for each sample in the data folder. Every fasta file in each sample folder will
# be analyzed for this specific sample (see README.md).
# Defining an empty list that will contain the sample's name
samples = []

# Looping through all the files in the data_folder_path. There should be one folder per sample. os.listdir() returns a list of all the files
# in the directory defiened in `data_folder_path`. Using this method, it allows the pipeline to iterate through each of those folders.
for s in os.listdir(data_folder_path):
    # print(s)
    # Defining the path for the specific sample. The function os.path.join() allows to join a path. In our case, we want: `data_folder_path` + the name of each sample.
    # Because of the for loop, it will assign the `full_path` variable to each of the sample's paths one at a time. This way, the pipeline can access
    # each sample directory
    full_path = os.path.join(data_folder_path, s)
    # print(full_path)
    # Defining the path for the specific sample. The function os.path.join() allows to join a path. In our case, we want: `data_folder_path` + the name of each sample.
    # Because of the for loop, it will assign the `full_path` variable to each of the sample's paths one at a time. This way, the pipeline can access
    # each sample directory
    full_path = os.path.join(data_folder_path, s)
    # print(full_path)

    # Verifing that the path refers to an existing directory
    if os.path.isdir(full_path):
        # Defining the name of the sample's file as the sample name. os.path.basename() returns a string containing the last part of the path, here, the folder corresponding to the sample's name
        sample_name = os.path.basename(s)
        # print(sample_name)
        samples.append(sample_name)
    else:
        print('Please check your data folder path')

# QC: I started by testing my pipeline with only 3 files (for the first two rules) to be sure that it does what it is supposed to do
# lst_test = ['PA_S9_1','PA_S9_2']

rule all:
    # The directive 'input' tells snakemake which files should be used as inputs in the rule
    input:
        # The expand() command allows you to iterate through all the file that matches the wildcards. The 'path' wildcard refers to 
        # the 'analysis_folder_path' variable defined earlier. Sample is defined as each element in the samples list created earlier
        expand(
            "{path}/gbk_file/{sample}_phold.gbk",
            path = analysis_folder_path,
            sample = samples,
        ),
        expand("{path}/{sample}/Phold",
            path = analysis_folder_path,
            sample = samples,),
        expand("{path}/{sample}/blast/{sample}_blast.out",
            path = analysis_folder_path,
            sample = samples,),
        expand("{path}/multifasta/{sample}_consensus.fasta",
            path = analysis_folder_path,
            sample = samples,)

rule DB_download:
    # There is no input for this rule since databases is simply downloaded in bash command line. It should only be done once since there are no wildcards associated with this rule.
    # The output pharokka is defined to contain pharokka's database
    output:
        pharokka = directory(f"{DB}/Pharokka_DB"),
        phold = directory(f"{DB}/Phold_DB")
    # Since the command to download the database is specific , I also use geNomad environment here. Of course, this environment is available 
    # in the Requirements folder of the repository.
    conda: 
       vir_genome
    # A message is printed in the terminal so the user can follow what the pipeline is currently doing
    message:
       "Downloading databases"
    shell:
        # In the shell I download Pharokka and Phold DB using the appropriate command
        """
        install_databases.py -o {output.pharokka} &&
        phold install -d {output.phold}
        """

# The first tool used is Pharokka. This tools allows to annotate phages genome using the fasta file
# The first tool used is Pharokka. This tools allows to annotate phages genome using the fasta file
rule pharokka:
# The input of this rule is a lambda function used to dynamically create file paths based on the values of wildcards. Here, each wildcard (sample)
# will be passed to the function, creating the path associated with it. In other words, the pipeline will input each consensus.fasta file regarding each sample.
    input: 
        lambda wildcards: f"{data_folder_path}/{wildcards.sample}/Consensus.fasta"
    # The output of this tool is a directory (defined by the all output). Later in the pipeline we will need the gbk file. This file is defiened as the "phold"
    # output because Phold is the tool that need a gbk file.
    output: 
        all = directory("{path}/{sample}/Pharokka/"),
        phold = "{path}/{sample}/Pharokka/{sample}.gbk",
        dnaapler = "{path}/{sample}/Pharokka/{sample}_dnaapler_reoriented.fasta"
        # no_dnaapler = "{path}/{sample}/Pharokka/phanotate.faa"
    # A message is printed in the terminal so the user can follow what the pipeline is currently doing
    message:
       "Annotation of {wildcards.sample} with Pharokka"

    #Sending tool's error to a log.
    log:
    	"{path}/{sample}/log/Pharokka/Phold_{sample}.log" 
    # The e value usd for this analysis is 0.001, it's the default value. This parameters could be changed depending in the use. The param DB_folder 
    # is defined to math the database path (DB variable defined at the beginning of this file)
    params:
        evalue = 1e-3,
        DB_folder = DB
    # Still using the same conda environnememt
    conda: 
        vir_genome
    shell: "pharokka.py -i {input} -d {params.DB_folder}/Pharokka_DB --dnaapler -e {params.evalue} -p {wildcards.sample} -l Pharokka_{wildcards.sample} -o {output.all} -f > {log} 2>&1" 

rule Phold:
    input:  "{path}/{sample}/Pharokka/{sample}_dnaapler_reoriented.fasta"
    output: 
        all = directory("{path}/{sample}/Phold"),
        gbk = "{path}/{sample}/Phold/phold.gbk",
        fasta = "{path}/{sample}/Phold/phold_aa.fasta"
    conda:
        vir_genome
    #Sending snakemake error to a log.
    log:
    	"{path}/{sample}/log/Phold/Phold_{sample}.log" 
    # A message is printed in the terminal so the user can follow what the pipeline is currently doing
    message:
       "Annotation of {wildcards.sample} with Phold"
    resources:
        gpu=1
    params:
        DB_folder = DB
    # This is the command that snakemake inputs in the shell.
        #Usage: 
            # -i : path the the input file (fasta file from sequencing)
            # -d : path to the DataBase
            # -o : path to the output directory (the fonction will create a new directory with the name that you gave, if you want to overwrite any directory that already have that name/path use -f ou --force)
            # --danapler : automatically detects and reorients your phage to start with the large terminase subunit. 
            # see pharokka.py --help for the other parameters
        
    shell: 
        """
        phold run -i {input} -o {output.all} -d {params.DB_folder}/Phold_DB -f > {log} 2>&1
        """
# Last, here is two simples rules that will allow the rest of the analysis (visualisation) to be way easier. Essentially it takes all the gbk file ouputed 
# by phold, it copies them into a folder and it adds the sample name in the file name. The second one takes all the amino_acid file and copy them into a folder
rule copy_data_gbk: 
    input: 
        gbk = "{path}/{sample}/Phold/phold.gbk", 
        
    output: 
        all_gbk = "{path}/gbk_file/{sample}_phold.gbk",
    shell:
        """
        cp {input.gbk} {output.all_gbk} 
        """

rule copy_data_aafasta: 
    input: 
        fasta = "{path}/{sample}/Phold/phold_aa.fasta" 
        # fasta = "{path}/{sample}/Phold/phold_aa.fasta"
    output: 
        all_fasta = "{path}/multifasta/{sample}_consensus.fasta",
        # all_fasta = "{path}/fasta_file/{sample}_phold_aa.fasta"
    shell:
        """
        cp {input.fasta} {output.all_fasta} 
        """

# def get_fasta_input(wildcards):

#     print(">>> Fonction get_fasta_input() appelée avec les wildcards :", wildcards)

#     fasta_list = []
#     # for raw_data_path, raw_samples in raw_data_dict.items():  # raw_samples est une LISTE
#     #     print("Dossier d'entrée :", raw_data_path)
#     #     print("Échantillons détectés :", raw_samples)
#     # for path in data_folder_path:
#     for sample in samples:  # Boucle sur chaque échantillon
#         fasta_path = f"{data_folder_path}/{sample}/Consensus.fasta"
#         print(f"Ajout de : {fasta_path}")
#         fasta_list.append(fasta_path)

#         print(">>> Liste finale des fichiers FASTA :", fasta_list)
#     return fasta_list


# rule blast:
#     input: 
#         lambda wildcards: get_fasta_input(wildcards)
#     output: 
#         "{path}/{sample}/blast/{sample}_blast.out"
#     shell: 
#         """
#         blastn -db nt -query {input} -out {output} -remote -outfmt 0
#         """
def get_fasta_input(wildcards):
    # print(">>> Fonction get_fasta_input() appelée avec les wildcards :", wildcards)
    
    # Construire le chemin du fichier FASTA en fonction du wildcard `sample`
    # fasta_path = f"{wildcards.path}/{wildcards.sample}/Pharokka/{wildcards.sample}_dnaapler_reoriented.fasta"
    fasta_path = f"{data_folder_path}/{wildcards.sample}/Pharokka/{wildcards.sample}_dnaapler_reoriented.fasta"
    # print(f"Chemin du fichier FASTA généré : {fasta_path}")

    return fasta_path  # Retourner une seule chaîne de caractères (pas une liste)

# This rule will blast each sample against the database online. It usually takes 20 minutes per sample, 
# since the remote option is very slow. It could be a great idea to dopwnload few database at some point
rule blast:
    input: 
        lambda wildcards: get_fasta_input(wildcards)
    output: 
        "{path}/{sample}/blast/{sample}_blast.out"
    shell: 
        """
        blastn -db nt -query {input} -out {output} -remote -best_hit_overhang 0.01  -outfmt "7 qseqid stitle sseqid evalue pident qcovs length score bitscore mismatch gapopen qstart qend sstart send"
        """


def multifasta(wildcards):
    prot_fasta_list = []
    
    # wildcards.path should match every path in the prot_fasta_list
    for key, values in all_samples_dict.items():
        # Generate full sample paths
        for v in values:
            sample_path = f"{key}/{v}"
            prot_fasta_list.append(f"{sample_path}/Phold/phold_aa.fasta")
    
    # Debugging: check the generated paths
    # print("Generated input paths:", prot_fasta_list)
    return prot_fasta_list


# Here the input for the next rule is created.
rule MultiFasta_prot:
    input:
        lambda wildcards: multifasta(wildcards)
    output:
        expand("{unique_path}/multifasta/all_samples_prot.fasta", unique_path = analysis_folder_path)
    shell:
        "cat {input} > {output}"

def get_gbk_input(wildcards):
    gbk_list = []
    
    # wildcards.path should match every path in the prot_fasta_list
    for key, values in all_samples_dict.items():
        # Generate full sample paths
        for v in values:
            gbk_path = f"{key}/gbk_file/{v}"
            # print(gbk_path)
            gbk_list.append(f"{gbk_path}_phold.gbk")
    
    # Debugging: check the generated paths
    # print("Generated input paths:", gbk_list)
    # print(len(gbk_list))
    return gbk_list

# rule create_gene_to_genome:
#     input:
#         get_gbk_input
#     output:
#         expand("{unique_path}/vContact2/gene_to_genome_allphage.tsv", unique_path = analysis_folder_path)
#     run:
#         output_file = output[0]  # Getting the output file path
#         # Ensure that input is correctly referenced (it should be a list of .gbk files)
#         gbk_files = input

#         with open(output_file, 'w') as gene_to_genome:
#             gene_to_genome.write("protein_id,contig_id,keywords\n")

#             for file in gbk_files:
#                 print(file)
#                 with open(file) as gbk_file:
#                     contig_ID = ""
#                     prot_ID = ""
                    
#                     for line in gbk_file:
#                         if "LOCUS" in line:
#                             ID = line.strip('\n').split('   ',)
#                             ID_temp = ID[2].split(" ")
#                             contig_ID = ID_temp[1]
                        
#                         elif "/locus_tag" in line:
#                             prot_ID = line.replace(' ', '').replace("/locus_tag=", '').replace('"', '').strip('"').strip('\n')
                        
#                         elif "/function" in line:
#                             keywords = line.strip(' ').replace('/function=', '').replace('"','')
#                             gene_to_genome.write(f"{prot_ID},{contig_ID},{keywords}")

# rule vContact2:
#     input:
#         gene_to_genome = "{path}/vContact2/gene_to_genome_allphage.txt",
#         gbk = "{path}/multifasta/all_samples_prot.fasta"
#     output:
#         vcont = "{path}/vcontact2/all_phages"
#     conda:
#         "/home/champa/BIOINFO_Linux/PHAGE_genome_analysis/phage_genome_analysis_pipeline/Requirements/vcontact2.yml"
#     log:
#         "{path}/log/vcontact2/vcontact2.log"
#     shell:
#         """
#         vcontact2 --raw-proteins {input.gbk} --proteins-fp [input.gene_to_genome] --db 'ProkaryoticViralRefSeq211-Merged' --output-dir {output.vcont} > {log} 2>&1
#         """