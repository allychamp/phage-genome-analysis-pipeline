import argparse
import csv
import re
import sys
from pathlib import Path
import pandas as pd 

empathi_cat = {
    "pvp":{"capsid":{"major_capsid","minor_capsid"}, "tail":{"major_tail", "minor_tail", "tail_appendage","tail_sheath", "baseplate"}},
    "DNA-associated":{},
    "transcriptional_regulator":{},
    "lysis":{},
}

def winner_func(function_list, dataframe, idx):
    prob = 0
    petit = None
    for i in range(len(function_list)):
        data = dataframe[function_list[i]].iloc[idx]
        # print(data, function_list[i])
        if data > prob:
            prob = data
            function = function_list[i] 
            
        elif data == prob:
            function = "Unassigned"
        else:
            continue
   
    return function 

def find_best_function(csv_file):
    def_syst = ["toxin", "anti-restriction", "sir2", "crispr", "super_infection"]
    df = pd.read_csv(csv_file, delimiter=',')
    csv_path = Path(csv_file).resolve()
    df['Best_function'] = None
    for index, row in df.iterrows():
        function = []
        # print(row[0])
        if "|" in row["Annotation"]:
            # print(index)
            temp_function = []
            full_func = {}
            complet_annot = row["Annotation"].split("|")
            idx = 0
            while idx < len(complet_annot):
                i = complet_annot[idx]
                if empathi_cat.get(i) != None and idx + 1 < len(complet_annot):
                    idx = idx + 1
                    sub_categorie = i
                    
                    if complet_annot[idx] in empathi_cat.get(sub_categorie):
                        sub_function = complet_annot[idx]
                        
                        if idx + 1 < len(complet_annot):
                            idx = idx + 1
                            temp_function.append(complet_annot[idx])
                            full_func[sub_function] = str(temp_function[0])
                            idx = idx + 1
                            # print(full_func)
                        else: 
                            continue
                    else: 
                        continue
                else: 
                    temp_function.append(i)
                idx = idx + 1
            function = winner_func(temp_function, df, index)
            # print(index,function)
            if function in empathi_cat["pvp"]["capsid"]:
                df.at[index,'Best_function'] = "pvp|capsid|" + function
            elif function in empathi_cat["pvp"]["tail"]:
                df.at[index,'Best_function'] = "pvp|tail|" + function
            elif function in def_syst:
                df.at[index,'Best_function'] = "defense-systems|" + function
                print(df.at[index,'Best_function'])
            else: 
                df.at[index,'Best_function'] = function
        else:
            if row["Annotation"] in def_syst:
                # print(row["Annotation"] )
                df.at[index,'Best_function'] = "defense-systems|" + row["Annotation"] 
                print(df.at[index,'Best_function'])
            else:
                function = row["Annotation"]
                df.at[index,'Best_function'] = function

        Categories = {'capsid': 'pvp', 'tail': 'pvp', 'portal': 'pvp', 'head-tail_joining': 'pvp', 
              'collar': 'pvp', 'head-tail joinning': 'pvp', 'helicase': 'DNA-associated', 
               'nuclease': 'DNA-associated', 'terminase': 'DNA-associated', 
               'integration': 'DNA-associated', 'DNA_polymerase': 'DNA-associated', 
               'annealing': 'DNA-associated', 'primase': 'DNA-associated', 
               'replication_initiation': 'DNA-associated', 
               'transcriptional_activator': 'transcriptional_regulator', 
               'transcriptional_repressor': 'transcriptional_regulator', 
               'endolysin': 'lysis', 'spanin': 'lysis', 'holin': 'lysis', 
               'lysis_inhibitor': 'lysis'}
        annotations = {}
        def make_annotation(locus, best_func):
            if pd.isna(best_func):
                return best_func  # will be caught as empty later
            category = Categories.get(best_func.split('|')[0] if '|' in best_func else best_func)
            if category:
                return f"{category}|{best_func}"
            return best_func  # no category found, keep as-is

        annotations = {row["Unnamed: 0"]: make_annotation(row["Unnamed: 0"], row["Best_function"]) 
                       for _, row in df.iterrows()}
            
    print(f"[INFO] Loaded {len(annotations)} annotations from '{csv_path}'")
    # print(annotations)
    print(f"[DEBUG] Rows with Best_function set: {df['Best_function'].notna().sum()} / {len(df)}")
    return annotations


def annotate_gbk(gbk_path: str, annotations: dict, tag_name: str) -> tuple:
    with open(gbk_path) as f:
        lines = f.readlines()

    out_lines = []
    i = 0
    stats = {"updated": 0, "no_annotation": 0, "not_in_csv": 0, "empty_value": 0}

    while i < len(lines):
        line = lines[i]

        if re.match(r'\s{5}CDS\s+', line):
            feature_lines = [line]
            i += 1

            while i < len(lines):
                next_line = lines[i]
                if re.match(r'\s{5}\S', next_line) or re.match(r'ORIGIN', next_line):
                    break
                feature_lines.append(next_line)
                i += 1

            # Extract locus tag
            locus = None
            func_idx = [idx for idx, f in enumerate(feature_lines) if "/function" in f]
            if len(func_idx) > 1:
                del feature_lines[max(func_idx)]
            for fl in feature_lines:
                m = re.search(rf'/{tag_name}="([^"]+)"', fl)
                if m:
                    locus = m.group(1)
                    break

            if locus is None:
                stats["no_annotation"] += 1
            elif locus not in annotations:
                stats["not_in_csv"] += 1
                print(f"[WARN] Locus tag '{locus}' not found in EMPATHI CSV — skipping")
            else:
                new_value = annotations[locus]
                if not new_value or (isinstance(new_value, float) and pd.isna(new_value)):
                    stats["empty_value"] += 1
                    print(f"[WARN] Empty annotation for '{locus}' — /function left unchanged")
                else:
                    # Join into one string to handle multi-line /function= values
                    block = "".join(feature_lines)
                    if '/function=' in block:
                        block = re.sub(
                            r'/function=".*?"',
                            f'/function="{new_value}"',
                            block,
                            count=1,
                            flags=re.DOTALL
                        )
                        stats["updated"] += 1
                    else:
                        # No /function= at all — insert after locus_tag line
                        new_feature_lines = []
                        inserted = False
                        for fl in feature_lines:
                            new_feature_lines.append(fl)
                            if not inserted and f'/{tag_name}=' in fl:
                                indent = ' ' * 21
                                new_feature_lines.append(f'{indent}/function="{new_value}"\n')
                                inserted = True
                        block = "".join(new_feature_lines)
                        if inserted:
                            stats["updated"] += 1
                    feature_lines = [block]

            out_lines.extend(feature_lines)
            continue

        out_lines.append(line)
        i += 1

    return "".join(out_lines), stats

def main():
    parser = argparse.ArgumentParser(
        description="Annotate a GenBank file with EMPATHI functional predictions."
    )
    parser.add_argument("-g", "--gbk-file",  required=True, dest="gbk_file",
                        help="Input GenBank file (.gbk)")
    parser.add_argument("-c", "--csv-file",  required=True, dest="csv_file",
                        help="EMPATHI predictions CSV file")
    parser.add_argument("-o", "--out-file",  required=True, dest="out_file",
                        help="Output annotated GenBank file")
    parser.add_argument(
        "--tag", default="locus_tag",
        help="Qualifier name used as CDS identifier in the GBK (default: locus_tag)"
    )
    args = parser.parse_args()

    # Validate input files
    for path, label in [(args.gbk_file, "GenBank"), (args.csv_file, "CSV")]:
        if not Path(path).is_file():
            sys.exit(f"[ERROR] {label} file not found: '{path}'")

    annotations =  find_best_function(args.csv_file)
    annotated_text, stats = annotate_gbk(args.gbk_file, annotations, args.tag)

    with open(args.out_file, "w") as f:
        f.write(annotated_text)

    print(f"\n[DONE] Results written to '{args.out_file}'")
    print(f"       CDS updated:          {stats['updated']}")
    print(f"       Empty annotation:     {stats['empty_value']}")
    print(f"       Not in CSV:           {stats['not_in_csv']}")
    print(f"       No locus tag in GBK:  {stats['no_annotation']}")


if __name__ == "__main__":
    main()