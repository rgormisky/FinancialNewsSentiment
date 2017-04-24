# FinancialNewsSentiment
Scripts for querying financial news sources and extracting latent topics/sentiment using NLP methods.

retuerskeydev.py - This script queries the Reuters Key Developments RSS feed for all articles about a particular ticker over the past two years. 

SP500Sentiment.py - This script aggregates Reuters Key Developments queries for all stocks in the S&P 500 using the function defined in reuterskeydev.py.

wordcounter.py - This script provides a function to count the ratios of positive or negative words in a document based on the General Inquirer dictionary (defintions contained in inquirerbasic.xlsx). 

VixReutersModel.R - All the data analysis and modeling is done in this R script.

All other files are data used in the four scripts above.
