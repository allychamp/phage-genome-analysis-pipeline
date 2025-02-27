import os
from os import system

# Enter here the file path to your data. 
# `data_folder_path` should be assigned to the path containing the data that is to be analysed. see README for more info on the appropriate organisation¸
# of your data
analysis_path = "/home/champa/BIOINFO_Linux/PHAGE_genome_analysis/Denault_N/Result"
cat_command = f"cat '/home/champa/BIOINFO_Linux/PHAGE_genome_analysis/Denault_N/Result/multifasta'/*.fasta > {analysis_path}/multifasta_all_NDphages.fasta"
fasta_folder_path = ["/home/champa/BIOINFO_Linux/PHAGE_genome_analysis/Denault_N/Result/multifasta"]
gbk_folder_path = "/home/champa/BIOINFO_Linux/PHAGE_genome_analysis/Denault_N/Result/gbk_file"

for path in fasta_folder_path:
    system(cat_command)
     

# # Looping through all the files in the data_folder_path. There should be one folder per sample. os.listdir() returns a list of all the files
# # in the directory defiened in `data_folder_path`. Using this method, it allows the pipeline to iterate through each of those folders.
# for s in os.listdir(gbk_folder_path):
#     print("gbk file:", s)
#     # Defining the path for the specific sample. The function os.path.join() allows to join a path. In our case, we want: `data_folder_path` + the name of each sample.
#     # Because of the for loop, it will assign the `full_path` variable to each of the sample's paths one at a time. This way, the pipeline can access
#     # each sample directory
#     full_path = os.path.join(fasta_folder_path, s)
#     print("gbk path:", full_path)

#     # Verifing that the path refers to an existing directory
#     if os.path.isdir(full_path):
#         # Defining the name of the sample's file as the sample name. os.path.basename() returns a string containing the last part of the path, here, the folder corresponding to the sample's name
#         sample_name = os.path.basename(s)
#         # print(sample_name)
#         samples.append(sample_name)
#     else:
#         print('Please check your data folder path')


with open("gene_to_genome.csv", 'w') as gene_to_genome:
            gene_to_genome.write("protein_id,contig_id,keywords\n")

            for file in os.listdir(gbk_folder_path):
                if file.endswith(".gbk"):
                    print(file)
                    with open(file) as gbk_file:
                        contig_ID = ""
                        prot_ID = ""
                        
                        for line in gbk_file:
                            if "LOCUS" in line:
                                ID = line.strip('\n').split('   ',)
                                ID_temp = ID[2].split(" ")
                                contig_ID = ID_temp[1]
                            
                            elif "/locus_tag" in line: 
                                prot_ID = line.replace(' ', '').replace("/locus_tag=", '').replace('"', '').strip('"').strip('\n')
                        
                                if 'PA_S6_6' in line:
                                    print(line) 

                            elif "/function" in line:
                                keywords = line.strip(' ').replace('/function=', '').replace('"','').replace(",",";")
                                gene_to_genome.write(f"{contig_ID}:{prot_ID},{contig_ID},{keywords}")