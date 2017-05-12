#!/bin/csh

# ------------------------------------------------------------------
# this script shows the use of wrapper program discriminate.pl when
# used in the senseclusters native mode or latent semantic analysis
# mode for carrying out target word sense discrimination
# ------------------------------------------------------------------

# Originally written by Amruta Purandare, 2002-2004
# Modified by Ted Pedersen, July 2006

# the script runs several experiments that shows the use of :

# global Vs local training data

# unigrams, bigram, co-occurrence, and target co-occurrence features 

# first and second order context vectors

# partitional and agglomerative clustering in vector and similarity spaces

# dimensionality reduction via SVD

# evaluation using sense tagged corpus

# cluster stopping using pk1, pk2, pk3 and gap measures

# senseclusters native mode versus latent semantic analysis

# local training is when you have a seperate source of training data
# for each word, global is when you use the same set of data for each
# word. In the case of local, you have some number of contexts that
# contain a given target word, and this may be text that comes from
# sources other than what the other target words use. In global, all
# the training data for all the words is created from the same corpus.

# to use the global training data, reset train variable to "global" 

set train = "local"

#set train = "global"

set svd_params = "--svd"
set lsa_params = "--lsa"

set statistic = "--stat ll --stat_rank 500"

set remove = 5
set window = 2

set expr_path = `pwd`

cd LexSample

    set lexelts = `ls`
    foreach lexelt ($lexelts)
	cd $lexelt

	    echo " %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% "
            echo "                    PROCESSING $lexelt"
	    echo " %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% "

	    mkdir $lexelt
	    mv $lexelt-t* $lexelt

	    # using bigram and co-occurrence features
	    foreach feature (uni bi co tco)

	        # using order1 and order2 vectors
	        foreach context (o1 o2)

		    # using vector and similarity spaces
		    foreach space (vector similarity)

		        # clustering method

		        foreach clmethod (direct rbr)
			   # cluster stopping

			   foreach cluststop (pk1 pk2 pk3 gap)

	                     # svd 
	                     foreach svd (on off)

	                       # lsa 
                               foreach lsa (on off) 

			    echo " ******************************************************** "
			    echo "Running $lexelt with following parameters -"
			    echo "--feature = $feature"
			    echo "--context = $context"
			    echo "--space = $space"
			    echo "--clmethod = $clmethod"
			    echo "--cluststop = $cluststop"
			    echo "--svd = $svd"
			    echo "--lsa = $lsa"

			    cp -r $lexelt $lexelt.$feature.$context.$space.$clmethod.$cluststop.$svd.$lsa
			    cd $lexelt.$feature.$context.$space.$clmethod.$cluststop.$svd.$lsa

	                    # if training mode is local, simply use 
			    # provided training data for each word

			        if ($train == "local") then
		                    set training = "$lexelt-training.count"

			    # if training is global, then create a set
			    # of training examples that include the target
			    # word as found in the test data - each word
	                    # uses the same set of global training data

			        else if ($train == "global") then
			            set training = "$expr_path/Data/eng-global-train.txt"
			            maketarget.pl $lexelt-test.xml 
				    mv $expr_path/Regexs/target.regex $expr_path/Regexs/target.regex.old
			            mv target.regex $expr_path/Regexs/target.regex
                                else 
				    echo "ERROR: train set to invalid value $train"
				    exit
			        endif

				if ($svd == "on") then 
				    set svd_string = "$svd_params"
                                else if ($svd == "off") then
                                    set svd_string = " "
				else 
				    echo "ERROR: svd set to invalid value $svd"
				    exit
                                endif

				if ($lsa == "on") then 
				    set lsa_string = "$lsa_params"
                                else if ($lsa == "off") then
                                    set lsa_string = " "
				else 
				    echo "ERROR: lsa set to invalid value $lsa"
				    exit
                                endif

				echo " -------------------------------------------------------- " 
				echo " Results in Directory: $lexelt.$feature.$context.$space.$clmethod.$cluststop.$svd.$lsa"
				echo " -------------------------------------------------------- " 
			        echo "discriminate.pl --showargs --verbose --eval $lsa_string --space $space --clmethod $clmethod --token $expr_path/Regexs/token.regex --target $expr_path/Regexs/target.regex --prefix $lexelt --context $context $svd_string --feature $feature --remove $remove --window $window --stop $expr_path/Regexs/stoplist-nsp.regex --cluststop $cluststop $statistic --training $training $lexelt-test.xml"

			        discriminate.pl --showargs --verbose --eval $lsa_string --space $space --clmethod $clmethod --token $expr_path/Regexs/token.regex --target $expr_path/Regexs/target.regex --prefix $lexelt --context $context $svd_string --feature $feature --remove $remove --window $window --stop $expr_path/Regexs/stoplist-nsp.regex --cluststop $cluststop $statistic --training $training $lexelt-test.xml
				echo " ******************************************************** "

			        cd ..
                               end # end of lsa
	                     end # end of svd
	                   end # end of cluststop
		        end # end of clmethod loop
		    end # end of space loop
	        end # end of context loop
	    end # end of feature loop
        cd ..
    end
cd ..


