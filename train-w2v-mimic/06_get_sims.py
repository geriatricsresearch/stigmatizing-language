from itertools import product
from time import time

from gensim.models import KeyedVectors
import numpy as np
import pandas as pd

path = 'w2v_boot_m3/'

nshuff = 20
nboot = 50

races = [
    '<AA>',
    '<CAUCASIAN>',
    '<HISPANIC>',
]

pc = set([
 'Palliative',
 'Palliate',
 'pall',
 'pallcare',
 'palliation',
 'DNR',
 'DNI',
 'DNAR',
 'coding',
 'coded',
 'code',
 'EOL',
 'hospice',
 'resuscitate',
 'resuscitation',
 'resuscitative',
 'PC',
 'PEG',
 'Trach',
 'tracheostomy',
 'supportive',
 'comfort',
 'CMO',
 'bereave',
 'bereaved',
 'bereavement',
 'bereavement_counseling',
 'curative',
 'terminal',
 'terminally',
 'futile',
 'futility',
 'CPR',
 'status',
 'ACP',
 'withdrawal',
 'surrogate',
 'surrogate_decision',
 'surrogate_decision_maker',
 'surrogate_decisionmaker',
 'surrogate_decision-maker',
 'advanced_directive',
 'advance_directive',
 'healthcare_power_of_attorney',
 'healthcare_proxy',
 'power_of_attorney',
 'proxy_decisionmaker',
 'proxy_decision_maker',
 'healthcare_decision_maker',
 'healthcare_decisionmaker',
 'advance_care_plan',
 'advanced_care_plan',
 'advance_care_planning',
 'advanced_care_planning',
 'goals_of_care',
 'goal_of_care',
 'do_not_resuscitate',
 'do_not_intubate',
 'do_not_attempt_resuscitation',
 'do_not_attempt_to_resuscitate',
 'end_of_life',
 'end_of_life_care',
 'comfort_care',
 'comfort_care_only',
 'comfort_measures',
 'comfort_measures_only',
 'cardiopulmonary_resuscitation',
 'medical_futility',
 'futile_care',
 'quality_of_life',
 'quality_over_quantity',
 'quantity_over_quality',
 'palliative_care',
 'palliative_surgery',
 'palliative_chemo',
 'palliative_chemotherapy',
 'code_status',
 'GOC',
 'withdrawal_of_care',
 'withdrawing_care',
 'focusing_on_comfort',
 'aggressive_comfort',
 'focus_on_comfort',
 'focus_on_symptoms',
 'symptom-focus',
 'symptom-focused',
 'dying',
 'is_dying',
 'about_to_die',
 'afraid_of_dying',
 'afraid_to_die',
 'fear_of_dying',
 'fear_of_death',
 'ready_to_die',
 'dying_process',
 'would_want_a_breathing_tube',
 'would_want_a_breathing',
 'would_want_a_breathing_device',
 'chest_compressions',
 'ready_for_death',
 'support_for_the_caregiver',
 'caregiver_support',
 'supporting_the_caregiver',
 'inpatient_hospice'
])

spirit = set([
 'Spiritual',
 'Spirituality',
 'chaplain',
 'prayer',
 'pastoral',
 'God',
 'Gods',
 'faith',
 'faith_in_god',
 'faithfull',
 'faithful',
 'spiritual_care',
 'spiritual_care_consult',
 'spiritual_care_consultation',
 'chaplain_consult',
 'chaplain_consultation',
 'pastoral_care',
 'pastoral_care_consult',
 'pastoral_care_consultation',
])

fight = set([
 'fighter',
 'resilient',
 'resilience',
 'a_fighter',
 'is_a_fighter',
 'fight',
 'fighting',
 'fighting_chance',
 'fighter',
 'keep_fighting',
 'fighter_and_would_want',
 'fighting_spirit',
 'put_up_fight',
 'put_up_a_fight',
 'cope',
 'coping_mechanism',
 'coping_skills',
 'coping',
 'optimistic',
 'optimist',
 'dogged',
 'doggedness',
 'perseverance',
 'persistent',
 'persistence',
 'toughness',
 'obstinance',
 'hardiness',
 'tenacity',
 'grit',
 'fortitude',
 'pluck',
 'self_sufficient',
 'self_sufficiency',
 'self_support',
 'internal_strength',
 'fighter_and_wouldnt_want',
 'persevere',
 'tough',
 'hardy',
 'tenacious',
 'self_sufficient',
 'as_a_fighter',
 'fighting_spirit'
])

stigma = set([
 'agitation',
 'aggressive',
 'resistant',
 'agitated',
 'resistance',
 'challenging',
 'aggressively',
 'challenges',
 'noncompliance',
 'noncompliant',
 'combative',
 'nonadherence',
 'angry',
 'non_adherent',
 'resisting',
 'anger',
 'non_compliance',
 'challenged',
 'confrontation',
 'resists',
 'non_compliant',
 'nonadherent',
 'combativeness',
 'resist',
 'resisted',
 'aggression',
 'noncooperative',
 'aggressiveness',
 'non_adherence',
 'agitate',
 'confrontational',
 'angrily',
 'unpleasant',
 'defensive',
 'confront',
 'confronting',
 'resistances',
 'confronted',
 'defensiveness'
])

vulnerable = [
    'vulnerable', 'vulnerability', 'fragile', 'fragility', 'frail', 'frailty'
]

classes = {
    'palliative care': pc, 
    'spirituality': spirit, 
    'figher': fight, 
    'stigmatizing': stigma,
    'vulernability': vulnerable
}


def get_path(i,j):
    '''
    helper funtion to build path
    '''
    return path + 'race_{}_{}.kv'.format(i,j)


def load_model(i,j):
    '''
    helper function to load w2v model
    '''
    path = get_path(i,j)
    return KeyedVectors.load(path, mmap='r')


def get_similarity(model, word, other_words):
    '''
    function to get similarities between base 'word' and target 'other_words'.
    any missing words are set to NaN similarity.

    INPUTS:
        model (gensim.KeyedVectors): w2v model
        word (str): base
        other_words (list of str): targets

    RETURNS:
        out (list of float): base target similarities (order maintained)
    '''
    return [1 - model.distance(word, other_word) 
            if word in model and other_word in model
            else np.nan
            for other_word in other_words]


def get_sim(model, i, j):
    '''
    function to get similarities for each class of terms and race tokens.

    INPUTS:
        model (gensim.KeyedVectors): w2v model
        i (int): value for bootstrap random seed
        j (int): value for shuffle random seed

    RETURNS:
        l (list of lists): similarities for the w2v model
            l[0] (int): value for bootstrap random seed (i)
            l[1] (int): value for shuffle random seed (j)
            l[2] (str): class for base word
            l[3] (str): base word
            l[4] (float): similarity bwtween base and African American
            l[5] (float): similarity bwtween base and Caucasian
            l[6] (float): similarity bwtween base and Latin-x

    '''
    return [[i, j, cl, target, *get_similarity(model, target, races)]
            for cl, targets in classes.items() for target in targets]      


if __name__ =='__main__':
    # get similarities for each bootstrapped model
    values = []
    for i in range(nboot):
        for j in range(nshuff):
            try:
                model = load_model(i,j)
                values += get_sim(model, i, j)
                print(' ' * 50, end='\r')
                print(i, j, end='\r')
            except:
                print(' ' * 50, end='\r')
                print('ooof', i, j)

    # dump bootstrapped similarities
    columns=['bootstrap', 'shuffle', 'class', 'base_word', 'african_american', 
             'caucasian', 'hispanic']
    df = pd.DataFrame(values, columns=columns)
    df.to_parquet('m3_bootstraps.parquet')

    # get similarities for each orginal model
    values = []
    for i in ['og']:
        for j in range(nshuff):
            try:
                model = load_model(i,j)
                values += get_sim(model, i, j)
                print(' ' * 50, end='\r')
                print(i, j, end='\r')
            except:
                print(' ' * 50, end='\r')
                print('ooof', i, j)
    
    # dump original similaritie       
    columns=['bootstrap', 'shuffle', 'class', 'base_word', 'african_american', 
             'caucasian', 'hispanic']
    df = pd.DataFrame(values, columns=columns)
    df['bootstrap'] = 'orignal!'
    df.to_parquet('m3_original.parquet')