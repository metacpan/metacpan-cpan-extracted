import re
import sys
import os
import gensim
from gensim import utils

def word2vecSim():
    lemma = ""
    wnfilename = sys.argv[-1]
    wnfile = open(wnfilename)
    #train word2vec model on google news vectors
    model = gensim.models.Word2Vec.load_word2vec_format('GoogleNews-vectors-negative300.bin', binary=True)

    highscore = 0
    score = 0
    ideal = 'entity'
    scValue = wnfile.readline()
    scValue = scValue.rstrip()
    cValue = float(scValue)
    lemma = wnfile.readline()
    lemma = lemma.rstrip()
    lemma = lemma.replace("_"," ")

    gloss = wnfile.readline()
    glossArray = gloss.split(" ")
    
    word = wnfile.readline()
    ideal = word
    
    lemmaExists = 1
    try:
        model.similarity('dog',lemma)
    except KeyError:
        lemmaExists = 0
    
    #for each word in WordNet find the similarity between it and the OOV lemma
    while word:
        word = word.rstrip()
        word = word.replace("_", " ")

        #if the lemma does not exist in googlevectors, find similarity between word and lemma's gloss instead
        if lemmaExists == 1:
            try:
                if word != lemma:
                    score = model.similarity(word, lemma)
                else:
                    score = 0
            except KeyError:
                score = 0
        else:
            score = 0
            numCompared = 0
            for lword in glossArray:
                try:
                    score = score + model.similarity(word,lword)
                    numCompared = numCompared + 1
                except KeyError:
                    score = score + 0

            if numCompared > 0:#normalize score
                score = score/numCompared
                
            

        if score > highscore:
            highscore = score
            ideal = word
        word = wnfile.readline()

    del model
    wnfile.close()
    if highscore >= cValue: #if the score is below the confidence value, do not return it
        print ideal
    else:
        print ""
    
word2vecSim()
