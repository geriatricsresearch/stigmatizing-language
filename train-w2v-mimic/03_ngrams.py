from time import time

from gensim.models import Phrases, phrases
from gensim.models.phrases import Phraser
import pandas as pd

fpath = 'mimic_sents.parquet'
opath = 'mimic_trigrams.parquet'

def chunker(seq, size):
    '''
    gennerator function to chunk sequence into batches

    INPUTS:
        seq (iterable): sequence to be chunked
        size (int): size of chunks

    RETURNS:
        generator function
    '''
    return (seq[pos:pos + size] for pos in range(0, len(seq), size))


if __name__ == '__main__':
    # load data
    df = pd.read_parquet(fpath)
    sentences = df['sent']

    n = len(sentences)

    # train bigrams (chunks for progress transparency)
    t0 = time()
    for i, chunk in enumerate(chunker(sentences, 100000), 1):
        ti = time()
        chunk = [sent.split() for sent in chunk]
        if i == 1:
            bigram = Phrases(chunk, connector_words=phrases.ENGLISH_CONNECTOR_WORDS)
        else:
            bigram.add_vocab(chunk)
        print(i * 100000, '/', n, time() - ti, time() - t0, end='\r')

    # freeze/save bigrams 
    bigram = bigram.freeze()
    bigram.save('bigrams.pkl')

    #train trigrams (chunks for progress transparency)
    t0 = time()
    for i, chunk in enumerate(chunker(sentences, 100000), 1):
        ti = time()
        chunk = [sent.split() for sent in chunk]
        if i == 1:
            trigram = Phrases(bigram[chunk], connector_words=phrases.ENGLISH_CONNECTOR_WORDS)
        else:
            trigram.add_vocab(bigram[chunk])
        print(i * 100000, '/', n, time() - ti, time() - t0, end='\r')

    # freeze/save trigrams 
    trigram = trigram.freeze()
    trigram.save('trigrams.pkl')

    # convert to trigrams and dump
    out = []

    n = len(df[['pid', 'nid']].drop_duplicates())
    gb = df.groupby(['pid', 'nid'])

    for i, ((pid, nid), sub_df) in enumerate(gb):
        tri = trigram[bigram[[sent.split() for sent in sub_df['sent']]]]
        tri = [' '.join(sent) for sent in tri]
        for sent in tri:
            out.append([pid, nid, sent])
        if i % 10000 == 0:
            print(i, '/', n, end='\r')
            
    out = pd.DataFrame(out, columns=['pid', 'nid', 'sent'])
    out.to_parquet(opath)