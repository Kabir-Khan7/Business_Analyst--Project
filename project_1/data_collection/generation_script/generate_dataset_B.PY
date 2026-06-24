import os
import pandas as pd
import numpy as np
import random
from datetime import timedelta

# ------------------------------
# Output folder for this dataset
# ------------------------------
OUTPUT_FOLDER = "dataset_B"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# ------------------------------
# Parameters
# ------------------------------
RANDOM_SEED=42
random.seed(RANDOM_SEED); np.random.seed(RANDOM_SEED)

GROUPING_PROB=0.30
MAX_GROUP_SIZE=4
UNRECORDED_RATE=0.05
OPENING_BALANCE=10000.0

def add_business_days(date,days):
    while days>0:
        date+=timedelta(days=1)
        if date.weekday()<5: days-=1
    return date

# Read Dataset A from its folder
input_path = os.path.join('dataset_A', 'dataset_A.xlsx')
df_a = pd.read_excel(input_path, sheet_name='Subledger')
cash = df_a[(df_a['Transaction_Type'].isin(['Payment','Vendor Credit'])) & (df_a['Status']=='Posted')]
cash = cash.sort_values('Document_Date').reset_index(drop=True)

bank_rows=[]
i=0
while i<len(cash):
    group=[i]
    if random.random()<GROUPING_PROB and i+1<len(cash):
        gs=random.randint(2,min(MAX_GROUP_SIZE,len(cash)-i))
        group=list(range(i,i+gs))
    trans=cash.iloc[group]
    base=trans['Document_Date'].max()
    booking=add_business_days(base,random.randint(1,4))
    value=add_business_days(booking,random.choice([0,1]))
    total=trans['Amount'].sum()
    if len(group)==1:
        tx=trans.iloc[0]
        narrative=f"{tx['Description']} / {tx['Entity_ID']}" if pd.notna(tx['Entity_ID']) else tx['Description']
    else:
        ents=[str(e) for e in trans['Entity_ID'].dropna().unique()]
        entity_str=', '.join(ents[:3])+('...' if len(ents)>3 else '') if ents else 'multiple payments'
        narrative=f"BATCH DEPOSIT - {entity_str} ({len(group)} payments)"
    bank_rows.append({'Bank_Row_ID':len(bank_rows)+1,'Booking_Date':booking,
                      'Value_Date':value,'Transaction_Text_Narrative':narrative,
                      'Amount':total,'Running_Balance':None})
    i+=len(group)

num_unrec=int(len(bank_rows)*UNRECORDED_RATE)
if num_unrec:
    min_date=df_a['Document_Date'].min(); max_date=df_a['Document_Date'].max()
    for _ in range(num_unrec):
        rand_date=min_date+timedelta(days=random.randint(0,(max_date-min_date).days))
        while rand_date.weekday()>=5: rand_date+=timedelta(days=1)
        booking=rand_date
        value=add_business_days(booking,random.choice([0,1]))
        item=random.choices(['Bank Fee','Interest Earned','Direct Debit'],weights=[0.5,0.2,0.3])[0]
        if item=='Bank Fee':
            amount=-round(random.uniform(5,50),2); narrative=f"BANK SERVICE FEE - {random.choice(['Monthly','Wire','ACH'])}"
        elif item=='Interest Earned':
            amount=round(random.uniform(0.5,10),2); narrative="INTEREST EARNED"
        else:
            amount=-round(random.uniform(20,200),2); narrative=f"DIRECT DEBIT - {random.choice(['INSURANCE','UTILITY','LOAN'])}"
        bank_rows.append({'Bank_Row_ID':len(bank_rows)+1,'Booking_Date':booking,
                          'Value_Date':value,'Transaction_Text_Narrative':narrative,
                          'Amount':amount,'Running_Balance':None})

df_b=pd.DataFrame(bank_rows).sort_values('Booking_Date').reset_index(drop=True)
balance=OPENING_BALANCE
runs=[]
for _,row in df_b.iterrows():
    balance+=row['Amount']
    runs.append(round(balance,2))
df_b['Running_Balance']=runs

output_path = os.path.join(OUTPUT_FOLDER, 'dataset_B.xlsx')
df_b.to_excel(output_path, index=False, sheet_name='BankFeed')
print(f"Dataset B saved with {len(df_b)} rows to {output_path}")