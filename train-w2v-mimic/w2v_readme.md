### Training word2vec readme

This directory houses the scripts to train word2vec for measuring bias in ICU note text in MIMIC-iii.

To build confidence intervals for the bias measurements, word2vec is both bootstrapped and shuffled. For the work presented, models were trained for:

* n bootstraps = 50
* m shuffles = 20

This configuration be exceedingly slow if ran with 50 bootstraps and 20 shuffles.

Code Assumptions:

* Source MIMIC-iii csv tables are in the same directory as the word2vec scripts.
* Scripts are executed in the same directory as the scripts.
* file paths are a the start of each script, and can be adjusted as needed.

Needed MIMIC-iii tables:

* NOTE_EVENTS.csv
* ICUSTAYS.csv
* PATIENTS.csv

Order of scripts:

* 01_subset_notes.py
  * subset note by note type and limiting notes for adults.
* 02_segment.py
  * Segment note into sentences. Limit characters to alpha-numeric.
* 03_ngrams.py
  * convert tokens into n-grams -- running gensim Phraser twice.
* 04_surrogate.py
  * run regexes to surrogate race phrases with race token.
* 05_w2v.py
  * run word2vec for 'n bootstraps' x 'm shuffles' iterations.
* 06_get_sims.py
  * get similarities for each bootstrap between race tokens and target sets.

Output of 06_get_sims.py is used in the analysis in the sister MIMIC-iii directory.