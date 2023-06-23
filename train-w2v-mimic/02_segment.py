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

# regexes for MIMIC-iii PHI tags, alphanumeric chars, and whitespace
regex_phi = re.compile(r'\[\*\*(.*?)\*\*\]')
regex_valid_chars = re.compile(r'[^a-z1-9 ]')
regex_ws = re.compile(r'\s+')


def process_sent(sent):
    '''
    function to process sentence.
      * convert to lower case
      * replace the MIMIC-iii PHI tags with '*****'
      * replace contiguous whitespace with a single ' '
      * drop all non alphanumeric characters

    INPUTS:
        sent(str): sentnece to be processed

    RETURNS:
        out (str): processed sentence
    '''
    sent = re.sub(regex_phi, '*****', sent).lower()
    sent = sent.lower()
    sent = re.sub(regex_ws, ' ', sent)
    return re.sub(regex_valid_chars, '', sent)


def prep_sents(pid, nid, text):
    '''
    function to split text into sentences and process each sentence.

    INPUTS:
        pid (str): patient identifier
        nid (str): note identifier
        text (str): note text

    RETURNS:
        pid (str): patient identifier
        nid (str): note identifier
        out (list of str): list of processed sentences
    '''
    # filter out 'bad' characters
    text = ''.join(c if c in string.printable else ' ' for c in text)

    # segment and process each sentence
    return pid, nid, [process_sent(sent) for sent in sent_tokenize(text)]


if __name__ == '__main__':
    # read in data
    df = pd.read_parquet(path)

    t0 = time()

    #iterate over all notes (parallelized)
    out = []
    data =  df[['SUBJECT_ID', 'ROW_ID', 'TEXT']].values
    with Pool(nthreads) as pool:
        for result in pool.starmap(prep_sents, data, 1000):
            for sent in result[2]:
                out.append([result[0], result[1], sent])

    # convert list of lists to dataframe and dump
    out = pd.DataFrame(out, columns=['pid', 'nid', 'sent'])
    out.to_parquet('mimic_sents.parquet')

    tf = time()
    print(tf - t0)