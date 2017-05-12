*******************************************************************************

		     README.txt FOR Testing order2vec.pl

                               Version 0.09
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for order2vec.pl
-------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
01/18/2004


1. Introduction:
----------------

This program is a component of a SenseClusters package that constructs
second order context vectors. The scripts and files provided here could be 
used to test the correct behaviour of the program and backward compatibility.

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test order2vec.pl under normal conditions.

Test A1:	 Tests order2vec when the word matrix has all integral
		 values 

Test A2:	 Tests order2vec when the word matrix is created by 
		 SVD

Test A3:	 Tests order2vec when the word matrix is very sparse

Test A4:	 Tests order2vec when some of the contexts are duplicated

Test A5:	 Tests order2vec when no context word has a word vector 

Test A6:	 Tests order2vec when token include punctuations and are 
		 defined via --token option

Test A7:	 Tests options --rlabel, --rclass in order2vec 

Test A8:	 Tests order2vec's --binary option on binary, int & 
		 real word vectors

Test A9:	 Tests order2vec on POS tagged data where tokens include POS
		 tags

Test A10:	 Tests order2vec on unigram features from order1vec.pl in
		 LSA context clustering mode, binary and non-binary

Test A11:	 Tests order2vec on bigram features from order1vec.pl in
		 LSA context clustering mode, binary and non-binary

Test A12:	 Tests order2vec on co-occurrence features from order1vec.pl 
		 in LSA context clustering mode, binary and non-binary

Test A13:	 Tests order2vec on target co-occurrence features from 
		 order1vec.pl in LSA context clustering mode, binary and 
		 non-binary

2.2 Error conditions:
---------------------

Tests written in testB*.sh test order2vec.pl under error conditions.

Test B1:	Tests order2vec when #features dont match the #word vectors

Test B2:	Tests order2vec when first line in WORDVEC file doesn't
		show #rows #cols #nnz or #rows #cols when --dense is ON

Test B3:	Tests order2vec when first line in WORDVEC shows wrong 
		number of vectors 

Test B4:	Tests order2vec when first line in WORDVEC shows wrong 
		number of non-zero entries

Test B5:	Tests order2vec when the column index of a non-zero entry
		exceeds the number of columns specified on line 1


3. Conclusions:
---------------

We have tested program order2vec.pl and conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
order2vec.pl can be compared to the current version against these scripts.

