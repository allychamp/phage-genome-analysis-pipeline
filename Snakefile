# Importing the needed module
import os

# Enter here the file path to your data. cd 
# `data_folder_path` should be assigned to the path containing the data that is to be analysed. see README for more info on the appropriate organisation¸
# of your data
data_folder_path = "/Raw_data/samples"
# `analysis_folder_path` should contain a list of one path (in string) to the desired output directory 
analysis_folder_path = ["Analysis"] # This absolutely needs to be a list

#Please change this path to download the databases in the desired location
DB = "/DataBase"

# Defining the path for all the conda envs. It doesn't need to be changed if the working directory is in the repository file.
vir_genome = "Requirements/vir_genome.yml"
pharokka = "Requirements/pharokka.yml"
empathi = "Requirements/empathi_env.yml"


# First the data is being organized so the pipeline will be executed for each sample in the data folder. Every fasta file in each sample folder will
# be analyzed for this specific sample (see README.md).
# Defining an empty list that will contain the sample's name
samples = []

# Looping through all the files in the data_folder_path. There should be one folder per sample. os.listdir() returns a list of all the files
# in the directory defiened in `data_folder_path`. Using this method, it allows the pipeline to iterate through each of those folders.
for s in os.listdir(data_folder_path):
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


rule all:
    # The directive 'input' tells snakemake which files should be used as inputs in the rule
    input:
        # The expand() command allows you to iterate through all the file that matches the wildcards. The 'path' wildcard refers to 
        # the 'analysis_folder_path' variable defined earlier. Sample is defined as each element in the samples list created earlier
        expand("{path}/{sample}/Empathi/{sample}_updated.gbk",
            path = analysis_folder_path,
            sample = samples,
        ),
        expand("{path}/{sample}/Pharokka",
            path = analysis_folder_path,
            sample = samples,
        ),
        expand("{path}/gbk_file/{sample}_empathi.gbk",
            path = analysis_folder_path,
            sample = samples,
        ),
        expand("{path}/{sample}/Phold",
            path = analysis_folder_path,
            sample = samples,
        )
        # expand("{path}/{sample}/blast/{sample}_blast.out",
        #     path = analysis_folder_path,
        #     sample = samples)

# The input of this rule is a lambda function used to dynamically create file paths based on the values of wildcards. Here, each wildcard (sample)
# will be passed to the function, creating the path associated with it. In other words, the pipeline will input each consensus.fasta file regarding each sample.

rule DB_download:
    # There is no input for this rule since databases is simply downloaded in bash command line. It should only be done once since there are no wildcards associated with this rule.
    # The output pharokka is defined to contain pharokka's database
    output:
        pharokka = directory(f"{DB}/Pharokka_1.8/"),
        phold = directory(f"{DB}/Phold_DB")
    # Since the command to download the database is specific , I also use geNomad environment here. Of course, this environment is available 
    # in the Requirements folder of the repository.
    conda: 
       pharokka
    # A message is printed in the terminal so the user can follow what the pipeline is currently doing
    message:
       "Downloading databases"
    shell:
        # In the shell I download Pharokka and Phold DB using the appropriate command
        """
        install_databases.py -o {output.pharokka} 
        &&
        phold install -d {output.phold}
        """ 

# The first tool used is Pharokka. This tools allows to annotate phages genome using the fasta file
rule pharokka:
    input: 
        lambda wildcards: f"{data_folder_path}/{wildcards.sample}/{wildcards.sample}.fasta"
    # The output of this tool is a directory (defined by the all output). Later in the pipeline we will need the gbk file. This file is defiened as the "phold"
    # output because Phold is the tool that need a gbk file.
    output: 
        all = directory("{path}/{sample}/Pharokka/"),
        empathi= "{path}/{sample}/Pharokka/{sample}.gbk",
        dnaapler = "{path}/{sample}/Pharokka/{sample}_dnaapler_reoriented.fasta",
        no_dnaapler = "{path}/{sample}/Pharokka/phanotate.faa",
        # empathi = "{path}/{sample}/Pharokka/phanotate.faa"
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
        pharokka
    shell: "pharokka.py -i {input} -d {params.DB_folder}/Pharokka_1.8 --dnaapler -e {params.evalue} -p {wildcards.sample} -l Pharokka_{wildcards.sample} -o {output.all} -f > {log} 2>&1" 
        
rule Empathi:
    input: "{path}/{sample}/Pharokka/phanotate.faa"

    output: "{path}/{sample}/Empathi/{sample}/predictions_{sample}.csv"

    message:
        "Annotation of {wildcards.sample} with Empathi"

    log:
        "{path}/{sample}/log/Empathi/{sample}.log"

    conda: 
        empathi

    params:
        path_to_model = "empathi/models",
        outdir = "{path}/{sample}/Empathi/"

    shell: 
        """
        python3 empathi/src/empathi/empathi.py {input} {wildcards.sample} \
            -o {params.outdir} \
            --threads 12 \
            --models_folder {params.path_to_model} \
            2> {log}
        """

rule update_gbk:
    input: 
        table = "{path}/{sample}/Empathi/{sample}/predictions_{sample}.csv",
        gbk = "{path}/{sample}/Pharokka/{sample}.gbk"
    output: "{path}/{sample}/Empathi/{sample}_updated.gbk"
    shell: 
        "python3 Requirements/updated_gbk_from_empathi_annot.py -g {input.gbk} -c {input.table} -o {output}"

rule Phold:
    input:  "{path}/{sample}/Pharokka/{sample}.gbk"
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
        
    shell: 
        """
        phold run -i {input} -o {output.all} -d {params.DB_folder}/Phold_DB -f > {log} 2>&1
        """

# Last, here is two simples rules that will allow the rest of the analysis (visualisation) to be way easier. Essentially it takes all the gbk file ouputed 
# by phold, it copies them into a folder and it adds the sample name in the file name. The second one takes all the amino_acid file and copy them into a folder
rule copy_data_gbk: 
    input: 
        gbk = "{path}/{sample}/Empathi/{sample}_updated.gbk", 
        
    output: 
        all_gbk = "{path}/gbk_file/{sample}_empathi.gbk",
    shell:
        """
        cp {input.gbk} {output.all_gbk} 
        """

def get_fasta_input(wildcards):
    fasta_path = f"{wildcards.path}/{wildcards.sample}/Pharokka/{wildcards.sample}_dnaapler_reoriented.fasta"
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
