# -*- coding: utf-8 -*-
"""
Created on Thu Apr 27 13:39:50 2017

@author: rolgo8
"""

import requests
import pytz
import pandas as pd
import os

from bs4 import BeautifulSoup
import datetime
import urllib.request  


SITE = "http://en.wikipedia.org/wiki/List_of_S%26P_500_companies"
START = datetime.datetime(1900, 1, 1, 0, 0, 0, 0, pytz.utc)
END = datetime.datetime.today().utcnow()

# There has been some turnover in the index because of IPOs/acquisitions
# This dictionary stores the number of returns available for each ticker. It is
# derived from the debug_sector_returns() function below. 
IPO_dict = {'FTV' : 204, 'CSRA' : 362, 'HPE' : 382, 'PYPL' : 456, 
            'UA' : 275, 'WLTW' : 329, 'WRK' : 463, 'KHC' : 456}

def scrape_list(site):
    req = requests.get(site)
    page = req.text
    soup = BeautifulSoup(page, "lxml")

    table = soup.find('table', {'class': 'wikitable sortable'})
    sector_tickers = dict()
    for row in table.findAll('tr'):
        col = row.findAll('td')
        if len(col) > 0:
            sector = str(col[3].string.strip()).lower().replace(' ', '_')
            ticker = str(col[0].string.strip())
            if ticker == 'BRK.B':
                ticker = 'BRK-B'
            elif ticker == 'BF.B':
                ticker = 'BF-B'
            if sector not in sector_tickers:
                sector_tickers[sector] = list()
            sector_tickers[sector].append(ticker)
    return sector_tickers

def get_returns_series(ticker):
    '''
    Gets the simple returns of the specified ticker for 4/26/1997 - 4/26/2017
    
    returns a pandas dataframe of dates and returns
    '''
    yahoo_url_start = 'http://real-chart.finance.yahoo.com/table.csv?s='
    yahoo_url_end = '&d=3&e=26&f=2017&g=d&a=3&b=1&c=2015' # chooses dates 4/1/15 - 4/26/17 because this is the Reuters data period
    yahoo_url = yahoo_url_start + ticker + yahoo_url_end
    urllib.request.urlretrieve(yahoo_url, ticker + '.csv')
    prices_df = pd.read_csv(ticker + '.csv', parse_dates= ['Date'])
    prices_df = prices_df.sort_values(by= 'Date')
    prices_df.set_index('Date', inplace= True)
    
    nrow, _ = prices_df.shape
    returns = []
    for i in range(1, nrow):
        returns.append(((prices_df.iloc[i, 4] - prices_df.iloc[i-1, 4]) / prices_df.iloc[i-1, 4]))
    
    #dates = prices_df.iloc[:, 0]
    
    return_dict = {ticker : returns}
    return(pd.DataFrame.from_dict(return_dict))

def get_yahoo_data(ticker, args):
    '''
    Queries yahoo finance API for args data on given ticker string
    
    ticker is a string representing a stock ticker e.g. 'AAPL', 'XOM'
    
    args is a string of the yahoo finance data items we wish to retrieve. Each
    arg is reprsented as a single character (or one character and one number).
    These args are put in a single string with no spaces and appended to the 
    URL.
    A list of available args is found at http://www.jarloo.com/yahoo_finance/
    
    Returns a list of strings corresponding to the desired data
    '''
    yahoo_url_start = 'http://finance.yahoo.com/d/quotes.csv?s='
    yahoo_url_mid = '&f='
    yahoo_url = yahoo_url_start + ticker + yahoo_url_mid + args
    req = requests.get(yahoo_url)
    text = req.text.strip('\n')
    return(text.split(','))

def get_sector_returns(sector_tickers):
    return_df = pd.DataFrame()
    for sector, tickers in sector_tickers.items():
        print(sector)
        os.chdir('L:\Robert\FinancialNewsSentiment\SPdata' + '\\' + sector + '\\')
        sector_df = pd.DataFrame()
        mcap_dict = {}
        sector_mcap = 0
        for ticker in tickers:
            if ticker == 'BRK-B': # Berkshire is not well supported by yahoo finance for some reason
                mcap = 411.33
            elif ticker == 'BF-B':
                mcap = 18.11
            else:
                mcap_str = get_yahoo_data(ticker, 'j1')[0].strip('B') # j1 = market capitalization
                if mcap_str[len(mcap_str) - 1] == 'M':
                    mcap = float(mcap_str.strip('M')) / 1000
                else:
                    mcap = float(mcap_str)
            mcap_dict[ticker] = mcap
            sector_mcap += mcap
            
            simple_returns = get_returns_series(ticker)
            sector_df[ticker] = simple_returns
        nrow, _ = sector_df.shape
        sector_returns = []
        for i in range(nrow):
            sector_return = 0
            for colname in sector_df.columns.values.tolist():
                if colname in IPO_dict:
                    if i == IPO_dict[colname] - 1:
                        sector_mcap -= mcap_dict[colname]
                        continue
                    if i >= IPO_dict[colname]:
                        continue
                weight = mcap_dict[colname] / sector_mcap
                sector_return += sector_df.ix[i, colname] * weight
            sector_returns.append(sector_return)
        print(sector_returns)
        sector_returns_dict = {sector : sector_returns}
        sector_returns_df = pd.DataFrame.from_dict(sector_returns_dict)
        sector_returns_df.to_csv(sector + '.csv', index= False)
        
        return_df[sector] = sector_returns_df
    
    os.chdir(r'L:\Robert\FinancialNewsSentiment')
    return_df.to_csv('SectorReturns.csv', index= False)

def debug_sector_returns(sector_tickers):
    ''' 
    assists in updating the IPO_dict
    '''
    curr_max = 0
    for sector, tickers in sector_tickers.items():
        print(sector)
        for ticker in tickers:            
            simple_returns = get_returns_series(ticker)
            if simple_returns.shape[0] >= curr_max:
                curr_max = simple_returns.shape[0]
            else:
                print(ticker, simple_returns.shape)

                        
#def download_ohlc(sector_tickers, start, end):
#    sector_ohlc = {}
#    for sector, tickers in sector_tickers.items():
#        print('Downloading data from Yahoo for %s sector' % sector)
#        data = DataReader(tickers, 'yahoo', start, end)
#        for item in ['Open', 'High', 'Low']:
#            data[item] = data[item] * data['Adj Close'] / data['Close']
#        data.rename(items={'Open': 'open', 'High': 'high', 'Low': 'low',
#                           'Adj Close': 'close', 'Volume': 'volume'},
#                    inplace=True)
#        data.drop(['Close'], inplace=True)
#        sector_ohlc[sector] = data
#    print('Finished downloading data')
#    return sector_ohlc
#
#
#def store_HDF5(sector_ohlc, path):
#    with pd.get_store(path) as store:
#        for sector, ohlc in sector_ohlc.iteritems():
#            store[sector] = ohlc
#
#
#def get_snp500():
#    sector_tickers = scrape_list(SITE)
#    sector_ohlc = download_ohlc(sector_tickers, START, END)

if __name__ == '__main__':
    sector_tickers = scrape_list(SITE) # always make this call first to scrape most recent tickers from wikipedia
    
    # Generate the returns data by sector for the S&P index
    get_sector_returns(sector_tickers)
    
#    # Debug IPO_dict at top of file
#    os.chdir(r'L:\Robert\FinancialNewsSentiment\SPdata')
#    debug_sector_returns
    
#    # For outputting the market capitalization associated with all tickers
#    record_list = []
#    for sector, tickers in sector_tickers.items():
#        for ticker in tickers:
#            mcap_str = get_yahoo_data(ticker, 'j1')[0].strip('B')
#            if mcap_str[len(mcap_str) - 1] == 'M':
#                mcap = float(mcap_str.strip('M')) / 1000
#            else:
#                mcap = float(mcap_str)
#            print(mcap)
#            record = (ticker, mcap)
#            record_list.append(record)
#    labels = ['ticker', 'mcap']
#    mcap_df = pd.DataFrame.from_records(record_list, columns = labels)
#    mcap_df.to_csv('marketcaps.csv', index= False)
   