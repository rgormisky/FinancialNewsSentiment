# -*- coding: utf-8 -*-
"""
Created on Sun Apr 30 11:22:11 2017

@author: Rob

create_model() relies on a call to write_event_data() in SP500Sentiment.py to 
load the raw event data into the same directory as this script. This script
also relies on the VIXCLS.csv and sectorOAS.csv data which have been acquired
from external sources (the Federal Reserve and Barclays Point, respectively).

This script outputs a statsmodel OLS regression of the spread of corporate
bonds in the Barclays U.S. Aggregate Fixed Income Index on the VIX and
our sentiment score. Weekly data is used in the estimation.

"""

import pandas as pd
import numpy as np
from datetime import datetime
from pandas.stats.api import ols

def create_model():
    '''
    Creates the coporate bond spread model OAS_t = intercept + ss_{t-1} + vix_{t-1}
    using sentiment score (ss) 
    '''
    # Read in data
    event_data = pd.read_csv(r'C:\Users\Rob\Desktop\OID 311\GroupProject\FinancialNewsSentiment-master\raweventlist.csv',
                             header=-1, parse_dates= [0])
    event_data.columns = ['DATE', 'wc', 'pos', 'neg', 'ticker']
    event_data['DATE'] = pd.to_datetime(event_data['DATE'])
    
    vix_data = pd.read_csv(r'C:\Users\Rob\Desktop\OID 311\GroupProject\FinancialNewsSentiment-master\VIXCLS.csv',
                             header=0, parse_dates= [0])
    vix_data['DATE'] = pd.to_datetime(vix_data['DATE'])
    
    spread_data = pd.read_csv(r'C:\Users\Rob\Desktop\OID 311\GroupProject\FinancialNewsSentiment-master\sectorOAS.csv',
                             header=10, parse_dates= [0])
    corp_spreads = spread_data.iloc[0:103, [0, 11]]
    corp_spreads.columns = ['DATE', 'CORP']
    
    corp_spreads['DATE'] = pd.to_datetime(corp_spreads['DATE'])
    
    # Convert sentiment data into weekly sentiment ratio of ((pos - neg) / wc)
    nrow, ncol = corp_spreads.shape
    sent_data = pd.DataFrame(np.zeros((nrow, ncol)))
    last_day = datetime(2015, 4, 25) #manually confirmed first day of corpus
    for i in range(nrow):
        if i != 0:
            last_day = corp_spreads.iloc[i-1, 0]
        curr_day = corp_spreads.iloc[i, 0]
        print(curr_day)
        sent_data.iloc[i-1, 0] = last_day
        words = 0
        pos = 0
        neg = 0
        for j in range(event_data.shape[0]):
            if event_data.iloc[j, 0] > last_day and event_data.iloc[j, 0] <= curr_day:
                words += event_data.iloc[j, 1]
                pos += event_data.iloc[j, 2]
                neg += event_data.iloc[j, 3]
        sent_data.iloc[i, 1] = (pos - neg) / words
    
    # Find appropriate VIX data points to match Fridays date scheme
    vix_fridays = pd.DataFrame(np.zeros((nrow, ncol)))
    for i in range(nrow):
        vix_fridays.iloc[i, 0] = corp_spreads.iloc[i, 0]
        for j in range(vix_data.shape[0]):
            if vix_data.iloc[j, 0] == corp_spreads.iloc[i, 0]:
                if vix_data.iloc[j, 1] == '.':
                    vix_fridays.iloc[i, 1] = float(vix_data.iloc[j-1, 1])
                else:
                    vix_fridays.iloc[i, 1] = float(vix_data.iloc[j, 1])
    
    # Lag predictors and put data into useable format
    corp_reg = corp_spreads.iloc[1:103, 1]
    sent_reg = sent_data.iloc[0:102, 1]
    vix_reg = vix_fridays.iloc[0:102, 1]
    design_mat = pd.concat([sent_reg, vix_reg], axis=1)
    design_mat.columns = ['sent', 'vix']
    
    #Finally, construct the model and return it
    # OAS_t = intercept + ss_{t-1} + vix_{t-1}
    model = ols(y=corp_reg, x= design_mat[['sent','vix']])
    return(model)