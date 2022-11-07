# Stigmatizing Language
**Principal Investigator**
- Julien Cobert

**Data Folk**
- Edie Espejo
- Hunter Mills

## Definitions
- Base word: We study 3 ethnic base words: "caucasian", "african_american", and "hispanic" (simplified)
- Target word: We have a list of stigmatizing words and their conjugations.
- Cosine distance: This is the measurement of (dis)similarity within context of words, in this case, all ICU notes within the year.

## Bootstraps
Bootstrap confidence intervals were created to test:

1. Whether or not an *average* cosine distance was 1 or not, where a value of 1 would denote the target and base word were unrelated terms and
2. Whether two mean cosine distances were the same or not.

We bootstrapped the mean average cosine distance and the differences in mean average. To compare across words of the same subclass/synonymous terms/conjugations, we bootstrapped the *precision-weighted average* cosine distance. Likewise, we bootstrapped the difference in the PWA cosine distances.

### Bootstrap Method
Original data are ICU notes from one year at UCSF. Bootstrap datasets were created from these original data, resampling patients to conserve the correlation structure of notes written about the same person. Resulting bootstrap datasets may include a patient more than once. For each bootstrap, using each base word and target word, cosine distances were estimated using word2vec word embeddings.

```
for each bootstrap_dataset:
  for each base_word, target_word:
    estimateCosineDistance(base_word, target_word)   # Estimates Monte-Carlo error
```

Using the produced data, we calculate the following statistics and create 95% CI for them

1. Average cosine distance
2. Difference in mean cosine distance
3. Precision-weighed average (PWA) cosine distance
4. Difference in PWA cosine distance

## Subclasses of Target Words
| Subclass                      | Strings Used     |
|-------------------------------|----------------|
| Violence                      | 'combative', 'defensiveness', 'agitation', 'agitated', 'defensive', 'confronting', 'agitate', 'confront', 'confronted', 'combativeness', 'angry', 'angrily', 'aggressiveness', 'aggression', 'confrontation', 'aggressively', 'aggressive', 'confrontational' |
| Passivity                     | 'nonadherent', 'challenges', 'noncooperative', 'resists', 'challenging', 'resisting', 'resist', 'resisted', 'non_compliant', 'noncompliant', 'resistance', 'unpleasant', 'noncompliance', 'non_adherence', 'non_compliance', 'challenged', 'non_adherent', 'resistances', 'resistant', 'nonadherence' |
| Non-adherence                 | 'nonadherent', 'non_adherence', 'non_adherent', 'nonadherence' |
| Non-compliance                | 'non_compliant', 'noncompliant', 'noncompliance', 'non_compliance' |
| Non-compliance/non-adherence  | Combined 2 lists above |
| Adjectives describing patient | 'noncooperative', 'nonadherent', 'non_adherence', 'non_adherent', 'nonadherence', 'noncompliance', 'non_compliant', 'non_compliance', 'noncompliant', 'anger', 'angrily', 'combative', 'confront', 'unpleasant', 'agitation' |
