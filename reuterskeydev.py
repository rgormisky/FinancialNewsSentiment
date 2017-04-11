# -*- coding: utf-8 -*-
"""
Created on Mon Apr 10 16:44:58 2017

@author: Rob
"""

import bs4, requests, re, datetime, time

month_dict = {'Jan' : 1, 'Feb' : 2, 'Mar' : 3, 'Apr' : 4, 'May' : 5, 'Jun' : 6,
              'Jul' : 7, 'Aug' : 8, 'Sep' : 9, 'Oct' : 10, 'Nov' : 11, 'Dec' : 12}
                

def getKeyDevList(ticker):
    '''
    queries Reuters Key Developments website for the most recent year of news 
    written about the given ticker. 
    
    ticker is a string representing a stock ticker, e.g. 'GS', 'XOM', 'AAPL', 'GOOG' 
    
    returns a list of tuples, one for each key development, of the form
    (article title, date of publication, article text)
    '''
    today = datetime.date.today()
                  
    curr_date = today
    target_date = datetime.date(today.year - 1, today.month, today.day)
    
    story_tuple_list = [] # store tuples of (title, date, text)
    pagenum = 1
    pagenum_stub = r'?pn='
    while curr_date >= target_date:
        if pagenum == 1:
            page_str = ''
        else:
            page_str = pagenum_stub + str(pagenum)
        tickerurl = r'http://www.reuters.com/finance/stocks/' + ticker + r'/key-developments' + page_str
        keydev_doc = requests.get(tickerurl)
        keydev_html = keydev_doc.text
        keydev_bs = bs4.BeautifulSoup(keydev_html, 'lxml')
        keydev_txt = keydev_bs.get_text()
        
        # Key developments end with string r'Previous.*Next'
        #Starts with r'Latest Key Developments \(Source: Significant Developments\)'
        
        keydev_startstring = r'Latest Key Developments \(Source: Significant Developments\)\n\n\n\n\n'
        match_all = ".*"
        keydev_endstring = r'Previous\n*Next'
        
        pattern = keydev_startstring + match_all + keydev_endstring
        
        keydev_nocookies_list = re.findall(pattern, keydev_txt, re.DOTALL)
        
        keydev_nocookies = ' '.join(keydev_nocookies_list)
        
        keydev_nohex = re.sub(r'\xa0', ' ', keydev_nocookies)  
        keydev_nostartnoend = re.sub(keydev_startstring + '|' + keydev_endstring, '', keydev_nohex, re.DOTALL)  
        
        keydev_list = keydev_nostartnoend.split('\n\t\t\t\nFull Article\n\n\n\n\n\n')
        
        for story in keydev_list:
            if story == '' or story == '\n':
                continue
            lines = story.splitlines()
            title = lines[0]
            date = lines[1]
            date_search = re.search(', (\d{1,2}) (\w{3}) (\d{4})', date)
            if date_search is None: #articles published today have no date in html
                date = today
            else:
                days = int(date_search.group(1))
                month = month_dict[date_search.group(2)]
                year = int(date_search.group(3))
                date = datetime.date(year, month, days)
            text = lines[2]
            story_tuple = (title, date, text)
            story_tuple_list.append(story_tuple)
        curr_date = story_tuple_list[len(story_tuple_list) - 1][1]
        pagenum += 1
    return(story_tuple_list)

# Testing, print most recent year of news for 50 companies from the S&P
ticker_list = ['MMM', 'ADBE', 'AET', 'AFL', 'ARE', 'LNT', 'ALL', 'GOOG',
               'AMZN', 'AAL', 'AMP', 'AMGN', 'AON', 'APA', 'AAPL', 'T',
               'BAC', 'BBT', 'BLK', 'BA', 'BXP', 'BMY', 'COG', 'CPB', 'CAT',
               'CVX', 'CMG', 'CSCO', 'C', 'KO', 'COST', 'DVA', 'DPS', 'DD',
               'EBAY', 'EA', 'EXPE', 'FB', 'GE', 'GS', 'HAL', 'HPQ', 'HUM',
               'INTC', 'INTU', 'JPM', 'KHC', 'LNC', 'LYB', 'MCD']
             
start_time = time.time()
for ticker in ticker_list:
    print(ticker)
    getKeyDevList(ticker)
print(time.time() - start_time)

#result: took 51.9 seconds for 50 companies, about 1 second each
