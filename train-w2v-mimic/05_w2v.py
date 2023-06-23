import random

from gensim.models import Word2Vec
import numpy as np
import pandas as pd

fpath = 'mimic_iii_strict_trigrams.parquet'
path = 'w2v_boot_m3/'

nthreads = 24

nshuff = 20
nboot = 50

epochs = 5
dimension = 300
window = 25


def bootstrap_txt(df, i):
    '''
    function to bootstrap text. bootstrapped on patient level.
    if original ('og') pass through as is.

    INPUTS:
        df (pd.DataFrame): dataframe of sentences
        i (int): value for bootstrap random seed

    RETURNS:
        None
    '''
    if i != 'og':
        # set seed
        np.random.seed(i + 42)
        
        n = len(df)

        # select patients
        pids = df['pid'].drop_duplicates()
        pids = set(pids.iloc[np.random.randint(len(pids), size=len(pids))])

        # sample sentences from patients
        df = df[df['pid'].isin(pids)].copy()
        sents = df['sent'].iloc[np.random.randint(len(df), size=n)]
    else:
        sents = df['sent']

    # save sentences
    with open('bs_sents.txt_{}'.format(i), 'w+') as fp:
        for sent in sents:
            if sent[-1] != '\n':
                sent += '\n'
            fp.write(sent)


def shuffle_txt(i, j):
    '''
    function to shuffle bootstrapped sentnces

    INPUTS:
        i (int): value for bootstrap random seed
        j (int): value for shuffle random seed

    OUTPUTS:
        None
    '''
    # read sentences in
    with open('bs_sents.txt_{}'.format(i)) as fp:
        sents = fp.readlines()
    #set seed and shuffle
    random.Random(j).shuffle(sents)
    with open('sh_sents.txt_{}'.format(j), 'w+') as fp:
        for sent in sents:
            fp.write(sent)


def train(df, i, j):
    '''
    functio to train w2v iteration.

    INPUTS:
        df (pd.DataFrame): dataframe of sentences
        i (int): value for bootstrap random seed
        j (int): value for shuffle random seed

    RETURNS:
       rutime (float): train time in seconds
    '''
    t0 = time()

    mname = 'race_{}_{}.kv'.format(i, j)
    
    # bootstrap and shuffle
    bootstrap_txt(df, i)
    shuffle_txt(i, j)

    # declare model
    model = Word2Vec(vector_size=dimension,
                     window=window,
                     min_count=5,
                     workers=nthreads,
                     seed=42 + i)

    # build vocab and train
    model.build_vocab(corpus_file='sh_sents.txt_{}'.format(j))
    model.train(corpus_file='sh_sents.txt_{}'.format(j),
                total_examples=model.corpus_count,
                total_words=model.corpus_total_words,
                epochs=epochs)

    # save results
    mname = 'race_{}_{}.kv'.format(i,j)
    model.wv.save(path + mname)

    return time() - t0


if __name__ == '__main__':
    # load data
    df = pd.read_parquet(path)

    # train each iteration
    for i in ['og'] + list(range(0, nboot)):
        for j in range(nshuff):
            print(i, j)
            print(train(df, i, j))

