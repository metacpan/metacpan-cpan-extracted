*******************************************************************************

                     README.txt FOR clusterstopping.pl Testing

                               Version 0.02
                         Copyright (C) 2006-2008
                       Ted Pedersen, tpederse@d.umn.edu
                    Anagha Kulkarni, kulka020@d.umn.edu
                       University of Minnesota, Duluth

*******************************************************************************

Introduction:
----------------
The scripts provided here test the behaviour of clusterstopping.pl program under
various conditions.

Tests:
-------
The test scripts are written in the files test*.sh

Normal Cases
------------
NOTE: testA1 through testA7 are platform dependent, that is, each of these tests
clusterstopping.pl based on the platform (Linux and Solaris). The need for doing
this arises because the predictions are different in few cases across the two 
platform, which in turn is caused because of the different criterion function 
values retuned by Cluto across different platforms.

testA1.sh tests clusterstopping.pl with default settings.
testA2.sh tests clusterstopping.pl when using all measures in vector space.
testA3.sh tests clusterstopping.pl in similarity space with only pk measures.
testA4.sh tests clusterstopping.pl in similarity space with all options.
testA5.sh tests clusterstopping.pl in vector space using only pk measures and many other options.
testA6.sh tests clusterstopping.pl in vector space using slightly atypical option values.
testA7.sh tests clusterstopping.pl in vector space and delta set to 0.
testA8.sh tests clusterstopping.pl in vector space on a contrived (clean) data to test the 
prediction consistency across platforms.

Conclusions:
---------------
We have tested the clusterstopping.pl program enough and say that it behaves
according to our expectations. The test scripts could also be used to check the
backward compatibility when the program is enhanced in future.
