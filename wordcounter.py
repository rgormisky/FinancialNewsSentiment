# -*- coding: utf-8 -*-
"""
Created on Thu Apr 13 11:19:34 2017

@author: rolgo8

counts positive and negative words (defined by General Inquirer dictionary)
in a given document.

Dictionary URL: http://www.wjh.harvard.edu/~inquirer/spreadsheet_guide.htm
"""

import openpyxl as pyxl
import re

dict_wb = pyxl.load_workbook('inquirerbasic.xlsx')
dict_first_sheet = dict_wb.get_sheet_by_name(dict_wb.get_sheet_names()[0])

dict_data = dict_first_sheet.values
dict_cols = next(dict_data)[1:]
dict_data = list(dict_data)

# select positive and negative words, filter # signs and numbers out of data
pos_words = set([re.sub('(#|\d)', '', str(r[0]).lower()) for 
                 r in dict_data if not r[2] is None])
neg_words = set([re.sub('(#|\d)', '', str(r[0]).lower()) for 
                 r in dict_data if not r[3] is None])

def count_words(document, category_string):
    '''
    document is a string representing an article. We wish to count either the
    positive or negative words in the document. 
    
    category_string is a string which indicates whether to count positive or 
    negative words. It can take values of 'pos' or 'neg' at present. This
    design allows extensions to other categories of words.
    
    Returns a tuple of (the number of words in the document, the number
    of words in the specified category)
    '''
    if category_string == 'pos':
        word_set = pos_words
    else:
        word_set = neg_words
    
    doc_nopunct_nonum = re.sub('[\W\d]', ' ', document)
    
    words = [w.lower() for w in doc_nopunct_nonum.split(' ') if w != '']
    word_count = len(words)
    category_word_count = len([w for w in words if w in word_set])
    return(word_count, category_word_count)
 