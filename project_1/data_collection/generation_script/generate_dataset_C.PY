import os
import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# ------------------------------
# Output folder for this dataset
# ------------------------------
OUTPUT_FOLDER = "dataset_C"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# ------------------------------
RANDOM_SEED=42
random.seed(RANDOM_SEED); np.random.seed(RANDOM_SEED)

# Read Dataset A to get existing Entity_IDs
input_path = os.path.join('dataset_A', 'dataset_A.xlsx')
df_a = pd.read_excel(input_path, sheet_name='Subledger')
existing_entities = df_a['Entity_ID'].dropna().unique().tolist()

extra_count = int(len(existing_entities) * 0.3)
all_entity_ids = set(existing_entities)

company_suffixes = ['Inc','LLC','Ltd','Corp','PK','Pakistan','PVT','S.A.']
company_types = ['Logistics','Trading','Consulting','Tech','Services','Manufacturing','Distribution']
name_parts = ['Alpha','Beta','Gamma','Delta','Epsilon','Zeta','Eta','Theta','Iota','Kappa',
              'Lambda','Mu','Nu','Xi','Omicron','Pi','Rho','Sigma','Tau','Upsilon','Phi','Chi','Psi','Omega']

def generate_entity_details(entity_id):
    prefix = random.choice(name_parts)
    suffix = random.choice(company_types)
    legal = f"{prefix} {suffix} {random.choice(company_suffixes)}"
    trade = f"{prefix} {suffix}"
    tax = f"TAX-{random.randint(100000,999999)}"
    country = random.choice(['US','PK','AE','GB','DE','FR','IN'])
    creation = datetime.now() - timedelta(days=random.randint(30, 365*5))
    active = random.choice([True, False])
    return {
        'Legal_Name': legal,
        'Trade_Name': trade,
        'Tax_Registration_Number': tax,
        'Country_Code': country,
        'Account_Creation_Date': creation,
        'Is_Active': active
    }

records = []
for eid in existing_entities:
    detail = generate_entity_details(eid)
    detail['Entity_ID'] = eid
    records.append(detail)

for _ in range(extra_count):
    while True:
        prefix = random.choice(['CUST','VEND'])
        num = random.randint(1000,9999)
        new_id = f"{prefix}_{num}"
        if new_id not in all_entity_ids:
            all_entity_ids.add(new_id)
            break
    detail = generate_entity_details(new_id)
    detail['Entity_ID'] = new_id
    records.append(detail)

# Near-duplicates
dup_indices = random.sample(range(len(records)), min(5, len(records)))
for idx in dup_indices:
    orig = records[idx]
    prefix = orig['Entity_ID'].split('_')[0]
    while True:
        new_num = random.randint(1000,9999)
        new_id2 = f"{prefix}_{new_num}"
        if new_id2 not in all_entity_ids:
            all_entity_ids.add(new_id2)
            break
    legal = orig['Legal_Name']
    if 'PK' in legal:
        legal = legal.replace('PK', 'Pakistan')
    elif 'Pakistan' in legal:
        legal = legal.replace('Pakistan', 'PK')
    else:
        legal = legal + ' ' + random.choice(['PK','Ltd','Corp'])
    dirty_legal = legal + random.choice(['   ', '\t', '\n', ' \n'])
    trade = orig['Trade_Name'] + random.choice(['  ', '\t'])
    dup_rec = {
        'Entity_ID': new_id2,
        'Legal_Name': dirty_legal,
        'Trade_Name': trade,
        'Tax_Registration_Number': orig['Tax_Registration_Number'],
        'Country_Code': orig['Country_Code'],
        'Account_Creation_Date': orig['Account_Creation_Date'] + timedelta(days=random.randint(1,30)),
        'Is_Active': orig['Is_Active']
    }
    records.append(dup_rec)

df_c = pd.DataFrame(records)
for idx in random.sample(range(len(df_c)), int(len(df_c)*0.1)):
    df_c.at[idx, 'Legal_Name'] = df_c.at[idx, 'Legal_Name'] + random.choice(['   ', '\t', '\n'])
    df_c.at[idx, 'Trade_Name'] = df_c.at[idx, 'Trade_Name'] + random.choice(['  ', '\t'])

df_c = df_c.sample(frac=1).reset_index(drop=True)
output_path = os.path.join(OUTPUT_FOLDER, 'dataset_C.xlsx')
df_c.to_excel(output_path, index=False, sheet_name='MasterDirectory')
print(f"Dataset C saved with {len(df_c)} rows to {output_path}")