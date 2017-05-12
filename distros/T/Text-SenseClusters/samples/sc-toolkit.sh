#!/bin/csh

# this script shows how to put together the programs in 
# SenseClusters' Toolkit with the ones distributed with
# NSP, SVDPACK and CLUTO to run discrimination experiments
# in order to carry out target word discrimination using 
# the SenseClusters native model

# the script demonstrates the use of :

# global Vs local training data
# bigram and co-occurrence features
# first and second order context vectors
# partitional and agglomerative clustering in vector and similarity spaces
# dimensionality reduction via SVD
# evaluation using sense tagged corpus

# to use global (generic) training data, reset train to "global"
set train = "local"
#set train = "global"

set expr_path = `pwd`

set remove = 2
set window = 5
set clusters = 5

set statistic = "--precision 8 --score 3.841 ll"

# note that with a reduction factor of 5 and a window size of 2
# fine and natural hung when running las2, that is they would 
# essentially run forever. We aren't sure why this happened. 

set svd_params = "--param --k 50 --rf 10 --numform 4f20.8"

# global data is assumed to be very large
# hence, we run huge-count.pl instead of normal count.pl

if($train == "global") then
	
	cp Data/eng-global-train.txt global-train

	echo "counting bigrams in global-train"
	echo "this will take about 30 mins."
	huge-count.pl --split 2 --token $expr_path/Regexs/token.regex --stop $expr_path/Regexs/stoplist-nsp.regex --newLine --remove $remove --window $window global-train.count global-train

	# if the above seems to consume lot of memory on your machine,
	# increase the --split value

	mv global-train.count/huge-count.output global-train.bigrams
	/bin/rm -r global-train.count
endif

cd LexSample

	set lexelts = `ls`
	foreach lexelt ($lexelts)
		cd $lexelt

			echo "*************************************"
			echo "      PROCESSING $lexelt"
			echo "*************************************"

			echo "finding unigrams in test data"
                        sval2plain.pl $lexelt-test.xml > $lexelt-test.count
                        count.pl --ngram 1 --stop $expr_path/Regexs/stoplist-nsp.regex --token $expr_path/Regexs/token.regex $lexelt-test.uni $lexelt-test.count

			if($train == "local") then
				echo "counting bigrams in local train"
				count.pl --token $expr_path/Regexs/token.regex --stop $expr_path/Regexs/stoplist-nsp.regex --newLine --remove $remove --window $window $lexelt.bigrams $lexelt-training.count

				cp $expr_path/Regexs/target.regex .
			else
				echo "reducing global bigram file"
				reduce-count.pl $expr_path/global-train.bigrams $lexelt-test.uni > $lexelt.bigrams

				echo "making target regex"
	                        maketarget.pl $lexelt-test.xml

			endif

			echo "combining counts"
			combig.pl $lexelt.bigrams > $lexelt.cocs

			echo "statistic"
			statistic.pl $statistic $lexelt.bigrams.stat $lexelt.bigrams
			statistic.pl $statistic $lexelt.cocs.stat $lexelt.cocs

			echo "finding focs"
			kocos.pl --order 1 --regex target.regex $lexelt.cocs.stat > $lexelt.focs

			# 1st order context vectors
			echo "finding feature regexs"
			nsp2regex.pl $lexelt.bigrams.stat > $lexelt.bigrams.regex
			nsp2regex.pl $lexelt.focs > $lexelt.focs.regex

			foreach feature (bigrams focs)
				if(-e "$lexelt.rlabel") then
					set order1_params = ""
				else
					set order1_params = "--rlabel $lexelt.rlabel --rclass $lexelt.rclass"
				endif

				echo "creating 1st order contexts"
				order1vec.pl $order1_params $lexelt-test.xml $lexelt.$feature.regex > $lexelt.$feature.o1

				# all experiments will have the same keyfile
				# hence we want to keep only one copy

				mv keyfile*.key keyfile
			end

			# 2nd order context vectors

			echo "creating word co-occurrence vectors"

			# note that wordvec is creating a new feature file 
			# (--feats) rather than using the existing feature 
			# unigram file (lexelt-test.uni) This means the 
			# resulting wordvec file will only include rows 
			# for features observed in the test data
			
			wordvec.pl --feats $lexelt-test.cocs.uni --wordorder nocare $lexelt.cocs.stat > $lexelt.cocs.wordvec
			echo "creating regexes for word co-occurrence features"
			nsp2regex.pl $lexelt-test.cocs.uni > $lexelt-test.cocs.uni.regex
			
			echo "creating word bigram vectors"
			wordvec.pl --feats $lexelt-test.bigrams.uni --wordorder follow $lexelt.bigrams.stat > $lexelt.bigrams.wordvec
			echo "creating regexes for bigram features"
			nsp2regex.pl $lexelt-test.bigrams.uni > $lexelt-test.bigrams.uni.regex

			foreach feature (bigrams cocs)
				set wordvec = "$lexelt.$feature.wordvec"
				echo "svd"
				mat2harbo.pl $svd_params $wordvec > matrix
				las2
				mv matrix $wordvec.harbomat
				svdpackout.pl --format f20.8 --rowonly lav2 lao2 > $wordvec.svd
				/bin/rm lap2
				echo "creating 2nd order contexts"
				order2vec.pl --dense --format f20.8 $lexelt-test.xml $wordvec.svd $lexelt-test.$feature.uni.regex > $lexelt.$feature.o2
				mv keyfile*.key keyfile
			end

			echo "clustering"
			foreach vectype (o1 o2)
				set vectors = `ls *.$vectype`
				foreach vector ($vectors)
					foreach clmethod (rbr agglo)
						echo "running vcluster $clmethod"
						vcluster --clustfile $vector.$clmethod.cluster_solution --rlabelfile $lexelt.rlabel --rclassfile $lexelt.rclass  --clmethod $clmethod --sim cos $vector $clusters > $vector.$clmethod.cluster_output
					end
					echo "running simat"
					if($vectype == "o2") then
						set simat_params = "--dense"
					else
						set simat_params = ""
					endif
					set simat = "$vector.simat"
					simat.pl $simat_params $vector > $simat

					foreach clmethod (rbr agglo)
						echo "running scluster $clmethod"
						scluster --clustfile $simat.$clmethod.cluster_solution --rlabelfile $lexelt.rlabel --rclassfile $lexelt.rclass --clmethod $clmethod $simat $clusters > $simat.$clmethod.cluster_output
					end
				end
			end
			echo "evaluation"
			set cluster_solutions = `ls *.cluster_solution`
			foreach cluster_solution ($cluster_solutions)
				set expr = `echo $cluster_solution | sed 's/\.cluster_solution//'`
				cluto2label.pl $cluster_solution keyfile > $expr.confusion
				label.pl $expr.confusion > $expr.label
				report.pl $expr.label $expr.confusion > $expr.report
				echo "*************************************"
	                        echo "  $expr"
        	                echo "*************************************"

				cat $expr.report
			end
		cd ..
	end

cd ..
