from math import floor

import pandas as pd

path_subset = 'mimic_note_counts_JMC inclusions.csv'
path_notes = 'NOTEEVENTS.csv'
path_out = 'NOTEEVENTS_subset.parquet'

df = pd.read_csv(path_subset)

pa = pd.read_csv('PATIENTS.csv', dtype=str)
ages = st[['SUBJECT_ID', 'HADM_ID', 'ICUSTAY_ID', 'INTIME']].merge(pa[['SUBJECT_ID', 'DOB', 'GENDER']], on='SUBJECT_ID')
ages['age'] = [floor(d.days/365) for d in ((pd.to_datetime(ages['INTIME']).dt.date - pd.to_datetime(ages['DOB']).dt.date))]
hadms = ages.loc[ages['age'] >= 18, 'HADM_ID']

keepers = df.loc[df['INCLUDE (1=yes; 0=no)'] == 1, ['CATEGORY', 'DESCRIPTION']]

notes = pd.read_csv(path_notes, dtype=str)

m = notes[['CATEGORY', 'DESCRIPTION']].isin(keepers)
m = notes['CATEGORY'].isin(keepers['CATEGORY']) \
  & notes['DESCRIPTION'].isin(keepers['DESCRIPTION']) \
  & notes['HADM_ID'].isin(hadms)

notes[m].to_parquet(path_out)