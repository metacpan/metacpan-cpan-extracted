================================================================================
                              SEMEVAL-2016 TASK 14
                          Semantic Taxonomy Enrichment
                   David Jurgens and Mohammad Taher Pilehvar
================================================================================
                     http://alt.qcri.org/semeval2016/task14/
================================================================================

=============
THE TASK
=============

Task 14 aims to enrich the WordNet taxonomy with new words and word senses. For
a word sense which is not already defined in the WordNet sense inventory, a
system in this task has to identify either:

 a) the WordNet synset that is a generalization of the new word sense (i.e., its
    hypernym), or

 b) the WordNet synset whose word senses are synonyms to the new word sense.

To complete the task, a system is provided with a specific word sense, i.e., a
word together with its definition. A system's objective is then to identify the
WordNet synset to which the new word sense should be merged (i.e., the term is
synonymous with those in the synset) or added as a hyponym (i.e., the new word
sense is a specialization of an existing word sense).


==================
PACKAGE CONTENTS
==================

The training and trial package contains the following:

README.txt                this file
evaluation/scorer.py      program for scoring the outputs
data/trial/               tab separated input file with trial data definitions
data/training/            tab separated input file with training data definitions
keys/gold/trial/          gold-standard answer keys for the trial data
keys/baseline/trial/      baseline system answer keys for the trial data
keys/gold/training/       gold-standard answer keys for the training data
keys/baseline/training/   baseline system answer keys for the training data


============
SYSTEM TYPES
============

Task 14 allows two types of systems:

  1) Constrained systems are restricted attempting to cross-reference the
     provided definitions within existing dictionaries and from using additional
     source-specific information provided within the originating document to
     improve integration (e.g., using Wiki- or HTML-markup patterns, identifying
     semantically-related words on the originating documents page, etc.).

  2) Source-aware systems may use all information provided in the
     originating-document's content to improve attachment.

Each definition in the dataset has an associated URL linking to the originating
document, which Source-aware systems may use.  Note that the document containing
the definition may contain other definitions as well (e.g., the definition is
one in a list of domain terminology) or it may be a single page dedicated to
that concept.  

We allow for both types of systems in order to determine the performance
difference between general-purpose methods that are capable of operating on all
types of definition input versus those systems that are tailored to specific
resources.  Furthermore, when the sites containing the source document exhibit
systematic structure, this may allow for approaches to try resource alignment
techniques for integrating the target.


=================
INPUT DATA FORMAT
=================

The input file consists of a tab-separated file with five columns:

lemma <tab> part-of-speech <tab> item-id <tab> definition <tab> definition source URL


==============
OUTPUT FORMAT
==============

System are expected to produce output in a tab-separated file, formatted as

item-id <tab> WordNet sense <tab> operation

Here, WordNet senses are specified as lemma#pos#number where the sense number
begins at 1 ("pos" means part of speech).  The WordNet 3.0 senses inventory is
used as ground truth.

The operation should be either "merge" or "attach".  For simplicity, these may
be abbreviated as 'm' or 'a', respectively, in the file.


============
EVALUATION
============

Evaluation are performed according to two official metrics and one unofficial
metric:

1) Wu & Palmer Similarity: This metric calculates the Wu & Palmer similarity
   between the synset locations where the correct integration would be and where
   the system has placed the synset.  The similarity score is in [0,1].  The
   mean similarity is reported.

2) Recall: the percentage of items that are integrated by the solution.

The unofficial metric is:

a) Lemma matches: This matches the percentage of answers where the operation is
   correct and the correct and system-provided synsets share a lemma (i.e., are
   senses of the word).  The difference between this score and the Wu & Palmer
   score reflects the cases where the system has identified the correct
   operation and lemma but has selected the wrong sense of the lemma.


================
BASELINE SYSTEMS
================

Two baseline systems are included for comparison:

a) the random baseline simply chooses a random synset of the appropriate part
   of speech and a random operation.  This baseline reflects the expected
   random performance.

b) the first word, first sense baseline looks for the first head word in the
   definition with the same part of speech as the target word and then chooses
   the first sense of that word.  



=============
PARTICIPATION
=============

Please visit our page in order to participate in the task:

http://alt.qcri.org/semeval2016/task14/

We invite potential participants to join our Google group:

<TBD>



===============
IMPORTANT DATES
===============

Trian data ready: June 30. 2015
Training data ready: September 7, 2015
Test data ready: December 15, 2015
Evaluation start: January 10, 2015
Evaluation end: January 31, 2015
Paper submission due: February 28, 2016 [TBC]
Paper reviews due: March 31, 2016 [TBC]
Camera ready due: April 30, 2016 [TBC]
SemEval 2016 workshop: Summer 2016


