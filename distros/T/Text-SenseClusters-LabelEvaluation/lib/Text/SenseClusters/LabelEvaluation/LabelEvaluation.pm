#!/usr/bin/perl -w

# Defining the Package for the modules.
package Text::SenseClusters::LabelEvaluation::LabelEvaluation;

use strict; 
use encoding "utf-8";

# Defining the version for the Progrm.
our $VERSION = '0.06';

# Including the FileHandle module.
use FileHandle;

# Including the other dependent Modules.
use Text::SenseClusters::LabelEvaluation::ReadingFilesData;
use Text::SenseClusters::LabelEvaluation::PrintingHashData;
use Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData;
use Text::SenseClusters::LabelEvaluation::SimilarityScore;
use Text::SenseClusters::LabelEvaluation::ConfusionMatrixTotalCalc;

#######################################################################################################################

=head1 Name 

Text::SenseClusters::LabelEvaluation - Module for evaluation of labels of the clusters. 

=head1 SYNOPSIS

	The following code snippet will evaluate the labels by comparing
	them with text data for a gold-standard key from Wikipedia .

	# Including the LabelEvaluation Module.
	use Text::SenseClusters::LabelEvaluation::LabelEvaluation;
	# Including the FileHandle module.
	use FileHandle;

	# File that will contain the label information.
	my $labelFileName = "temp_label.txt";

	# Defining the file handle for the label file.
	our $labelFileHandle = FileHandle->new(">$labelFileName");

	# Writing into the label file.
	print $labelFileHandle "Cluster 0 (Descriptive): George Bush, Al Gore, White House,". 
	   			" COMMENTARY k, Cox News, George W, BRITAIN London, U S, ".
	  			"Prime Minister, New York \n\n";
	print $labelFileHandle "Cluster 0 (Discriminating): George Bush, COMMENTARY k, Cox ".
	   			"News, BRITAIN London \n\n";
	print $labelFileHandle "Cluster 1 (Descriptive): U S, Al Gore, White House, more than,". 
	   			"George W, York Times, New York, Prime Minister, President ".
	   			"<head>B_T</head>, the the \n\n";
		print $labelFileHandle "Cluster 1 (Discriminating): more than, York Times, President ".
	   			"<head>B_T</head>, the the \n";
	   						
	# File that will contain the topic information.
	my $topicFileName = "temp_topic.txt";

	# Defining the file handle for the topic file.
	our $topicFileHandle = FileHandle->new(">$topicFileName");

	# Writing into the Topic file.
	# Bill Clinton  ,   Tony  Blair 
	print $topicFileHandle "Bill Clinton  ,   Tony  Blair \n";

	# Closing the handles.
	close($labelFileHandle);								
	close($topicFileHandle);								

	# Calling the LabelEvaluation modules by passing the following options

	%inputOptions = (

			labelFile => $labelFileName, 
			labelKeyFile => $topicFileName
	);	


	# Calling the LabelEvaluation modules by passing the name of the 
	# label and topic files.
	my $score = Text::SenseClusters::LabelEvaluation::LabelEvaluation->
			new (\%inputOptions);
		

	# Printing the score.			
	print "\nScore of label evaluation is :: $score \n";

	# Deleting the temporary label and topic files.
	unlink $labelFileName or warn "Could not unlink $labelFileName: $!";								
	unlink $topicFileName or warn "Could not unlink $topicFileName: $!";


=head1 DESCRIPTION

	This Program will compare the result obtained from the SenseClusters with that 
	of Gold Standards. Gold Standards will be obtained from two independent and 
	reliable source:
			1. Wikipedia
			2. Wordnet
			
	For fetching the Wikipedia data it use the WWW::Wikipedia module from the CPAN 
	and for comparison of Labels with Gold Standards it uses the Text::Similarity
	Module. The comparison result is then further processed to obtain the result
	and score of result.
			


Result:

   a) Decision Matrix:	
	         Based on the similarity comparison of Labels with the gold standards,
	         the decision matrix are calculated as below:

	For eg:
	===========================================================================
			 	|	Cluster0	|	Cluster1	|		Row Total
	---------------------------------------------------------------------------
	Topic#1		|		271 	|		2713 	|			2984
	---------------------------------------------------------------------------
	Topic#2		|		2396 	|		306 	|			2702
	---------------------------------------------------------------------------
	Col Total	|		2667	|		3019	|			5686
	===========================================================================

	b) Calculated decision Matrix:	
	         Now based on decision matrix, a new calculated matrix is printed. 
	         Each of the cell in the matrix, will contains the probabilities value:
			
				CELL_VALUE_IN_DECISION_MATRIX / TOTAL_SCORE_OF_DECISION_MATRIX
			
		
	For eg:
		For cell : Cluster0 - Topic#1   
			i) First -Value = 271 / 5686 = 0.048


	         Now based on above decision matrix, new calculated matrix is: 
	========================================================================
				|	Cluster0		|	Cluster1	
	------------------------------------------------------------------------
	Topic#1		|	0.048 			|	0.477
	------------------------------------------------------------------------
	Topic#2		|	0.421 			|	0.054
	------------------------------------------------------------------------


	c) Interpreting Calculated decision Matrix:	
		
			1. Row-Wise Comparison
				For each topic, "row score" will be compared and cluster with maximum 
				value will be assigned to that topic.
				for eg: 
					a) Topic#1  	Cluster1     (max-row-score = 0.477 )
				 	b) Topic#2  	Cluster0     (max-row-score = 0.421 )
				 	
			2. Col-Wise Comparison
				For each Cluster, "col score" will be compared and topic with maximum 
				value will be assigned to that Cluster.
				for eg: 
					a) Cluster0  	Topic#2     (max-col-score = 0.421 )
				 	b) Cluster1  	Topic#1     (max-col-score = 0.477 )

	d)	Deriving final conclusion from above two comparison:
		
		Result of Row-Wise comparison and Column-wise comparison is matched.
		Only matching result is then printed.

		For eg:
			1. Row-Wise Comparison
				 a) Topic#1  	Cluster1 
				 b) Topic#2  	Cluster0 
			2. Col-Wise Comparison
				 a) Cluster0  	Topic#2    
				 b) Cluster1  	Topic#1 

		Matching Result: 
				Cluster0 	Topic#2
				Cluster1 	Topic#1   

	e) Overall score:
			This is the multiplication of all the probability scores of all
			matching cluster and topics.
			
			For eg:
				The score for above example will be: 0.201
			 
			


=cut


#######################################################################################################################

# Declaring the global variables for the LabelEvaluation. 

# 1. labelFile: 
# 		Name of the file containing the labels from sense cluster. 
our $senseClusterLabelFileName;	

# 2. labelKeyFile:      
#		Name of the file containing the comma separated actual topics (keys)  
#		for the clusters. 
our $topicsFileName;
	
# 3. This variable contains the lenth of the data to be fetched from gold
#    standard source. 
our $labelKeyLength = 0;

# 4. This variable will tell the ratio of weightage of Discriminating labels 
# 	 over weightage of descriptive labels. Default value is set to 10.
our $weightRatio = 10;

# 5. This variable will tell user supplied location of file that contains 
# 	 the stop list.
our $stopListFileLocation = "";

# 6. This variable will decide whether to keep or delete temporary files.
our $isClean = 0;

# 7. Variable used for the deciding whether to show detailed results
# 	 to user or not.
# 	 Default value = Off, to make it 'On' change value to 1.
our $isDecisionMatrixDebugOn = 0;

# 8. This variable will decide whether to display help to user or not.
our $help = "";



# Defining the name of the Source from where we are getting the text, for 
# finding the label.
our $standardReferenceName_Global = "Wikipedia"; 

# Defining the file handle for the output file.
our $outFileHandle;

sub new{

	# Global variable for storing the labels from the sense cluster.
	our %labelSenseClustersHash_Global =();

	# Openning the output file in Write mode.
	open ($outFileHandle, ">&", \*STDERR) or die "Can't duped STDERR: $!";
	
	# This variable is never used, so can be ignored.
	our $programName = shift;
	
	
	# Add here the options code:
	
	# Getting the options-hash from the command line argument. 
	our $optionHashRef = shift;
	
	# Getting the options hash from its reference.
	our %optionsHash = %$optionHashRef;
	
	# OptionsHash the following options:
	# 1. labelFile: 
	#	Name of the file containing the labels from sense cluster. The syntax of file 
	#	must be similar to label file from SenseClusters. This is the mandatory option.
	#
	# 2. labelKeyFile:      
	#	Name of the file containing the comma separated actual topics (keys) for the 
	#	clusters. This is the mandatory option.
	#
	# 3. labelKeyLength: 
	#	This parameters tell about the length of data to be fetched from Wikipedia 
	#	which will be used as reference data. Default is the first section of the 
	#	Wikipedia page.
	#
	# 4. weightRatio:       
	#	This ratio tells us about how much the weight we should provide to Discriminating 
	#	label to that of the descriptive label. Default value is set to 10.
	#
	# 5. stopList:             
	# 	This is the name of file which contains the list of all stop words. This is the 
	#	optional parameter.
	#	
	# 6. isClean:              
	#	This option tells us whether to keep temporary files or not. Default value is 
	#	true
	#
	# 7. verbose:             
	#	This option will let you see details output. Default value is false.
	#
	# 8. help :                 
	#	This option will show the details about running this module. This is the 
	#	optional parameter.
	#
	
	
	# 1. labelFile
	if($optionsHash{"labelFile"}){
		$senseClusterLabelFileName = $optionsHash{"labelFile"};
	}else{
		# display here the help .TODO, write here properly.
		print STDERR "Please type help to see how to run the program!";
	}
	
	# 2. labelKeyFile
	if($optionsHash{"labelKeyFile"}){
		$topicsFileName = $optionsHash{"labelKeyFile"};
	}else{
		# display here the help .TODO, write here properly.
		print STDERR "Please type help to see how to run the program!";
	}

	# 3. Weight ratio.
	if($optionsHash{"weightRatio"}){
		$weightRatio = $optionsHash{"weightRatio"};
	}
		
	# 4. Weight ratio.
	if($optionsHash{"labelKeyLength"}){
		$labelKeyLength = $optionsHash{"labelKeyLength"};
	}
		
	# 5. Setting the option which contains the location for file that contains the stop 
	# 	 words list.
	if($optionsHash{"stopList"}){
		$stopListFileLocation = $optionsHash{"stopList"};
	}
	
	
	# 6. Setting the option whether to delete or keep the temporary files.
	if($optionsHash{"isClean"}){
		$isClean = $optionsHash{"isClean"};
	}
	
	# 7. Setting the detailed debug option using the user input.
	if($optionsHash{"verbose"}){
		$isDecisionMatrixDebugOn = $optionsHash{"verbose"};
	}
	
	# 8. Setting the option whether to display help or not using the user input.
	if($optionsHash{"help"}){
		$help = $optionsHash{"help"};
	}
	
	# Checking if the Label file's name is provided by user.
	if(!defined $senseClusterLabelFileName){
		# Close the file handle.
		close ($outFileHandle);
		
		# If no argument is passed then return from here. This is the place
		# where we can ask user to print help.
		print "Type 'LabelEvaluation help' for usage.";
	
		# Return the error code which indicates insufficient argument.	
		return 2;
	}
	
	# Checking if the Label file's name is provided by user.
	if(!defined $topicsFileName){
		# Close the file handle.
		close ($outFileHandle);
		
		# If no argument is passed then return from here. This is the place
		# where we can ask user to print help.
		print "Type 'LabelEvaluation help' for usage.";
		
		# Return the error code which indicates insufficient argument.		
		return 2;
	}
	

=pod

=head1 Help
--------------------

The LabelEvaluation module expect the 'OptionsHash' as the required argument. 
The 'optionHash' has the following elements:
	
1. labelFile: 
	Name of the file containing the labels from sense cluster. The syntax of file 
	must be similar to label file from SenseClusters. This is the mandatory option.
	
2. labelKeyFile:      
	Name of the file containing the comma separated actual topics (keys) for the 
	clusters. This is the mandatory option.
	
3. labelKeyLength: 
	This parameters tell about the length of data to be fetched from Wikipedia 
	which will be used as reference data. Default is the first section of the 
	Wikipedia page.
	
4. weightRatio:       
	This ratio tells us about how much the weight we should provide to Discriminating 
	label to that of the descriptive label. Default value is set to 10.
	
5. stopList:             
	This is the name of file which contains the list of all stop words. This is the 
	optional parameter.
		
6. isClean:              
	This option tells us whether to keep temporary files or not. Default value is 
	true
	
7. verbose:             
	This option will let you see details output. Default value is false.
	
8. help :                 
	This option will show the details about running this module. This is the 
	optional parameter.
	
	%inputOptions = (
	
		labelFile => '<filelocation>/<SenseClusterLabelFileName>', 
		labelKeyFile => '<filelocation>/<ActualTopicName>',
		labelKeyLength=> '<LenghtOfDataFetchedFromWikipedia>',
		weightRatio=> '<WeightageRatioOfDiscriminatingToDiscriptiveLabel>',
		stopList=> '<filelocation>/<StopListFileLocation>',
		isClean=> 1,
		verbose=> 1,
		help=> 'help'
	);
	
=cut	
	
if($help){
print "\nPlease pass the options-hash in following format:
%inputOptions = (

		labelFile => '<filelocation>/<SenseClusterLabelFileName>', 
		labelKeyFile => '<filelocation>/<ActualTopicName>',
		labelKeyLength=> '<LenghtOfDataFetchedFromWikipedia>',
		weightRatio=> '<WeightageRatioOfDiscriminatingToDiscriptiveLabel>',
		stopList=> '<filelocation>/<StopListFileLocation>',
		isClean=> 1,
		verbose=> 1,
		help=> 'help'
);	

Note that only 'labelFile' and 'labelKeyFile' are mandatory options.  
For example, please refer the  SYNOPSIS section of the LabelEvaluation Module.\n";

return 3;		
}
	
	
	# Calling the function "readLinesFromClusterFile" 
	our $labelSenseClustersHashRef_Global = 
		Text::SenseClusters::LabelEvaluation::ReadingFilesData::readLinesFromClusterFile(
			$senseClusterLabelFileName,\%labelSenseClustersHash_Global);

	# Getting the Hash from its reference.	
	%labelSenseClustersHash_Global = %$labelSenseClustersHashRef_Global;

	# Calling readLinesFromTopicFile function to get the list of all the topics.
	our $standardTermsGlobal =
		Text::SenseClusters::LabelEvaluation::ReadingFilesData::readLinesFromTopicFile($topicsFileName);

	# Calling makeDecisionOfSense() function to get the final decision. 
	my $score = makeDecisionOfSense(\%labelSenseClustersHash_Global,
	$standardReferenceName_Global, $standardTermsGlobal, $stopListFileLocation);

	#print $outFileHandle "\nScore:: $score";

	# Returning the overall score given by this module for labels.
	return "$score";
}



#########################################################################################################
=head1 function: makeDecisionOfSense

This function will do the evaluation of labels. 
	 
@argument1		: LabelSenseClusters	DataType(Reference to HashOfHash)

@argument2		: StandardReferenceName: DataType(String)
					Name of the external application. 
					Currently, its two possible values are:
						1. Wikipedia 
						2. WordNet
						
@argument3		: StandardTerms: DataType(String)
					Terms(comma separated) to be sent to Wikipedia or Wordnet for 
					getting the Gold Standard Labels.
					
@return 		: Score : DataType(Float)
	  		  		Indicates the measure of overlap of current label mechanisms 
			  		with the Gold Standard Labels.

	
@description	:
	1). It will go through the Hash which contains the clusters and label terms.
	2). Each cluster's label terms will be written to a file whose name will be 
		same as of cluster name(or number).
	3). Then, this will go through the Standard terms against which we have to 
		compare the cluster labels.
	4). We will then create the files with name of the terms and content of the 
		file will be data fetched from the Wikipedia against a topic.
	5). Then, cluster's data and topic's data are compared using the method
		from Text::Similarity::Overlaps. 
	6). Finally the calculated scores are used further for decision matrix and
		getting the final score value.

=cut
#######################################################################################################
sub makeDecisionOfSense{
	
	# Reference of Hash containing the clusters and their corresponding labels. 
	my $labelSenseClustersHashRef = shift;

	# Getting the Hash from its reference.
	my %labelSenseClustersHash = %$labelSenseClustersHashRef;
	
	# Getting the Name of the external application to lookup from the Argument. 
	my $standardReferenceName = shift;
	
	# Terms to be sent to the external application for getting the Gold  
	# Standard Labels. 
	my $standardTerms = shift; 
	
	# Getting the Stop List file location from the argument.
	my $stopListFileLocation = shift;

	# Array to hold the file names for all the clusters.
	my @fileNameForClustersArray = ();
	
	# Array for holding the name of all the clusters.
	my @clusterNameArray = ();	

	# Hash which will hold the score of Topic against a Cluster and its scoring value. 
	my %hashForClusterTopicScore = ();

	# Iterating through the Hash which contains the clusters name and its labels
	# as assigned by sense cluster.
	foreach my $sortedOuterKey (sort keys %labelSenseClustersHash){
		
		# Open the file handle with Write mode.
		open (CLUSTERFILE, ">temp_$sortedOuterKey.txt");
		
		# Storing the name of the file (for a cluster data) in the array,
		push(@fileNameForClustersArray, "temp_$sortedOuterKey.txt");
		
		# Storing the cluster name in the clusterNameArray.
		push(@clusterNameArray, $sortedOuterKey);
		
		# Iterating through the type-of-Labels to fetch the value Of the Hash.
		foreach my $sortedInnerKey (sort keys %{$labelSenseClustersHash{$sortedOuterKey}}){

				# Writing the label terms in the 		 
	        	print CLUSTERFILE "\n$labelSenseClustersHash{$sortedOuterKey}{$sortedInnerKey}";        
	    } 
		# Close the file handle.
		close (CLUSTERFILE);   
	}


	# Spliting the standard terms on "," to get the Topic name.
	# 		For e.g: 	"Bill Clinton  ,   Tony  Blair" 
	my @standardTermsArray = split(/[\,]/, $standardTerms);
	
	# Defining the array for holding the name of the files.
	my @standardTermsFileArray = ();
	
	# 1. Going through the terms against which we have to compare the cluster labels.
	# 2. We will create the files with name of the terms.
	# 3. Content of the files will be data fetched from the Wikipedia against a topic.
	# 4. Finally, storing the name of the newly created files into Array for further  
	#    similarity comparison. 
	foreach my $sortedKey (@standardTermsArray){
		push(@standardTermsFileArray, 
		Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData::getWikiDataForTopic($sortedKey));
	}

	# Iterating through the ClusterFiles against TopicFiles to get the similarity value.
	foreach my $clusterFileName (@fileNameForClustersArray){
		foreach my $topicFileName (@standardTermsFileArray){
			
			# Calling the "computeOverlappingScores" to get the similarity score and 
			# store it into hash. 
			$hashForClusterTopicScore{$clusterFileName}{$topicFileName} 
					= Text::SenseClusters::LabelEvaluation::SimilarityScore::computeOverlappingScores(
						$clusterFileName,$topicFileName, $stopListFileLocation);
		}
	}

	# Defining the Reference for the hash, %topicTotalSumHash.
	my $topicTotalSumHashRef;
	
	# Defining the Reference for the hash, %clusterTotalSumHash.	
	my $clusterTotalSumHashRef;

	# Calling the function to print the decision matrix, based on the above similarity score.
	($topicTotalSumHashRef,$clusterTotalSumHashRef)= 
			printDecisionMatrix(\@clusterNameArray, \@standardTermsArray, \%hashForClusterTopicScore);

	# Getting the Hash from its references.
	my %topicTotalSumHash = %$topicTotalSumHashRef;
	my %clusterTotalSumHash = %$clusterTotalSumHashRef;


	# Calling the function to print the newly calculated decision matrix, based on the 
	# above decision matrix.
	my $score = 
		Text::SenseClusters::LabelEvaluation::ConfusionMatrixTotalCalc::printCalculatedScoreMatrix(
				$outFileHandle, \@clusterNameArray, \@standardTermsArray, 
				\%hashForClusterTopicScore,\%topicTotalSumHash ,\%clusterTotalSumHash,
				$isDecisionMatrixDebugOn);


	
	# Deleting all the temporary topic files at end of operation.	
	foreach my $topicFileName(@standardTermsFileArray){
		unlink $topicFileName or warn "Could not unlink $topicFileName: $!";								
	}

	# Deleting all the temporary clusters files at end of operation.	
	foreach my $clusterFileName(@fileNameForClustersArray){
		unlink $clusterFileName or warn "Could not unlink $clusterFileName: $!";								
	}


	return $score;
}



#########################################################################################################
=pod

=head1 function: printDecisionMatrix

This function is responsible for printing the decision matrix. 
 
@argument1	: clusterNameArrayRef:  	DataType(Reference_Of_Array)
				Reference to Array containing Cluster Name.
				
@argument2	: standardTermsArrayRef:  	DataType(Reference_Of_Array)  
				Reference to Array containing Standard terms.
				 
@argument3	: hashForClusterTopicScoreRef:  DataType(Reference_Of_Hash)
				Reference to hash containing Cluster Name, corresponding 
				StandardTopic and its score.
				

@return1 		: topicTotalSumHash:  	DataType(Reference_Of_Hash)
				Hash which will contains the total score for a topic 
				against each clusters.
				
@return2 		: clusterTotalSumHash:  DataType(Reference_Of_Hash) 
				Hash which will contains the total score for a cluster 
				against each topics.
	  		  	


@description	:
	1). It will go through the Hash which contains the similarity score for 
		each clusters against standard label terms.
	2). This uses the above hash to print the decision matrix. Below has the 
		example of the decision matrix.
	3). It will also use the ScoringHash to get new hashes which will store
			a) total score for a cluster against each topics.
			b) total score for a topic against each cluster.	


Example of decision Matrix

		==============================================================================
							|	Cluster0	|	Cluster1
		------------------------------------------------------------------------------
			Bill Clinton:	|		11		|		12 		|		23(ROW TOTAL)
		------------------------------------------------------------------------------
		------------------------------------------------------------------------------
			Tony Blair:	|		15		|		9 		|		24 (ROW TOTAL)
		------------------------------------------------------------------------------
			Total			|		26		|		21		|		47
					  		| (COL TOTAL)	| (COL TOTAL)	|   (Total Matrix Sum)


 Where, 1) Cluster0, Cluster1 are  Cluster Names.
		2) Bill Clinton, Tony Blair are  Standard Topics.
		3) 23, 24 are Row Total of the Topic score.			(ROW TOTAL)
 		4) 26, 21 are Col Total of the ClusterName Score.		(COL TOTAL)
		5) 47 is Total sum of the scores of all clusters again all topics.		
			(Total Matrix Sum)


=cut
#######################################################################################################

sub printDecisionMatrix{

	# Getting the ReferenceToArray which contains ClusterName from the argument.
	my $clusterNameArrayRef = shift;
	# Getting the array from the reference.
	my @clusterNameArray = @$clusterNameArrayRef;

	# Getting the ReferenceToArray which contains StandardTerms from the argument.
	my $standardTermsArrayRef =  shift;
	# Getting the array from the reference.
	my @standardTermsArray =  @$standardTermsArrayRef;

	# Getting the Reference to hash which contains Cluster Name, corresponding
	# StandardTopic and its score from the argument.
	my $hashForClusterTopicScoreRef = shift;
	# Getting the hash from the reference.
	my %hashForClusterTopicScore = %$hashForClusterTopicScoreRef;

	
	# Defining Hash which will contain the topics and their total score.	
	my %topicTotalSumHash =();

	# Defining Hash which will contain the cluster and their total score.
	my %clusterTotalSumHash =();

	# Variable will hold the total values of the decision matrix.
	my $totalDecisionMatrixSum = 0;

	# If user opted to print the decision matrix, then only print the below.
	if($isDecisionMatrixDebugOn == 1){
		# Printing the 
		# 1. Title and  
		# 2. Table Column headers for decision matrix table.
		
				
		print $outFileHandle "\nDECISION MATRIX(Count)::";
		print $outFileHandle "\n==============================================================".
			"=================================================================================\n\t\t";
		
		foreach my $clusterName (@clusterNameArray){
			print $outFileHandle "\t|\t $clusterName";
		}
	}	


	# Iterate through the list of all Standard Terms. 
	foreach my $topicName (@standardTermsArray){

		# Getting the topic name in temporary variable.
		my $topicNameLabel = $topicName;
		
		# Removing the extra white space with single.
		$topicNameLabel =~ s/\s+/ /g;

		# Removing the white space from the front and end of the word.
		$topicNameLabel =~ s/^\s+|\s+$//g;
		
		# If user opted to print the decision matrix, then only print the below.
		# 3. Table Row headers for decision matrix table.		
		if($isDecisionMatrixDebugOn ==1){
			print $outFileHandle "\n--------------------------------------------------------------".
				"----------------------------------------------------------------------------------";
			print $outFileHandle "\n\t$topicNameLabel:";
		}

		# Removing the white space with underscore.
		$topicNameLabel =~ s/\s+/_/g;
		
		# Creating the file name from the topic name.
		$topicName = "temp_$topicNameLabel.txt";

		# Variable which will hold the value of the Row Sum.
		my $rowSum = 0; 
		
		# Going through cluster-topic hash.
		foreach my $sortedOuterKey (sort keys %hashForClusterTopicScore){

				# If user opted to print the decision matrix, then only print the below.
				if($isDecisionMatrixDebugOn ==1){
					
					# Printing the similarity vlaue between cluster and topic.
					print $outFileHandle "\t|\t\t"
						."$hashForClusterTopicScore{$sortedOuterKey}{$topicName} ";
				}
				
				# Adding the value for each cluster against a topic.
				$rowSum += $hashForClusterTopicScore{$sortedOuterKey}{$topicName};
		}

		# Storing the total sum into the Sum Hash.
		$topicTotalSumHash{$topicName} = $rowSum;


		# If user opted to print the decision matrix, then only print the below.
		if($isDecisionMatrixDebugOn ==1){
			print $outFileHandle "\t|\t\t $rowSum";
			print $outFileHandle "\n--------------------------------------------------------"
			."----------------------------------------------------------------------------------------";
		}

	}

	# If user opted to print the decision matrix, then only print the below.
	if($isDecisionMatrixDebugOn ==1){
		print $outFileHandle "\n\tTotal\t";
	}	
		

	# The following piece of code will go through Similarity Values of clusters against topics.
	# Then, it will print the column sum for each column.
	foreach my $sortedOuterKey (sort keys %hashForClusterTopicScore){
		
		# Defining variable for total score of a column. 
		my $colSum =0;
		
		# Iterating through each hash against each Column (Cluster Name).  
		foreach my $sortedInnerKey (sort keys %{$hashForClusterTopicScore{$sortedOuterKey}}){

			# Totaling the value of Cluster's similarity score against each topic. 
			$colSum += $hashForClusterTopicScore{$sortedOuterKey}{$sortedInnerKey}
		}
		
		# If user opted to print the decision matrix, then only print the below.
		if($isDecisionMatrixDebugOn ==1){
			print $outFileHandle "\t|\t\t$colSum";
		}
		
		# Storing the total sum into the Sum Hash.
		$clusterTotalSumHash{$sortedOuterKey} = $colSum;

		#Totaling the score of all the clusters against all the topics.
		$totalDecisionMatrixSum += $colSum;
	}

	# If user opted to print the decision matrix, then only print the below.
	if($isDecisionMatrixDebugOn ==1){
		print $outFileHandle "\t|\t\t$totalDecisionMatrixSum";
		print $outFileHandle "\n============================================================="
			."==================================================================================\n";
	}


	# Returning Hash containing the total score against each topics and total 
	# score against each clusters. 
	return (\%topicTotalSumHash,\%clusterTotalSumHash);
}





#######################################################################################################
=pod

=head1 BUGS

=over

=item * Supports input of label and topic values through files. Should be able to accept as string value

=item * Currently not supporting the WordNet gold standards comparison. 

=back

=head1 SEE ALSO

http://senseclusters.cvs.sourceforge.net/viewvc/senseclusters/LabelEvaluation/ 
 
 
@Last modified by				: Anand Jha			
@Last_Modified_Date   		: 24th Dec. 2012
@Modified Version				: 1.15 


=head1 AUTHORS

 	Ted Pedersen, University of Minnesota, Duluth
 	tpederse at d.umn.edu

 	Anand Jha, University of Minnesota, Duluth
 	jhaxx030 at d.umn.edu



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 Ted Pedersen, Anand Jha 

See http://dev.perl.org/licenses/ for more information.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to: 
 
	
	The Free Software Foundation, Inc., 59 Temple Place, Suite 330, 
	Boston, MA  02111-1307  USA
	
	
=cut
#######################################################################################################

1;

__END__
