import os
import pandas as pd
import numpy as np
import uuid
import random
from datetime import datetime, timedelta

# ------------------------------
# Output folder for this dataset
# ------------------------------
OUTPUT_FOLDER = "dataset_A"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# ------------------------------
# Generation parameters
# ------------------------------
NUM_ROWS = 1000
RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

GL_ACCOUNTS = ['1000','1100','1200','2000','2100','3000','4000','5000','6000','7000']
TRANSACTION_TYPES = ['Invoice','Payment','Bill','Vendor Credit']
STATUSES = ['Posted','Pending','Draft']
PAYMENT_DESCRIPTIONS = ['Online payment','Wire transfer','Check #1234',
                        'Credit card payment','ACH transfer','Refund','Payment receipt']

def random_date(start,end):
    return start + timedelta(seconds=random.randint(0, int((end-start).total_seconds())))

def random_entity_id():
    return f"{random.choice(['CUST','VEND'])}_{random.randint(1000,9999)}"

def random_amount():
    return round(random.uniform(-5000,-10),2) if random.random()<0.2 else round(random.uniform(10,10000),2)

def random_description(trans_type):
    if trans_type in ['Payment','Vendor Credit']:
        base = random.choice(PAYMENT_DESCRIPTIONS)
        case = random.choice(['lower','upper','title','capitalize','swap'])
        if case=='lower': return base.lower()
        if case=='upper': return base.upper()
        if case=='title': return base.title()
        if case=='capitalize': return base.capitalize()
        return base.swapcase()
    return f"{trans_type} - {random.choice(['Services','Products','Consulting','Maintenance'])}"

data=[]
end_date=datetime.now()
start_date=end_date-timedelta(days=90)

for _ in range(NUM_ROWS):
    tx_id=str(uuid.uuid4())
    system_ts=random_date(start_date,end_date)
    if random.random()<0.10:
        max_back=min(30,(system_ts-start_date).days)
        back_days=random.randint(1,max(1,max_back))
        doc_date=system_ts-timedelta(days=back_days)
    else:
        doc_date=system_ts
    gl=random.choice(GL_ACCOUNTS)
    entity=random_entity_id() if random.random()>=0.05 else None
    amount=random_amount()
    ttype=random.choice(TRANSACTION_TYPES)
    status=random.choice(STATUSES)
    desc=random_description(ttype)
    data.append({'Transaction_ID':tx_id,'System_Timestamp':system_ts,'Document_Date':doc_date,
                 'GL_Account_Code':gl,'Entity_ID':entity,'Amount':amount,
                 'Transaction_Type':ttype,'Status':status,'Description':desc})

df=pd.DataFrame(data).sort_values('System_Timestamp').reset_index(drop=True)
output_path = os.path.join(OUTPUT_FOLDER, 'dataset_A.xlsx')
df.to_excel(output_path, index=False, sheet_name='Subledger')
print(f"Dataset A saved with {len(df)} rows to {output_path}")