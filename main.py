# -*- coding: utf-8 -*-
"""
Created on Sun Apr 30 12:38:44 2017

@author: Rob
"""

import SP500Sentiment as spsent
import VixReutersModel as vixmodel
import matplotlib.pyplot as plt
import numpy as np

# First collect the necessary sentiment data
spsent.write_event_data()

# Broken as of 4/23, need to update the spreads and VIX data to match the 
# two year - a few days rolling window offered by Reuters. Suggests the need
# to automate the spreads and VIX data collection process, but most sources
# of this data require significant cleaning.
model = vixmodel.create_model()

# Assess the model fit with
print(model.summary)

# Plot the Basis risk of the model
# Negative basis risk implies the market is overvaluing bonds relative to the model
# In this case, we underweight corporate bonds relative to the index
# Positive basis risk implies the market is undervaluing bonds relative to the model
# In this case, we overweight corporate bonds relative to the index
residuals = model.resid
sd_err = np.std(residuals)

nobs = len(residuals)

X = range(nobs)
neg_sd_err = [-sd_err] * nobs
pos_sd_err = [sd_err] * nobs
zero = [0] * nobs

plt.figure('Basis Risk') 
plt.plot(X,residuals,color='green',linestyle='-')
plt.plot(X,neg_sd_err,color= 'red',linestyle='-')
plt.plot(X,zero,color= 'black',linestyle='-')
plt.plot(X,pos_sd_err,color= 'blue',linestyle='-')
plt.xlabel('Weeks since 4/24/15')
plt.title('Basis Risk of Corporate Bonds')
plt.show()

# Plot the model fit versus the actual spread. This graph contains essentially
# the same information as the previous graph
predictions = model.y_fitted
actual = model._y_orig

nobs = len(predictions)

X = range(nobs)
zero = [0] * nobs

plt.figure('Fitted vs. Actual') 
plt.plot(X,predictions,color='green',linestyle='-')
plt.plot(X,actual,color= 'blue',linestyle='-')
plt.xlabel('Weeks since 4/24/15')
plt.title('Fitted vs. Actual Spread')
plt.legend(['Fitted', 'Actual'],loc='upper right')
plt.show()