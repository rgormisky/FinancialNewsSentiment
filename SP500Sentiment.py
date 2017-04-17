# -*- coding: utf-8 -*-
"""
Created on Tue Apr 11 15:15:34 2017

@author: rolgo8

Use the getKeyDevList function in reuterskeydev.py to scrape articles for
all (except 2) companies in the S&P. Treat this set of articles as a single corpus
and perform Latent Dirichlet Allocation to automatically extract latent topics.
The topics themselves are written to '../topicdistributions'
"""

import wordcounter as wc
import openpyxl as pyxl
import numpy as np
import reuterskeydev as rkd
import datetime, csv
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation

# For writing date objects to csv files
def date_tostring(date_obj):
    '''
    converts python datetime.date object to MMDDYYYY representation. used for
    Reuters news URL generation.
    '''
    months = date_obj.month
    days = date_obj.day
    years = date_obj.year
    if days < 10:
        days_str = '0' + str(days)
    else:
        days_str = str(days)
    if months < 10:
        months_str = '0' + str(months)
    else:
        months_str = str(months)
    years_str = str(years)
    return(months_str + '/' + days_str + '/' + years_str)

# For reporting and debugging the topic output
def print_top_words(model, feature_names, n_top_words):
    for topic_idx, topic in enumerate(model.components_):
        print("Topic #%d:" % topic_idx)
        print(" ".join([feature_names[i]
                        for i in topic.argsort()[:-n_top_words - 1:-1]]))
    print()

target_date = datetime.date(2008, 11, 30)    
    
ticker_wb = pyxl.load_workbook('SPtickers.xlsx')
first_sheet_name = ticker_wb.get_sheet_names()[0]
first_sheet = ticker_wb.get_sheet_by_name(first_sheet_name)

ticker_data = first_sheet.values
ticker_cols = next(ticker_data)[1:]
ticker_data = list(ticker_data)
ticker_list = [r[0] for r in ticker_data]

ticker_ban_list = ['HAR', 'LLTC'] #HAR is Indian company, LLTC acquired by ADI

event_tuple_list = [] #(headline, date, article text, word count, pos words, neg words)
for ticker in ticker_list:
    print(ticker)
    if ticker in ticker_ban_list:
        continue
    three_tuples = rkd.getKeyDevList(ticker, target_date)
    # Only checks for positive words in article text, include headline?
    for three_tuple in three_tuples:
        word_count, pos_word_count = wc.count_words(three_tuple[2], 'pos')
        _, neg_word_count = wc.count_words(three_tuple[2], 'neg')
        wc_tuple = (word_count, pos_word_count, neg_word_count, ticker)
        event_tuple = three_tuple + wc_tuple
        event_tuple_list.append(event_tuple)

pos_word_counts = [r[4] for r in event_tuple_list]
neg_word_counts = [r[5] for r in event_tuple_list]

print('mean_pos_words= ', np.mean(pos_word_counts), 
      'mean_neg_words= ', np.mean(neg_word_counts))

output_tuples = [(date_tostring(r[1]), str(r[3]), str(r[4]), str(r[5]), r[6]) for
                 r in event_tuple_list]
csvname = "raweventlist.csv"
with open(csvname, "w") as csvfile:
    writer = csv.writer(csvfile, delimiter=',', quotechar='|', 
                        quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
    writer.writerows(output_tuples)

# Begin LDA on the entire S&P corpus
#n_samples = len(article_text_list)
#n_features = 1000000 # possible words, set arbitrarily high
#n_top_words = 25  # words per topic
#
#outdir = r'L:\Robert\FinancialNewsSentiment\topicdistributions' + '\\'
#    
#print("Extracting tf features for LDA...")
#tf_vectorizer = CountVectorizer(max_df=0.95, min_df=1,
#                                max_features=n_features,
#                                stop_words='english')
#tf = tf_vectorizer.fit_transform(raw_documents= article_text_list) # Document-Word Matrix
#feature_names = tf_vectorizer.get_feature_names()
#
#print("Fitting LDA models with tf features, "
#      "n_samples=%d and n_features=%d..."
#      % (n_samples, n_features))
#
#for k in range(10, 31):
#    print("Fitting model for k = ", k)
#    lda = LatentDirichletAllocation(n_topics=k, max_iter=5,
#                                    learning_method='online',
#                                    learning_offset=50.,
#                                    random_state=0)
#    lda.fit(tf)
#          
#    print("\nTopics in LDA model:")
#    tf_feature_names = tf_vectorizer.get_feature_names()
#    print_top_words(lda, tf_feature_names, n_top_words)
#  
#    filename = outdir + "k" + str(k) + ".txt"
#    with open(filename, "w") as topicfile:
#        for topic_idx, topic in enumerate(lda.components_):
#            k_prefix = "Topic " + str(topic_idx + 1) + ": "
#            topics_suffix = " ".join([feature_names[i]
#                              for i in topic.argsort()[:-n_top_words - 1:-1]])
#            topicfile.write(k_prefix + topics_suffix)
#            topicfile.write('\n')

#  Find theta distributions
#  topic_dist = lda.transform(tf)
#  


