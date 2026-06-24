import os
import pandas as pd
import random

# Output folder
OUTPUT_FOLDER = "dataset_D"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# Read Dataset A
input_path = os.path.join('dataset_A', 'dataset_A.xlsx')
# Check if dataset_A exists
if not os.path.exists(input_path):
    raise FileNotFoundError(f"Dataset A not found at {input_path}. Please run generate_dataset_A.py first.")

df_a = pd.read_excel(input_path, sheet_name='Subledger')
# Convert GL_Account_Code to string (handles both int and str)
gl_codes = df_a['GL_Account_Code'].astype(str).unique().tolist()

def classify(code):
    # Ensure code is string
    code_str = str(code)
    if code_str.isdigit():
        code_int = int(code_str)
    else:
        code_int = 0
    if 1000 <= code_int <= 1999:
        return ('Asset', 'Current Assets')
    elif 2000 <= code_int <= 2999:
        return ('Liability', 'Current Liabilities')
    elif 3000 <= code_int <= 3999:
        return ('Equity', 'Equity')
    elif 4000 <= code_int <= 4999:
        return ('Revenue', 'Operating Revenue')
    elif 5000 <= code_int <= 5999:
        return ('Expense', 'Cost of Goods Sold')
    elif 6000 <= code_int <= 6999:
        return ('Revenue', 'Other Income')
    elif 7000 <= code_int <= 7999:
        return ('Expense', 'Other Expenses')
    else:
        return ('Unknown', 'Other')

# Account names (you can extend this)
account_names = {
    '1000': 'Cash',
    '1100': 'Accounts Receivable',
    '1200': 'Inventory',
    '2000': 'Accounts Payable',
    '2100': 'Accrued Liabilities',
    '3000': 'Retained Earnings',
    '4000': 'Revenue - Services',
    '5000': 'Cost of Goods Sold',
    '6000': 'Interest Income',
    '7000': 'Miscellaneous Expense',
}
# Fill missing names
for code in gl_codes:
    if code not in account_names:
        cls, sec = classify(code)
        if cls == 'Asset':
            account_names[code] = f"Asset - {code}"
        elif cls == 'Liability':
            account_names[code] = f"Liability - {code}"
        elif cls == 'Equity':
            account_names[code] = f"Equity - {code}"
        elif cls == 'Revenue':
            account_names[code] = f"Revenue - {code}"
        elif cls == 'Expense':
            account_names[code] = f"Expense - {code}"
        else:
            account_names[code] = f"Account {code}"

records = []
for code in gl_codes:
    cls, fss = classify(code)
    records.append({
        'GL_Account_Code': code,
        'Account_Name': account_names.get(code, f"Account {code}"),
        'Account_Class': cls,
        'Financial_Statement_Section': fss
    })

# Add extra codes (optional)
extra_codes = ['1500','1600','2200','2500','3100','4500','5100','5200','6500','7500']
for code in extra_codes:
    if code not in gl_codes:
        cls, fss = classify(code)
        records.append({
            'GL_Account_Code': code,
            'Account_Name': f"Account {code}",
            'Account_Class': cls,
            'Financial_Statement_Section': fss
        })

df_d = pd.DataFrame(records).sort_values('GL_Account_Code').reset_index(drop=True)
output_path = os.path.join(OUTPUT_FOLDER, 'dataset_D.xlsx')
df_d.to_excel(output_path, index=False, sheet_name='ChartOfAccounts')
print(f"Dataset D saved with {len(df_d)} rows to {output_path}")