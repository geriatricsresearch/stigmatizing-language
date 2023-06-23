from math import floor

import pandas as pd

path_subset = 'mimic_note_counts_JMC inclusions.csv'
path_notes = 'NOTEEVENTS.csv'
path_icu_stay = 'ICUSTAYS.csv'
path_patients = 'PATIENTS.csv'
path_out = 'NOTEEVENTS_subset.parquet'

# read in files
df = pd.read_csv(path_subset)
st = pd.read_csv(path_icu_stay, dtype=str)
pa = pd.read_csv(path_patients, dtype=str)
notes = pd.read_csv(path_notes, dtype=str)

# get ages, and keep adults
ages = st[['SUBJECT_ID', 'HADM_ID', 'ICUSTAY_ID', 'INTIME']] \
         .merge(pa[['SUBJECT_ID', 'DOB', 'GENDER']], on='SUBJECT_ID')
tf = pd.to_datetime(ages['INTIME']).dt.date
t0 = pd.to_datetime(ages['DOB']).dt.date
ages['age'] = [floor(d.days/365) for d in (tf - t0)]
hadms = ages.loc[ages['age'] >= 18, 'HADM_ID']

# get appropriatee note types
keepers = df.loc[df['INCLUDE (1=yes; 0=no)'] == 1, ['CATEGORY', 'DESCRIPTION']]

# slect the 'good' notes
m = notes[['CATEGORY', 'DESCRIPTION']].isin(keepers)
m = notes['CATEGORY'].isin(keepers['CATEGORY']) \
  & notes['DESCRIPTION'].isin(keepers['DESCRIPTION']) \
  & notes['HADM_ID'].isin(hadms)

# save
notes[m].to_parquet(path_out)