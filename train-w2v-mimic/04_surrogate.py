from itertools import product
from multiprocessing.pool import Pool
import re
from time import time

import pandas as pd
import tqdm

nthreads = 36

path =  'mimic_iii_trigrams.parquet'
out_path = 'mimic_iii_strict_trigrams.parquet'

cauc_words = [
    'caucasian', 'white'
]

aa_words = [
    'african american', 'black', 'aa'
]

hisp_words = [
    'hispanic', 'hispanic american', 'latin x', 'latin ex', 'latina', 'latino', 'latinx'
]

modifier_words = [
    'man', 'woman', 'male', 'female', 'gentleman', 'lady', 'verteran', 'm', 'f', 'american'
]


def build_re(words, drop=[]):
    words = words + [' '.join(pair) for pair in product(words, modifier_words)]
    words = [word for word in words if word not in drop]
    words = sorted(words, key=lambda x:-len(x))
    re_str = r'((_|\b){}(_|\b))'.format(r'(_|\b))|((_|\b)'.join(words)).replace(' ', '[ _]?')
    return re.compile(re_str)


cauc_re = build_re(cauc_words, ['white'])
aa_re = build_re(aa_words, ['black', 'aa'])
hisp_re = build_re(hisp_words)
egfr_re = re.compile(r'((_|\b)egfr(_|\b))')


def surrogate(pid, nid, sent):
    if egfr_re.search(sent):
        return ''
    
    sent = cauc_re.sub(' <CAUCASIAN> ', sent)
    sent = aa_re.sub(' <AA> ', sent)
    sent = hisp_re.sub(' <HISPANIC> ', sent)
    return pid, nid, re.sub(' +', ' ', sent)

def surrogate_star(args):
    return surrogate(*args)


if __name__ == '__main__':

    df = pd.read_parquet(path)
    
    chunksize = 1000
    n = len(df)
    
    t0 = time()
    
    with Pool(nthreads) as pool:
        out = list(tqdm.tqdm(pool.imap(surrogate_star, df.values, chunksize), total=n))

    out = pd.DataFrame(out, columns=['pid', 'nid', 'sent'])
    m = out['sent'] != ''
    out[m].to_parquet(out_path)

    tf = time()
    print(tf - t0)