#!/bin/csh

# ------------------------------------------------------------------
# this script shows the use of wrapper program discriminate.pl when
# used in the senseclusters native mode or latent semantic analysis
# mode for carrying out word or feature clustering
# ------------------------------------------------------------------

# Originally written by Amruta Purandare, 2002-2004
# Modified by Ted Pedersen, July 2006

# the script runs several experiments that shows the use of :

# unigrams, bigram, co-occurrence, and target co-occurrence features 

# first and second order context vectors

# partitional and agglomerative clustering in vector and similarity spaces

# dimensionality reduction via SVD

# cluster stopping using pk1, pk2, pk3 and gap measures

# senseclusters native mode versus latent semantic analysis

set svd_params = "--svd"
set lsa_params = "--lsa"

set statistic = "--stat ll --stat_score 3.841"

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
		        # using agglomerative and
 		        # partitional clustering
		        foreach clmethod (agglo rbr)
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

				if ($svd == "on") then 
				    set svd_string = "$svd_params"
                                else
                                    set svd_string = " "
                                endif

				if ($lsa == "on") then 
				    set lsa_string = "$lsa_params"
                                else
                                    set lsa_string = " "
                                endif

				echo " -------------------------------------------------------- "
				echo " Results in Directory: $lexelt.$feature.$context.$space.$clmethod.$cluststop.$svd.$lsa"
				echo " -------------------------------------------------------- "

			        echo "discriminate.pl --showargs --verbose --wordclust $lsa_string --space $space --clmethod $clmethod --token $expr_path/Regexs/token.regex --prefix $lexelt --context $context $svd_string --feature $feature --remove $remove --window $window --stop $expr_path/Regexs/stoplist-nsp.regex --cluststop $cluststop $statistic $lexelt-test.xml"

			        discriminate.pl --showargs --verbose --wordclust $lsa_string --space $space --clmethod $clmethod --token $expr_path/Regexs/token.regex --prefix $lexelt --context $context $svd_string --feature $feature --remove $remove --window $window --stop $expr_path/Regexs/stoplist-nsp.regex --cluststop $cluststop $statistic $lexelt-test.xml

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

