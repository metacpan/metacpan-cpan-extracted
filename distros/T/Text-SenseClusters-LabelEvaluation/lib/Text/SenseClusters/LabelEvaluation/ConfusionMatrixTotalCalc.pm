#!/usr/bin/perl -w

# Declaring the Package for the module.
package Text::SenseClusters::LabelEvaluation::ConfusionMatrixTotalCalc;

use strict; 
use encoding "utf-8";

# The following two lines will make this module inherit from the Exporter Class.
require Exporter;
our @ISA = qw(Exporter);



#######################################################################################################################

=head1 Name 

Text::SenseClusters::LabelEvaluation::ConfusionMatrixTotalCalc - Module responsible for processing of decision matrix. 

=head1 DESCRIPTION 
	
This module provide two functions. First function will calculate the probability
decision matrix from the scores of the original decision matrix. The second 
function will then use the new decision matrix to decide whether labels are 
appropriately assigned or not.
 
=cut


##########################################################################################
=pod

=head1 function: printCalculatedScoreMatrix

	The following function is responsible for printing the calculated score 
	matrix from the decision matrix.

	@argument1	:  outputFileHandle:  	DataType(File Handler)
					This the file handler used for defining where to print
					the output message/statements of this module.
					Its default value is: STDERR.
					 
	@argument2	: clusterNameArrayRef:  	DataType(Reference_Of_Array)
					Reference to Array containing Cluster Name.
					
	@argument3	: standardTermsArrayRef:  	DataType(Reference_Of_Array)  
					Reference to Array containing Standard terms.
					 
	@argument4	: hashForClusterTopicScoreRef:  DataType(Reference_Of_Hash)
					Reference to hash containing Cluster Name, corresponding 
					StandardTopic and its score.
					
	@argument5	: topicTotalSumHashRef:  DataType(Reference_Of_Hash)
					Hash which will contains the total score for a topic 
					against each clusters.
					
	@argument6	: clusterTotalSumHashRef:  DataType(Reference_Of_Hash)
					Hash which will contains the total score for a cluster 
					against each topics.

	@argument7	: $isDecisionMatrixDebugOn:  DataType(number 0 or 1)
				  Verbose:: This decide whether to detail output or not.   	


	@return		: SimilarityScore
				  This indicate the similarity score of labels and actual
				  topics which are correctly identified by SenseClusters 
				  or similar application.		

	@description	:

	This module is responsible of decision matrix which is identified as:				

	Calculated Decision MATRIX:
	
		=========================================================
							|	Cluster0		|		Cluster1		|
		---------------------------------------------------------
			Bill Clinton:	|		0.478		|		0.522			|
		---------------------------------------------------------
		---------------------------------------------------------
			Tony Blair:	|		0.625		|		0.375			|
		---------------------------------------------------------
		=========================================================


	 Where, 1) Cluster0, Cluster1 are  Cluster Names, (Column Header).
			 2) Bill Clinton, Tony Blair are  Standard Topics, (Row Header).
			 3) Cell content is the probability measure which indicates 
			    likelihood of a cluster's label against a Topic.
			    
	
	 Steps:
	 		1. First, it will iterate through hash, '%hashForClusterTopicScore'.
	 		2. It will divide the cluster-topic overlapping score with the total 
	 		   count value of the decision matrix. 
	 		3. This will give the normalized score.
	 		4. Based on user input on Verbose, it will display the normalized 
	 		   decision matrix.
	 		5. It will then call the function 'concludingFromDecisionMatrix' 
	 		   which will used the normalized decision matrix to conclude 
	 		   		a) which cluster's labels is matching with which Gold-Standard
	 		   		   -topic's data.
	 		   		a) which Gold-Standard-topic's data label is matching with 
	 		   		   which cluster's labels.
	 		6. Finally, it will compare the Clusterwise results with Topicwise 
	 		   results to conclude final cluster-topic match results along with
	 		   their matching score.  		    

=cut
##########################################################################################

sub printCalculatedScoreMatrix{

	# Getting the File Handle from the function argument.
	my $outputFileHandle = shift;
	
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

	# Getting the Reference to hash which contains the topics and their total 
	# score from the argument.
	my $topicTotalSumHashRef = shift;
	# Getting the hash from its reference.	
	my %topicTotalSumHash = %$topicTotalSumHashRef;

	# Getting the Reference to hash which contains the clusters and their total 
	# score from the argument.
	my $clusterTotalSumHashRef = shift;
	# Getting the hash from its reference.	
	my %clusterTotalSumHash = %$clusterTotalSumHashRef;
	# Variable which will decide whether to display verbose or not.
	my $isDecisionMatrixDebugOn = shift;
	
	# This value is going to store the total value for the decision matrix.
	my $totalValueOfDecisionScore = 0;
	
	# Getting the total for the decision matrix table.
	foreach my $clusterName (keys %clusterTotalSumHash){
		$totalValueOfDecisionScore += $clusterTotalSumHash{$clusterName}; 
	}
	
	# Printing only if the debug option is on.
	if($isDecisionMatrixDebugOn == 1){

		# If user opted to print the calculated decision matrix, then only print the below.
		print $outputFileHandle "\n\n\n\nDecision MATRIX (Probability)::";
		print $outputFileHandle "\n===========================================================".
			"=================================================================\n\t\t";
	
		# If user opted to print the calculated decision matrix, then only print the below.
		# This will print the cluster name in the decision matrix.
		foreach my $clusterName (@clusterNameArray){
			print $outputFileHandle "\t|\t$clusterName   ";
		}
	}

	# HashOfHash to store conclusion of Direct calculation, rowwise i.e 
	# a topic (OuterKey) score against each cluster(InnerKey).
	my %directTopicClusterHash = ();
	
	# HashOfHash to store conclusion of Direct calculation, columnwise i.e 
	# a Cluster (OuterKey) scores against each topics(InnerKey).
	my %directClusterTopicHash = ();

	
	# Looping through each of the topic from the topics list.
	foreach my $topicName (@standardTermsArray){
		
		# The variable to store the maximum score in a row.
		my $rowMaxScore = 0;
		
		# The variable to store the maximum score in a column.
		my $colMaxScore = 0;
		
		# The variable to store the cluster name which will have maximum score 
		# in direct approach.
		my $clusterNameDirect = "";
		
		
		# Storing the topics in temporary variable for some preprocessing. 
		my $topicNameLabel = $topicName;
		
		# Removing the extra white space with single space.
		$topicNameLabel =~ s/\s+/ /g;

		# Removing the white space from the front and end of the sentence
		# (in this case single word).
		$topicNameLabel =~ s/^\s+|\s+$//g;


		# Printing only if the debug option is on.
		if($isDecisionMatrixDebugOn == 1){
			# If user opted to print the calculated decision matrix, then only 
			# print the below.
			print $outputFileHandle "\n----------------------------------------------------------".
				"---------------------------------------------------------------";
			print $outputFileHandle "\n\t$topicNameLabel:   ";
		}	


		# Removing the white space with underscore.
		$topicNameLabel =~ s/\s+/_/g;
		
		# Then, creating the filename from the topic name. We are doing this 
		# because score about a cluster and the topic is stored in a hashOfHash 
		# using the filename format of topic. 
		$topicNameLabel = "temp_$topicNameLabel.txt";

		# Iterating through hash which store the score of a cluster against all the topics.
		foreach my $sortedOuterKey (sort keys %hashForClusterTopicScore){
		
			# Variable used for storing the direct tempoarary probability value i.e. the
			# denominator for probability calculation will be sum of similarity score of
			# a row.
			my $tempRowScore =0;
			
			# If the total sum against a topic is zero, then the make the tempRowScore zero. 
			if($topicTotalSumHash{$topicNameLabel} == 0){
				$tempRowScore =0;
			}else{
				
				# Calculating the probability of occurrence of "a cluster having a topic".
				# This is calculated by dividing the similarity score of a cluster against
				# a topic with total similarity score of all the clusters against that topic. 
				$tempRowScore = $hashForClusterTopicScore{$sortedOuterKey}{$topicNameLabel} 
						/$totalValueOfDecisionScore;
			}
			
			# Formating the probability value to round off to 3 decimal place.
			$tempRowScore = sprintf("%.3f", $tempRowScore);

			# Printing only if the debug option is on.
			if($isDecisionMatrixDebugOn == 1){
				# If user opted to print the calculated decision matrix, then only print the below.
				print $outputFileHandle "\t|\t$tempRowScore";
			}	

		
			# For Direct Approach: The following code will get the maximum score in a row 
			# and its corresponding Cluster name, which will be then be stored against the 
			# given topic.
			if($rowMaxScore < $tempRowScore){
				$rowMaxScore = $tempRowScore;	
				$clusterNameDirect = $sortedOuterKey;
				
				# Remvoing unwanted characters related to the file name, which was used
				# while storing in the hash.
				$clusterNameDirect =~ s/temp_//;
				$clusterNameDirect =~ s/.txt//;
			}
		}

		# Storing the maximum direct score and its corresponding cluster name for the 
		# given topic. 
		$directTopicClusterHash{$topicNameLabel} = "$clusterNameDirect \t,\t $rowMaxScore";

		# Printing only if the debug option is on.
		if($isDecisionMatrixDebugOn == 1){
				
			# If user opted to print the calculated decision matrix, then only print the below.
			print $outputFileHandle "\n-------------------------------------------------------".
				"-------------------------------------------------------------------";
		}	
	}


	# Calling the function 'concludingFromDecisionMatrix' which will used the normalized
	# decision matrix to conclude which cluster label is matching with which Gold-Standard
	# -topic's data.
	my ($directClusterTopicHashRef,$directTopicClusterHashRef)
				= concludingFromDecisionMatrix( $outputFileHandle,
					\%hashForClusterTopicScore, \%topicTotalSumHash ,
					\%clusterTotalSumHash, \%directClusterTopicHash,
					\%directTopicClusterHash, $totalValueOfDecisionScore,
					$isDecisionMatrixDebugOn);	
	
	# Getting the hashes from the references.
	%directClusterTopicHash  = %$directClusterTopicHashRef;
	%directTopicClusterHash  = %$directTopicClusterHashRef;
				

	# The following code is responsible for printing the final result
	# of direct method approach.
	#
	# In this approach we will compare the results of Cluster-Topic conclusion
	# and Topic-Cluster conclusion. If both are matching then we will consider
	# as the clear winner.
	print $outputFileHandle "\n\n\n\n Matched:: \t";	
	
	# This variable will hold the total number of successful match from wikipedia.
	my $totalTopicsMatched = 0;
	
	# Getting the size of the Hash.
	my $totalTopicCount = keys(%directClusterTopicHash);
		
	# This variable will hold the overall score for the match of labels.
	my $matchedScore = 1;
	
	# Going through the hash which contains the hash that contains the cluster-topic
	# overlapping score.
	foreach my $clusterKey (sort keys %directClusterTopicHash){
		my $topicValue = $directClusterTopicHash{$clusterKey};
		my @topicArray = split(/[\,]/, $topicValue);
		
		# Remvoing unwanted characters related to the file name, which was used
		# while storing in the hash.
		$topicArray[0]=~s/\s+//g;
		$topicArray[0] =~ s/temp_//;
		$topicArray[0] =~ s/.txt//;

		# Remvoing unwanted characters related to the file name, which was used
		# while storing in the hash.
		$clusterKey =~ s/temp_//;
		$clusterKey =~ s/.txt//;

		# Iterating through the hash to get the topic, cluster-name and score from topic-cluster hash.
		foreach my $topicKey (sort keys %directTopicClusterHash){
			my $clusterValue = $directTopicClusterHash{$topicKey};
			my @clusterArray = split(/[\,]/, $clusterValue);

			# Remvoing unwanted characters related to the file name, which was used
			# while storing in the hash.
			$clusterArray[0]=~s/\s+//g;
			$topicKey =~ s/temp_//;
			$topicKey =~ s/.txt//;

			$clusterArray[1]=~s/\s+//g;
			#print "\n temp score::".$clusterArray[1];
			
			if($clusterKey eq $clusterArray[0] && $topicKey eq $topicArray[0]){
				print $outputFileHandle "\n \t$clusterKey \t:\t$topicKey"; 
				$totalTopicsMatched++;
				$matchedScore *= $clusterArray[1];
			}
		}
	}

	print $outputFileHandle "\n\n\nSuccessful labels verified $totalTopicsMatched  out of  $totalTopicCount";
	print $outputFileHandle "\nScore = $matchedScore";
	 
	# Close the file handle.
	close ($outputFileHandle);
	
	# Returning the score for the labels.
	return $matchedScore;
}



#########################################################################################################
=pod

=head1 function: concludingFromDecisionMatrix

	The following matrix is responsible for printing the calculated score 
	matrix from the decision matrix.

	@argument1	: hashForClusterTopicScoreRef:  DataType(Reference_Of_Hash)
					Reference to hash containing Cluster Name, corresponding 
					StandardTopic and its score.
	@argument2	: topicTotalSumHashRef:  DataType(Reference_Of_Hash)
					Hash which will contains the total score for a topic 
					against each clusters.
	@argument3	: clusterTotalSumHashRef:  DataType(Reference_Of_Hash)
					Hash which will contains the total score for a cluster 
					against each topics.
	@argument4	: directClusterTopicHashRef:  DataType(Reference_Of_Hash)
					HashOfHash to store conclusion of Direct calculation, 
					row-wise i.e a topic (OuterKey) score against each 
					cluster(InnerKey).
	@argument5	: directTopicClusterHashRef:  DataType(Reference_Of_Hash)
					HashOfHash to store conclusion of Direct calculation, 
					columnwise i.e a Cluster (OuterKey) scores against 
					each topics(InnerKey).

	
	 @return1	: directClusterTopicHashRef:  DataType(Reference_Of_Hash)
					HashOfHash which store conclusion of calculation, 
					row-wise i.e a topic (OuterKey) score against each 
					cluster(InnerKey).
	 @return2	: directTopicClusterHashRef:  DataType(Reference_Of_Hash)
					HashOfHash to store conclusion of calculation, 
					columnwise i.e a Cluster (OuterKey) scores against 
					each topics(InnerKey).

	@description :
	
				 	The following block of code is responsible for 
				 	1. Calculating the probabilities (normalized value) of all the   
						topic against a cluster. 
					2. Chosing a topic which has the maximum probability (normali
						-zed value) value for the given cluster.
					3. In current approach, for calculating the probability (norm
	 	 				-alized value) we will divide the similarity score of a  
		 				topic against a cluster with total similarity score of all 
						the topics against all the cluster.
	
	 
					 Future enhancement::
					 4. The above approach can be done in two way i.e. using the  
					 	direct way as well as inverse way.
					 5. In direct approach, for calculating the probability we 
	    				 will divide	the similarity score of a topic against a 
	    				 cluster with total similarity score of all the topics 
	    				 against that cluster.
	    			 6. In inverse approach, for calculating the probability we 
	    			 	 will divide the similarity score of a topic against a 
	    			 	 cluster with total similarity score of all the clusters 
	    			 	 against that topic.

=cut
#########################################################################################################

sub concludingFromDecisionMatrix{
	
	# Getting the File Handle from the function argument.
	my $outputFileHandle = shift;
	
	# Getting the Reference to hash which contains Cluster Name, corresponding
	# StandardTopic and its score from the argument.
	my $hashForClusterTopicScoreRef = shift;
	# Getting the hash from the reference.
	my %hashForClusterTopicScore = %$hashForClusterTopicScoreRef;
	
	# Getting the Reference to hash which contains the topics and their total 
	# score from the argument.
	my $topicTotalSumHashRef = shift;
	# Getting the hash from its reference.	
	my %topicTotalSumHash = %$topicTotalSumHashRef;

	# Getting the Reference to hash which contains the clusters and their total 
	# score from the argument.
	my $clusterTotalSumHashRef = shift;
	# Getting the hash from its reference.	
	my %clusterTotalSumHash = %$clusterTotalSumHashRef;
	
	# HashOfHash to store conclusion of Direct calculation, columnwise i.e 
	# a Cluster (OuterKey) scores against each topics(InnerKey).
	my $directClusterTopicHashRef = shift;
	my %directClusterTopicHash = %$directClusterTopicHashRef;

	# HashOfHash to store conclusion of Direct calculation, rowwise i.e 
	# a topic (OuterKey) score against each cluster(InnerKey).
	my $directTopicClusterHashRef = shift;
	my %directTopicClusterHash = %$directTopicClusterHashRef;
	
	# This value is going to store the total value for the decision matrix.
	my $totalValueOfDecisionScore = shift;
	
	# Variable which will decide whether to dispaly details results or not.
	my $isDecisionMatrixDebugOn = shift;
	
	
	# The following block of code is responsible for 
	# 1. Calculating the probabilities (normalized value) of all the topic  
	#    against a cluster. 
	# 2. Chosing a topic which has the maximum probability (normalized value) 
	#	 value for the given cluster.
	# 3. In current approach, for calculating the probability (normalized value)
	# 	 we will divide the similarity score of a topic against a cluster with 
	#	 total similarity score of all the topics against all the cluster.
	#
	# 
	#  Future enhancement::
	#
	# 3. The above approach is done in two way i.e. using the direct way 
	#	 as well as inverse way.
	# 4. In direct approach, for calculating the probability we will divide
	#    the similarity score of a topic against a cluster with total  
	#	 similarity score of all the topics against that cluster.
	# 5. In inverse approach, for calculating the probability we will divide
	#    the similarity score of a topic against a cluster with total  
	#	 similarity score of all the clusters against that topic.

	# Iterating through hash which store the score of a cluster against all the topics. 
	foreach my $sortedOuterKey (sort keys %hashForClusterTopicScore){
		
		# The variable to store the maximum score in a column.
		my $colBasedMaxScore = 0;
		
		# The variable to store the topic name which will have maximum score 
		# in direct approach.
		my $topicNameDirect = "";
		

		# Iterating through hash which store the score of a cluster against all the topics.
		# Iterating through low level key, this will give name of the topics.
		foreach my $sortedInnerKey (sort keys %{$hashForClusterTopicScore{$sortedOuterKey}}){	

			# Direct Approach::
			my $tempRowScore =0;
			if($topicTotalSumHash{$sortedInnerKey} == 0){
				$tempRowScore =0;
			}else{
				
				 # Direct approach of Calculating the probability:
				 # We are diving the similarity score of a topic against a cluster with 
				 # total similarity score of all the topics against that cluster.
				$tempRowScore = $hashForClusterTopicScore{$sortedOuterKey}{$sortedInnerKey} 
						/ $totalValueOfDecisionScore;
			}
			# Formating the probability value to round off to 3 decimal place.
			$tempRowScore = sprintf("%.3f", $tempRowScore);

			# Inverse Approach::
			my $tempColScore =0;
			if($clusterTotalSumHash{$sortedOuterKey} == 0){
				$tempColScore =0;
			}else{
				#	Inverse approach of Calculating the probability:
				#   We are diving the similarity score of a topic against a cluster with 
				#   total similarity score of all the clusters against that topic.
				$tempColScore = $hashForClusterTopicScore{$sortedOuterKey}{$sortedInnerKey} 
						/ $totalValueOfDecisionScore;
			}
			# Formating the probability value to round off to 3 decimal place.
			$tempColScore = sprintf("%.3f", $tempColScore);

			if($colBasedMaxScore < $tempColScore){
				$colBasedMaxScore = $tempColScore;	
				$topicNameDirect = $sortedInnerKey;
				
				# Remvoing unwanted characters related to the file name, which was used
				# while storing in the hash.
				$topicNameDirect =~ s/temp_//;
				$topicNameDirect =~ s/.txt//;
			}
		}

		# Storing the maximum direct score and its corresponding topic name for the 
		# given cluster. 
		$directClusterTopicHash{$sortedOuterKey} = 
			"temp_$topicNameDirect.txt \t,\t $colBasedMaxScore";
	}
	
	# Print this only if the detailed debug output is on.	
	if($isDecisionMatrixDebugOn ==1){
			# If user opted to print the calculated decision matrix, then only print the below.
			# Following block of code is responsible for printing all the decision 
			# we made using the decision matrix, based on direct and inverse approach.
			print $outputFileHandle "\n=====================================================".
				"======================================================================\n";
			print $outputFileHandle "\n Column-wise Conclusion::\t";
			Text::SenseClusters::Wikipedia::PrintingHashData::prinHashOfScore(
				\%directClusterTopicHash, $outputFileHandle);	
		
			print $outputFileHandle "\n\n\n Row-wise Conclusion::\t";
			Text::SenseClusters::Wikipedia::PrintingHashData::prinHashOfScore(
				\%directTopicClusterHash, $outputFileHandle);	
	}
		
	# Returning all the populated hashes.
	return(\%directClusterTopicHash,\%directTopicClusterHash);	
}




#######################################################################################################
=pod


=head1 SEE ALSO

http://senseclusters.cvs.sourceforge.net/viewvc/senseclusters/LabelEvaluation/ 
 
 
@Last modified by				: Anand Jha			
@Last_Modified_Date   		: 24th Dec. 2012
@Modified Version				: 1.6 

	
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
# Making the default return statement as 1;
# Reference : http://lists.netisland.net/archives/phlpm/phlpm-2001/msg00426.html
1;
