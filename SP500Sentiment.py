# -*- coding: utf-8 -*-
"""
Created on Tue Apr 11 15:15:34 2017

@author: rolgo8

Use the getKeyDevList function in reuterskeydev.py to scrape articles for
all (except 2) companies in the S&P. Treat this set of articles as a single corpus
and perform Latent Dirichlet Allocation to automatically extract latent topics.
The topics themselves are written to '../topicdistributions'
"""

import openpyxl as pyxl
import reuterskeydev as rkd
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation

# For reporting and debugging the topic output
def print_top_words(model, feature_names, n_top_words):
    for topic_idx, topic in enumerate(model.components_):
        print("Topic #%d:" % topic_idx)
        print(" ".join([feature_names[i]
                        for i in topic.argsort()[:-n_top_words - 1:-1]]))
    print()

ticker_wb = pyxl.load_workbook('SPtickers.xlsx')
first_sheet_name = ticker_wb.get_sheet_names()[0]
first_sheet = ticker_wb.get_sheet_by_name(first_sheet_name)

ticker_data = first_sheet.values
ticker_cols = next(ticker_data)[1:]
ticker_data = list(ticker_data)
ticker_list = [r[0] for r in ticker_data]

ticker_ban_list = ['HAR', 'LLTC'] #HAR is Indian company, LLTC acquired by ADI

event_tuple_list = []
article_text_list = []
for ticker in ticker_list:
    print(ticker)
    if ticker in ticker_ban_list:
        continue
    ticker_tuples = rkd.getKeyDevList(ticker)
    article_text_list += [r[2] for r in ticker_tuples]
    event_tuple_list += ticker_tuples

# Begin LDA on the entire S&P corpus
n_samples = len(article_text_list)
n_features = 1000000 # possible words, set arbitrarily high
n_top_words = 25  # words per topic

outdir = r'L:\Robert\FinancialNewsSentiment\topicdistributions' + '\\'
    
print("Extracting tf features for LDA...")
tf_vectorizer = CountVectorizer(max_df=0.95, min_df=1,
                                max_features=n_features,
                                stop_words='english')
tf = tf_vectorizer.fit_transform(raw_documents= article_text_list) # Document-Word Matrix
feature_names = tf_vectorizer.get_feature_names()

print("Fitting LDA models with tf features, "
      "n_samples=%d and n_features=%d..."
      % (n_samples, n_features))

for k in range(10, 31):
    print("Fitting model for k = ", k)
    lda = LatentDirichletAllocation(n_topics=k, max_iter=5,
                                    learning_method='online',
                                    learning_offset=50.,
                                    random_state=0)
    lda.fit(tf)
          
    print("\nTopics in LDA model:")
    tf_feature_names = tf_vectorizer.get_feature_names()
    print_top_words(lda, tf_feature_names, n_top_words)
  
    filename = outdir + "k" + str(k) + ".txt"
    with open(filename, "w") as topicfile:
        for topic_idx, topic in enumerate(lda.components_):
            k_prefix = "Topic " + str(topic_idx + 1) + ": "
            topics_suffix = " ".join([feature_names[i]
                              for i in topic.argsort()[:-n_top_words - 1:-1]])
            topicfile.write(k_prefix + topics_suffix)
            topicfile.write('\n')

#  Find theta distributions
#  topic_dist = lda.transform(tf)
#  
#  csvname = datadir + "k" + str(k) + ".csv"
#  with open(csvname, "wb") as csvfile:
#    writer = csv.writer(csvfile, delimiter=',', quotechar='|', 
#                        quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
#    writer.writerows(topic_dist)

