*******************************************************************************

                     README.txt FOR clusterlabeling.pl Testing

                               Version 0.01
                         Copyright (C) 2004-2005
                       Ted Pedersen, tpederse@d.umn.edu
                    Anagha Kulkarni, kulka020@d.umn.edu
                       University of Minnesota, Duluth

*******************************************************************************

Introduction:
----------------
The scripts provided here test the behaviour of clusterlabeling.pl program under
various conditions.

Tests:
-------
The test scripts are written in the files test*.sh

Normal Cases
------------
testA1.sh tests clusterlabeling.pl for a no label cluster.
testA2.sh tests clusterlabeling.pl for non-unique labels.
testA3.sh tests clusterlabeling.pl for unique labels.
testA4.sh tests clusterlabeling.pl with Pointwise Mutual Information (pmi) as the test of association.
testA5.sh tests clusterlabeling.pl without stoplist.
testA6.sh tests clusterlabeling.pl for ngram parameter with trigram feature without stoplist (to see if we are capturing important phrases).
testA7.sh tests clusterlabeling.pl for ngram parameter with trigram feature with stoplist.

Conclusions:
---------------
We have tested the clusterlabeling.pl program enough and say that it behaves
according to our expectations. The test scripts could also be used to check the
backward compatibility when the program is enhanced in future.
