#!/usr/bin/perl -w

# Declaring the Package for the module.
package Text::SenseClusters::LabelEvaluation::PrintingHashData;

use strict; 
use encoding "utf-8";

# The following two lines will make this module inherit from the Exporter Class.
require Exporter;
our @ISA = qw(Exporter);



#######################################################################################################################

=head1 Name 

Text::SenseClusters::LabelEvaluation::PrintingHashData - Module for printing information stored in a Hash-Variable. 

=head1 SYNOPSIS

		The following code snippet will show how to use this module:

		# Including the LabelEvaluation Module.
		use Text::SenseClusters::LabelEvaluation::PrintingHashData;

		my %labelClusterHash = (
		'cluster0' =>  {
				           'Descriptive' 	=> 'George Bush, Al Gore, White House, Cox News, BRITAIN London, Prime Minister, New York',
				           'Discriminating' => 'George Bush, Cox News, BRITAIN London'
				       },
		'cluster1' =>  {
				           'Descriptive'    => 'Al Gore, White House, more than, George W, York Times, New York, Prime Minister',
				           'Discriminating'  => 'more than, York Times, George W'
				       }
		);

		Text::SenseClusters::LabelEvaluation::PrintingHashData::prinHashOfHash(\%labelClusterHash);	
		print "\n";


=head1 DESCRIPTION 
	
This module provide two functions. First function will print the content 
of Hash-of-hash that is passed to it as argument. The	second function will be 
used by confusion-matrix-module, to print the data in the matrix format. The 
function will present data in more readable format to users.

=cut



##########################################################################################
=head1 Function: prinHashOfHash
------------------------------------------------

Function to print the content of  Hash-of-Hash.
 
@argument1	: Reference of HashOfHash whose values has to be printed. 
	
@return		: Nothing.
				  
Description:
1. Iterate through the outer key in sorted order.

2. Iterate through the inner key and print the corresponding value.

=cut
##########################################################################################
sub prinHashOfHash{
	# Getting the Hash Reference from the argument.
	my $hashOfHashRef = shift; 
	
	# Getting the Hash from its reference.
	my %hashOfHash = %$hashOfHashRef;

	# Step 1: Iterating through the OuterKeys Of the Hash.
	foreach my $sortedOuterKey (sort keys %hashOfHash){
		print "\n\nOuterKey = '$sortedOuterKey'";
	   
	    # Step 2: Iterating through the InnerKeys Of the Hash.
	    foreach my $sortedInnerKey (sort keys %{$hashOfHash{$sortedOuterKey}}){

			# Step 3:Printing the value.
	        print "\nInnerKey=$sortedInnerKey  ".
	        		"Value=$hashOfHash{$sortedOuterKey}{$sortedInnerKey}";        
	    }    
	}
}


##########################################################################################
=head1 Function: prinHashOfScore
------------------------------------------------

	This function will print the score of each cluster and its most
	probable against a topic and its corresponding score.



	For e.g:
	Direct Col Conclusion::	
		Cluster0 		:	Tony_Blair 		,	 0.577
		Cluster1 		:	Bill_Clinton 		,	 0.571
	Direct Row Conclusion::	
		Bill_Clinton 		:	Cluster1	 	,	 0.522
		Tony_Blair 		:	Cluster0 		,	 0.625

	Inverse Row Conclusion::	
		Cluster0 		:	Tony_Blair 		,	 0.625
		Cluster1 		:	Bill_Clinton 		,	 0.522
	Inverse Col Conclusion::	
		Bill_Clinton 		:	Cluster1 		,	 0.571
		Tony_Blair 		:	Cluster0 		,	 0.577


@Argument	: Reference of HashOfHash 
			 (i)  containing the topic (with supporting score) against a 
		 	   cluster name.
			 (ii) containing the cluster name (with supporting score) 
			   against a topic.

@return 	: Nothing.

@Description:
1. Get the HashOfHash Reference from the function argument.
2. Iterate through key in sorted order.
3. Clean the key and value.
4. Write the result into the Output file.


Output File:

Output file is the final file that user can see to get the detailed 
result about the complete evaluation process.

=cut
##########################################################################################

sub prinHashOfScore{
	# Getting the Hash Reference from the argument.
	my $topicClusterHashRef = shift; 
	
	# Getting the Hash from its reference.
	my %topicClusterHash = %$topicClusterHashRef;

	# Getting the File Handle from the function argument.
	my $outputFileHandle = shift;

	# Going through Hash and Printing the score.
	# Getting the Key of the Hash in the sorted order.
	foreach my $sortedKey (sort keys %topicClusterHash){
		
		# Extracting the "topic" from the key (FileName is the key).
		my $key = $sortedKey; 	
		
		# Removing the additional text from the key (filename related stuff).
		$key =~ s/temp_//;
		$key =~ s/.txt//;
		
		# Extracting the value from the hash.
		my $value = $topicClusterHash{$sortedKey};
		
		# Removing the additional text from the values (filename related stuff).
		$value =~ s/temp_//;
		$value =~ s/.txt//;
		
		# Writing the data into the output file.
		print $outputFileHandle "\n \t$key \t:\t$value"; 
	}
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
