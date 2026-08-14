import pathlib
import os

print(os.getcwd())
os.chdir('/home/champa/DATA/PHAGE_genome_analysis/SUS-Paul_Champoux-A_Chenard_A/Analysis_05052026/vContact2_redo')

os.chdir('/home/champa/DATA/PHAGE_genome_analysis/SUS-Paul_Champoux-A_Chenard_A/Analysis_05052026/sample_gbk')
with open( 'gene-to-genome_allECphages_redo.txt', 'w') as mapping_file:
    mapping_file.write("protein_id,contig_id,keywords\n")
    
    dir = os.getcwd()
    for file in os.listdir(dir):
        with open(os.path.join(dir, file)) as gbk_file:
            for line in gbk_file:
                if "LOCUS" in line:
                    # print(line)
                    ID = line.strip('\n').split('       ')
                    print(ID)
                    contig_ID = ID[1]
                    # print(contig_ID)
                    # mapping_file.write(prot_ID,',')

                elif "/locus_tag" in line:
                    # print(line)
                    prot_ID = line.replace(' ', '').replace("/locus_tag=", '').strip('"').strip('\n').strip('"')
                    # print(prot_ID)
                    # print(prot_ID,contig_ID)
                    
                
                elif "/function" in line:
                    keywords = line.strip(' ').replace('/function=','')
                    # mapping_file.write("{},\n".format(keywords))
                    # print(keywords)
                    mapping_file.write("{},{},{}".format(prot_ID,contig_ID,keywords))
