#!/usr/bin/perl -w

# Declaring the Package for the module.
package Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData;

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

#######################################################################################################################

=head1 Name 

Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData - Module for getting the information about a topic from wikipedia. 

=head1 SYNOPSIS

	#The following code snippet will show how to use this module.

	# Including the LabelEvaluation Module.
	use Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData;

	# Defining the topic name for which we will create the file containing their detail
	# data from the wikipedia.
	my $topicName ="BillClinton";

	# This tells to not to create the temp files (which will held the data feteched from 
	# wikipedia). To keep this file make it 0.
	my $isClean = 1;

	# The following code will call the getWikiDataForTopic() function from the 
	# GetWikiData modules. It will create the file containing the wikipedia 
	# information about the topic.
	my $fileName = 
		Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData::getWikiDataForTopic(
							$topicName, $isClean);

	print "\nName of the File created for the topic \'$topicName\' is $fileName \n";


=head1 DESCRIPTION
       		
		Given a topic, this module is responsible for getting the wikipedia 
		information about it and writing it to file with the file-name as, 
		'<topic_Name>.txt'   
			
=cut

##########################################################################################
=head1 function: getWikiDataFileForTopic

This function will fetch data about a topics from the Wikipedia, then it  
will write the fetched data into a new file 'topic_Name.txt'.


@argument1	: Name of the topic for which we need to fetch data from the 
 				  Wikipedia.

@return 	: Name of the file in which this function has written the 
				  data,'topic_Name.txt'.
		  
@description	:
	1). Reading the topic to read from the function arguments.
	2). Use this topic name to create file name in which we will write
		data about the topic.
	3). Get the data from the Wikipedia module about the topic and write
		it into the above mentioned topic.
	4). Return the file name.

=cut
##########################################################################################
sub getWikiDataFileForTopic{
	
	# Read the Topic name from the argument of the function.
	my $topicToLook = shift;
	
	# Removing the white space from the front and end of the word.
	$topicToLook =~ s/^\s+|\s+$//g;

	# Removing the white space with underscore.
	$topicToLook =~ s/\s+/_/g;

	# Creating the fileName from the topic name.
	my $fileName = "temp_$topicToLook.txt";
	
	
	# Open the file handle in Write Mode.
	open (MYFILE, ">$fileName");

	# Use Wikipedia Search to get the result about the topic.
	# Reference: http://search.cpan.org/~bricas/WWW-Wikipedia-2.00/	
	my $result = $wiki->search($topicToLook);

	# If the entry has some text, write it out to file.
	if ($result){
		# Writing the content of the search result into the newly created file.  
		print MYFILE $result->text();
		
		# Also writing the list of any related items into the files. 
		print MYFILE join( "\n", $result->related() );
	}

	# Close the file handle.
	close (MYFILE);

	# Returning the name of the file in which we write the Wikipedia data 
	# about the given topic.
	return $fileName;
}



#########################################################################################

=head1 function: getWikiDataForTopic() -

This function will fetch data about a topics from the Wikipedia and return to
user.

@argument1	: Name of the topic for which we need to fetch data from the 
 			  Wikipedia.
@return 	: String data about the topics.

=cut

#########################################################################################
sub getWikiDataForTopic{
	
	# Read the Topic name from the argument of the function.
	my $topicToLook = shift;
	
	# Reading the parameter which says whether to delete data or not.
	my $isClean = shift; 
	
	# Removing the white space from the front and end of the word.
	$topicToLook =~ s/^\s+|\s+$//g;

	# Variable that will hold all the string data for a given topic.
	my $topicData = "";
		
	# Use Wikipedia Search to get the result about the topic.
	# Reference: http://search.cpan.org/~bricas/WWW-Wikipedia-2.00/	
	my $result = $wiki->search($topicToLook);

	# If the entry has some text, write it out to file.
	if ($result){
		# Adding all the text to $topicData variable.
		$topicData = $topicData.$result->text(); 
		
		# Also adding the list of any related items into the files. 
		$topicData = $topicData.join("\n", $result->related());
	}

	# If user want to see the wiki files, he will mention isClean==1.
	if($isClean == 0){
		# Creating the fileName from the topic name.
		my $fileName = "temp_$topicToLook.txt";
		# Open the file handle in Write Mode.
		open (MYFILE, ">$fileName");
		# Writing the content of the search result into the newly created file.
		print MYFILE $topicData;
		# Close the file handle.
		close (MYFILE);
	}
	
	# Returning the wikipedia about the topic
	return $topicData;
}



#######################################################################################################
=pod

=head1 SEE ALSO

http://senseclusters.cvs.sourceforge.net/viewvc/senseclusters/LabelEvaluation/ 
 
Last modified by :
$Id: GetWikiData.pm,v 1.6 2013/03/18 02:17:16 jhaxx030 Exp $

	
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
