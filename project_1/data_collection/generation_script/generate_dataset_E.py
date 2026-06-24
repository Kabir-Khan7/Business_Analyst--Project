import os
import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# ------------------------------
# Output folder for this dataset
# ------------------------------
OUTPUT_FOLDER = "dataset_E"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# ------------------------------
RANDOM_SEED=42
random.seed(RANDOM_SEED); np.random.seed(RANDOM_SEED)

# Read Master Directory (Dataset C)
input_path = os.path.join('dataset_C', 'dataset_C.xlsx')
df_c = pd.read_excel(input_path, sheet_name='MasterDirectory')
vendors = df_c[df_c['Entity_ID'].str.startswith('VEND')]['Entity_ID'].tolist()
if not vendors:
    vendors = df_c['Entity_ID'].tolist()

selected_vendors = random.sample(vendors, min(20, len(vendors)))

items_pool = [
    ('Consulting Services', 100, 500),
    ('Product A', 50, 200),
    ('Product B', 30, 150),
    ('Maintenance Plan', 200, 1000),
    ('Training Session', 150, 300),
    ('Software License', 500, 2000),
    ('Hardware', 300, 800),
    ('Shipping', 20, 100),
]

def generate_invoice(vendor_id, invoice_num):
    # Per-vendor layout style (consistent)
    vendor_seed = hash(vendor_id) % 1000
    random.seed(vendor_seed)
    layout_style = random.choice(['top_total', 'bottom_total', 'top_total_with_tax', 'bottom_total_with_tax'])
    random.seed(RANDOM_SEED)  # reset

    num_lines = random.randint(2, 6)
    lines = []
    total_net = 0
    for _ in range(num_lines):
        desc, min_price, max_price = random.choice(items_pool)
        qty = random.randint(1, 10)
        unit = round(random.uniform(min_price, max_price), 2)
        line_total = round(qty * unit, 2)
        total_net += line_total
        lines.append((desc, qty, unit, line_total))
    tax_rate = random.choice([0, 5, 10, 15])
    tax = round(total_net * tax_rate / 100, 2)
    grand_total = total_net + tax

    invoice_date = datetime.now() - timedelta(days=random.randint(1, 90))
    vendor_name = df_c[df_c['Entity_ID'] == vendor_id]['Legal_Name'].values[0]
    vendor_name_clean = vendor_name.replace('\n','').replace('\t','').strip()

    lines_text = ""
    for desc, qty, unit, line_total in lines:
        lines_text += f"{desc:30} {qty:3} x {unit:8.2f} = {line_total:10.2f}\n"

    if layout_style == 'top_total':
        raw = f"""INVOICE #{invoice_num}
Vendor: {vendor_name_clean}
Date: {invoice_date.strftime('%Y-%m-%d')}

TOTAL NET: {total_net:.2f}
TAX: {tax:.2f}
GRAND TOTAL: {grand_total:.2f}

Items:
{lines_text}
"""
    elif layout_style == 'bottom_total':
        raw = f"""INVOICE #{invoice_num}
Vendor: {vendor_name_clean}
Date: {invoice_date.strftime('%Y-%m-%d')}

Items:
{lines_text}

TOTAL NET: {total_net:.2f}
TAX: {tax:.2f}
GRAND TOTAL: {grand_total:.2f}
"""
    elif layout_style == 'top_total_with_tax':
        raw = f"""INVOICE #{invoice_num}
Vendor: {vendor_name_clean}
Date: {invoice_date.strftime('%Y-%m-%d')}

TOTAL (incl. tax): {grand_total:.2f}

Items:
{lines_text}
"""
    else:  # bottom_total_with_tax
        raw = f"""INVOICE #{invoice_num}
Vendor: {vendor_name_clean}
Date: {invoice_date.strftime('%Y-%m-%d')}

Items:
{lines_text}

TOTAL (incl. tax): {grand_total:.2f}
"""
    return {
        'Vendor_ID': vendor_id,
        'Vendor_Name': vendor_name_clean,
        'Invoice_Number': invoice_num,
        'Invoice_Date': invoice_date,
        'Line_Item_Description': ', '.join([d for d,_,_,_ in lines]),
        'Line_Item_Quantity': ', '.join([str(q) for _,q,_,_ in lines]),
        'Line_Item_Unit_Price': ', '.join([str(u) for _,_,u,_ in lines]),
        'Total_Tax': tax,
        'Grand_Total': grand_total,
        'Raw_Text': raw
    }

invoice_counter = 1
invoice_data = []
for vendor in selected_vendors:
    num_inv = random.randint(3, 7)
    for _ in range(num_inv):
        inv_num = f"INV-{invoice_counter:05d}"
        inv = generate_invoice(vendor, inv_num)
        invoice_data.append(inv)
        invoice_counter += 1

df_e = pd.DataFrame(invoice_data)
output_path = os.path.join(OUTPUT_FOLDER, 'dataset_E.xlsx')
df_e.to_excel(output_path, index=False, sheet_name='Invoices')
print(f"Dataset E saved with {len(df_e)} invoices to {output_path}")