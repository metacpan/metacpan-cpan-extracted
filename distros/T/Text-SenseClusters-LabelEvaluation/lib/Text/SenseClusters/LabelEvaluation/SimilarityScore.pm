#!/usr/bin/perl -w

# Declaring the Package for the module.
package Text::SenseClusters::LabelEvaluation::SimilarityScore;

use strict; 
use encoding "utf-8";

# The following two lines will make this module inherit from the Exporter Class.
require Exporter;
our @ISA = qw(Exporter);

# Using WWW::Wikipedia Module.
# Reference: http://search.cpan.org/dist/WWW-Wikipedia/lib/WWW/Wikipedia.pm
use WWW::Wikipedia;

# Defining the Variable for using the Wikipedia Module.
# Reference: http://search.cpan.org/~bricas/WWW-Wikipedia-2.00/
my $wiki = WWW::Wikipedia->new();

# Using Text Similarity Module.
# Reference: http://search.cpan.org/~tpederse
#					/Text-Similarity-0.08/lib/Text/Similarity.pm
use Text::Similarity::Overlaps;


#######################################################################################################################

=head1 Name 

Text::SenseClusters::LabelEvaluation::SimilarityScore - Module for getting the similarity score between the contents of the two files. 

=head1 SYNOPSIS

		# The following code snippet will show how to use SimilarityScore.
		package Text::SenseClusters::LabelEvaluation::Test_SimilarityScore;

		# Including the LabelEvaluation Module.
		use Text::SenseClusters::LabelEvaluation::SimilarityScore;

		# Including the FileHandle module.
		use FileHandle;

		# File that will contain the label information.
		my $labelFileName = "temp_ClusterLabel.txt";

		# Defining the file handle for the label file.
		our $labelFileHandle = FileHandle->new(">$labelFileName");

		# Writing into the label file.
		print $labelFileHandle "U S, Al Gore, White House, more than, President 1993, George W,". 
		   			"York Times, New York, Prime Minister, New Democrat, National Governors";
		   						
		# File that will contain the topic information.
		my $topicFileName = "temp_TopicData.txt";

		# Defining the file handle for the topic file.
		our $topicFileHandle = FileHandle->new(">$topicFileName");

		# Writing into the Topic file.
		# Bill Clinton  ,   Tony  Blair 
		print $topicFileHandle "Bill Clinton is an American politician who served as the 42nd President of". 
		"the United States from 1993 to 2001. Inaugurated at age 46, he was the third-youngest president.". 
		"He took office at the end of the Cold War, and was the first president of the baby boomer generation.". 
		"Clinton has been described as a New Democrat. Many of his policies have been attributed to a centrist". 
		"Third Way philosophy of governance. He is married to Hillary Rodham Clinton, who has served as the". 
		"United States Secretary of State since 2009 and was a Senator from New York from 2001 to 2009.". 
		"As Governor of Arkansas, Clinton overhauled the state's education system, and served as Chair ".
		"of the National Governors Association.Clinton was elected president in 1992, defeating incumbent". 
		"president George H. W. Bush. The Congressional Budget Office reported a budget surplus between ".
		"the years 1998 and 2000, the last three years of Clinton's presidency. Since leaving office,".
		"Clinton has been rated highly in public opinion polls of U.S. presidents. \n";

		# Closing the handles.
		close($labelFileHandle);								
		close($topicFileHandle);		

		my $stopListFileLocation ="";

		my $similarityScore = Text::SenseClusters::LabelEvaluation::SimilarityScore::computeOverlappingScores(
								$labelFileName,$topicFileName, $stopListFileLocation);

		print "\n Similarity Score for the Cluster-labels and Bill-Clinton-Wiki data is $similarityScore \n";

		# Deleting the temporary label and topic files.
		unlink $labelFileName or warn "Could not unlink $labelFileName: $!";								
		unlink $topicFileName or warn "Could not unlink $topicFileName: $!";

=head1 DESCRIPTION

This module provide a function that will compare the two files and return 
the overlapping score. 
			
=cut





########################################################################################
=head1 Function: computeOverlappingScores
------------------------------------------------


Function that will compare the labels file with the wiki files and  
will return the overlapping score. 

@argument1		: Name of the cluster file.
@argument2		: Name of the file containing the data from Wikipedia.
@argument3		: Name of the file containing the stop word lists.
 
@return 		: Return the overlapping score between these files.
		  
@description	:
		1). Reading the file name from the command line argument.
		2). Invoking the Text::Similarity::Overlaps module and passing
			the file names for similarity comparison.
 		3). Then overlapping score obtained from this module is returned 
			as the similarity value.

=cut

#########################################################################################

sub computeOverlappingScores{
	 
	# Getting the ClusterFileName from the argument.
	my $clusterFileName = shift;
	
	# Getting the TopicFileName from the argument.
	my $topicFileName = shift;

	# Getting the stop list file location.
	my $stopListFileLocation = shift;
	
	if(!defined $stopListFileLocation){
			 # Getting the module name.
			my $module = "Text/SenseClusters/Wikipedia/SimilarityScore.pm";
			   
			# Finding its installed location.
			my $moduleInstalledLocation = $INC{$module};
		
			# Getting the prefix of installed location. This will be one of 
			# the values in array @INC.
			$moduleInstalledLocation =~ 
				m/(.*)Text\/SenseClusters\/Wikipedia\/SimilarityScore\.pm$/g;
			
			# Getting the installed stopList.txt location using above location. 
			# For e.g.:
			#	/usr/local/share/perl/5.10.1/Text/SenseClusters
			#			/Wikipedia/stoplist.txt
			$stopListFileLocation 
					= $1."/Text/SenseClusters/Wikipedia/stoplist.txt";
			

	}
	# Setting the Options for getting the results from the Text::Similarity
	# Module.
	my %options = ('verbose' => 0, 'stoplist' => $stopListFileLocation);

	# Creating the new Overlaps Object.
	my $mod = Text::Similarity::Overlaps->new (\%options);
	
	# If the object is not created, then quit the program with error message. 
	defined $mod or die "Construction of Text::Similarity::Overlaps failed";

	# Getting the overlapping score from the Similarity function.
	my $score = $mod->getSimilarity ($clusterFileName, $topicFileName);

	# Printing the Similarity Score for the files.
	# print "The similarity of $clusterFile and $topicFile is : $score\n";
	
	# Returning the overlapping Score.
	return $score;
}


#######################################################################################################
=pod


=head1 SEE ALSO

http://senseclusters.cvs.sourceforge.net/viewvc/senseclusters/LabelEvaluation/ 
 
 
@Last modified by				: Anand Jha			
@Last_Modified_Date   		: 24th Dec. 2012
@Modified Version				: 1.4 
	
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
