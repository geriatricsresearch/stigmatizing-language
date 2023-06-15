# Stigmatizing Language
**Principal Investigator**
- Julien Cobert

## Data
This project leveraged notes of patients >= 18 years old from 2 separate hospitals.
- University of California, San Francisco (UCSF)
  - Private data source
  - De-identified dataset, years 2012 to 2022
- Beth Israel Deaconess Medical Center
  - Public data source developed by MIT and BIDMC
  - MIMIC-III database, years 2001 to 2012

## Definitions
- Base word: We study 3 ethnic base words: "caucasian", "african_american", and "hispanic" (simplified)
- Target word: We have a list of stigmatizing words and their conjugations.
- Cosine similarity: This is the measurement of similarity within context of words, in this case, all ICU notes within the year.

## Natural Language Processing
- Preprocessed n-grams using word2vec (w2v) with continuous bag of words that predicts presence of word using its surrounding word context
- To estimate contextual word similarity, w2v models were fit between each base and target word
- **Due to protections surrounding UCSF data, NLP models and results will are shared here for the MIMIC dataset.** Statistical analysis code (bootstraps and plots) will be shared.

## Bootstraps
Bootstrap confidence intervals were created to test:

1. Whether or not an *average* cosine similarity was 0 or not, where **a value of 0 would denote the target and base word were unrelated terms** and
2. Whether two mean cosine similarity were the same or not.

We bootstrapped the mean average cosine similarity and the differences in mean average. To compare across words of the same subclass/synonymous terms/conjugations, we bootstrapped the *precision-weighted average* cosine distance. Likewise, we bootstrapped the difference in the PWA cosine similarities.

### Bootstrap Method
Original data are ICU notes from one year at UCSF. Bootstrap datasets were created from these original data, resampling patients to conserve the correlation structure of notes written about the same person. Resulting bootstrap datasets may include a patient more than once. For each bootstrap, using each base word and target word, cosine similarities were estimated using word2vec word embeddings.

Using the produced data, we calculate the following statistics and create 95% CI for them.

1. Average cosine similarity
2. Difference in mean cosine similarity
3. Precision-weighed average (PWA) cosine similarity
4. Difference in PWA cosine similarity

```
for each bootstrap_dataset:
  for each base_word, target_word:
    estimateCosineSimilarity(base_word, target_word)   # Simulates Monte-Carlo error using 20 shuffles

for each base_word:
  for each bootstrap_dataset:
    # Statistic and amount of target words differs
    calculateStatisticUsingCosineDistances(base_word, target_words)
     
  calculateMean()
  calculateSD()
  calculate95CI()
```

## Subclasses of Target Words
| Subclass                      | Strings Used     |
|-------------------------------|----------------|
| Violence                      | 'combative', 'defensiveness', 'agitation', 'agitated', 'defensive', 'confronting', 'agitate', 'confront', 'confronted', 'combativeness', 'angry', 'angrily', 'aggressiveness', 'aggression', 'confrontation', 'aggressively', 'aggressive', 'confrontational' |
| Passivity                     | 'nonadherent', 'challenges', 'noncooperative', 'resists', 'challenging', 'resisting', 'resist', 'resisted', 'non_compliant', 'noncompliant', 'resistance', 'unpleasant', 'noncompliance', 'non_adherence', 'non_compliance', 'challenged', 'non_adherent', 'resistances', 'resistant', 'nonadherence' |
| Non-adherence                 | 'nonadherent', 'non_adherence', 'non_adherent', 'nonadherence' |
| Non-compliance                | 'non_compliant', 'noncompliant', 'noncompliance', 'non_compliance' |
| Non-compliance/non-adherence  | Combined 2 lists above |
| Adjectives describing patient | 'noncooperative', 'nonadherent', 'non_adherence', 'non_adherent', 'nonadherence', 'noncompliance', 'non_compliant', 'non_compliance', 'noncompliant', 'anger', 'angrily', 'combative', 'confront', 'unpleasant', 'agitation' |
