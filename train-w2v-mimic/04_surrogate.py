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
    'hispanic', 'hispanic american', 'latin x', 'latin ex', 'latina', 'latino', 
    'latinx'
]

modifier_words = [
    'man', 'woman', 'male', 'female', 'gentleman', 'lady', 'verteran', 'm', 'f', 
    'american'
]


def build_re(words, drop=[]):
    '''
    function to build regex. regex is built from base words + carteasean product
    of base words and modifier words. Regex catches phrases longest to shortest,
    so longest spans are always caught.

    certain phrases are exluded via 'drop' input.

    INPUTS:
        words (list of str): list of base words to build with
        drop (list of str): list of phrases to be excluded from regex

    RETURNS:
        out (re.Pattern): regex for target phrases
    '''
    # get phrases
    words = words + [' '.join(pair) for pair in product(words, modifier_words)]

    # exclude 'bad' phrases
    words = [word for word in words if word not in drop]

    # sort by length
    words = sorted(words, key=lambda x:-len(x))

    # build re (multi word phrases are agnostic to no space, ' ', and '_')
    re_str = r'((_|\b){}(_|\b))' \
               .format(r'(_|\b))|((_|\b)' \
               .join(words)) \
               .replace(' ', '[ _]?')
    return re.compile(re_str)


# regex for 3 racial groups
cauc_re = build_re(cauc_words, ['white'])
aa_re = build_re(aa_words, ['black', 'aa'])
hisp_re = build_re(hisp_words)

# regex to find mention of EGFR (removed from analysis)
egfr_re = re.compile(r'((_|\b)egfr(_|\b))')


def surrogate(pid, nid, sent):
    '''
    function to surrogate racial phrases.
    return empty str for sentences with mention of EGFR.

    INPUTS:
        pid (str): patient identifier
        nid (str): note identifier
        sent (str): sentence to be surrogated

    RETURNS:
        pid (str): patient identifier
        nid (str): note identifier
        out (str): surrogated sentence
    '''
    # drop text for EGFR mentions
    if egfr_re.search(sent):
        return ''
    
    # surogate racial groups
    sent = cauc_re.sub(' <CAUCASIAN> ', sent)
    sent = aa_re.sub(' <AA> ', sent)
    sent = hisp_re.sub(' <HISPANIC> ', sent)

    # regex may add extra space characters -- convert to single space
    return pid, nid, re.sub(' +', ' ', sent)


def surrogate_star(args):
    '''
    syntactic salt to make imap + tqdm progress bar work
    '''
    return surrogate(*args)


if __name__ == '__main__':

    # load in data
    df = pd.read_parquet(path)
    
    chunksize = 1000
    n = len(df)
    
    t0 = time()
    
    # surrogate sentences (parallelized)
    with Pool(nthreads) as pool:
        out = list(tqdm.tqdm(pool.imap(surrogate_star, df.values, chunksize), 
                             total=n))

    # convert list of lists to dataframe and dump.
    # drop any empty sentences.
    out = pd.DataFrame(out, columns=['pid', 'nid', 'sent'])
    m = out['sent'] != ''
    out[m].to_parquet(out_path)

    tf = time()
    print(tf - t0)