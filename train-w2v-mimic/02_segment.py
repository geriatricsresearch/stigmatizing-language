import os

from multiprocessing.pool import Pool
import re
import string
from time import time

import nltk
nltk.download('punkt')
from nltk.tokenize import sent_tokenize
import pandas as pd

path = 'NOTEEVENTS_subset.parquet'
path_out = 'mimic_sents.parquet'
nthreads = 24

regex_phi = re.compile(r'\[\*\*(.*?)\*\*\]')
regex_valid_chars = re.compile(r'[^a-z1-9 ]')
regex_ws = re.compile(r'\s+')


def process_sent(sent):
    sent = re.sub(regex_phi, '*****', sent).lower()
    sent = sent.lower()
    sent = re.sub(regex_ws, ' ', sent)
    return re.sub(regex_valid_chars, '', sent)


def prep_sents(pid, nid, text):
    text = ''.join(c if c in string.printable else ' ' for c in text)
    return pid, nid, [process_sent(sent) for sent in sent_tokenize(text)]

if __name__ == '__main__':

    df = pd.read_parquet(path)

    t0 = time()

    out = []
    with Pool(nthreads) as pool:
        for result in pool.starmap(prep_sents, df[['SUBJECT_ID', 'ROW_ID', 'TEXT']].values, 1000):
            for sent in result[2]:
                out.append([result[0], result[1], sent])

    out = pd.DataFrame(out, columns=['pid', 'nid', 'sent'])
    out.to_parquet('mimic_sents.parquet')

    tf = time()
    print(tf - t0)