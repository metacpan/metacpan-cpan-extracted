#!/bin/csh

# This script sets up data in the "lexical sample" format that is
# commonly used in Senseval exercises. That means that there is a 
# directory created (called LexSample) that contains subdirectories,
# one for each word we wish to sense discriminate. 

# Originally written by Amruta Purandare, 2002-2004 
# Modified by Ted Pedersen, July 2006

if(-e LexSample) then
	echo "LexSample already exists."
	echo "Remove directory LexSample before running makedata.sh"
	exit 1
endif

# The input data must be in Senseval2 format, and if there are multiple
# lexelts in the input file, then those will be split up so that there
# is one directory per lexelt in LexSample

# training and test file must be in /Data directory

set DATADIR  = Data
set TRAINING = eng-lex-sample.training.xml
set TEST     = eng-lex-sample.evaluation.xml
set KEY      = $DATADIR/eng-lex-sample.key

set REGEXDIR = Regexs
set TOKEN    = $REGEXDIR/token.regex
set NONTOKEN = $REGEXDIR/nontoken.regex

# we move the train/test data from its home in DATADIR up one level  
# because of setup.pl requirements and structure

cd $DATADIR
gunzip *.gz

cp $TRAINING ..
cp $TEST ..

cd ..

# preprocessing - this will split the training and test data up into 
# separate files based on the lexelt, and put them in their own directory

setup.pl --verbose --showargs --training $TRAINING --key $KEY --token $TOKEN --nontoken $NONTOKEN $TEST

	rm -fr $TRAINING $TEST

	cd LexSample

	rm -fr token.regex nontoken.regex

	# we run demo only on selected words that we have 
	# experimeted with for Amruta's Thesis experiments
	# removing other words ...

	rm -fr bum.n call.v carry.v chair.n colourless.a detention.n develop.v draw.v dress.v drift.v drive.v dyke.n face.v faithful.a fatigue.n feeling.n ferret.v find.v fit.a graceful.a green.a hearth.n holiday.n keep.v lady.n leave.v local.a match.v nation.n nature.n oblique.a play.v pull.v replace.v restraint.n see.v sense.n serve.v solemn.a spade.n stress.n strike.v treat.v turn.v use.v vital.a wander.v wash.v work.v yew.n

	set lexelts = `ls`
	
	foreach lexelt ($lexelts)
	
		cd $lexelt
	
			# we only need test.xml and training.count
			rm -fr $lexelt-training.xml $lexelt-test.count

			# Senseval-2 data has a large number of senses,
                        # and some of the words have instances with 
			# multiple correct answers. SenseClusters assumes
	 	        # that each instance only has one correct answer,
	                # so we must filter the data to make that true.

		        # create a table showing the number of instances
                        # that occur with each sense. This is needed by
	                # filter.pl

			frequency.pl $lexelt-test.xml > frequency

	                # remove all but the most frequent sense for those
	                # instances that have multiple answers (--nomulti)
	                # and remove all instances associated with senses
                        # that occur 5 percent of the time or less (--percent)

	                # it is also possible with filter to ask for the 
	                # top N senses for each word (--rank N) but we do 
			# not do that here

			filter.pl --nomulti --percent 5 $lexelt-test.xml frequency > $lexelt-test.xml.fil

			mv $lexelt-test.xml.fil $lexelt-test.xml

			rm -fr frequency
		cd ..
	end
cd ..

gzip Data/eng*
