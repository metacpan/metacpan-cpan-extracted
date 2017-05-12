#!/usr/local/bin/perl

=head1 NAME 

	WordCluster - Simple program that uses the GoogleHack functions to 
        retrieve related set of words.

=head1 SYNOPSIS

	#Change this variable if you are running this program from a directory

	#Other than WebService/GoogleHack/Example/

	$PATHCONFIGFILE="../Datafiles/initconfig.txt";

	#Create an Object of type WebService::GoogleHack

	$google = new WebService::GoogleHack;
 
	#initialize the object to required parameters by giving path to config

	#file.

	$google->initConfig("$PATHCONFIGFILE");
	
=head1 DESCRIPTION

This program shows the example usage of the sets of related words functions.

=head1 AUTHOR

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt>

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt>

=head1 BUGS

=head1 SEE ALSO

WebService::GoogleHack home page - http://google-hack.sourceforge.net

Pratheepan Raveendranathan - http://www.d.umn.edu/~rave0029/research

Ted Pedersen - www.d.umn.edu./~tpederse

Google-Hack Maling List E<lt>google-hack-users@lists.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 by Pratheepan Raveendranathan, Ted Pedersen

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut

#include GoogleHack, so that it can be used

use WebService::GoogleHack;

#Change this variable if you are running this program from a directory
#Other than WebService/GoogleHack/Example/

$PATHCONFIGFILE="../Datafiles/initconfig.txt";

#create an instance of WebService::GoogleHack called "google".

$google = new WebService::GoogleHack;

#initialize the object to required parameters by giving path to config
#file.

$google->initConfig("$PATHCONFIGFILE");

#print the config file information that has been parsed

$google->printConfig();

#predict the semantic orientation of the given review file, and use the word 
#"excellent" to denote a positive semantic orientation and the word "bad" to 
#denote a negative semanctic orientation.
#write the output to the exp,txt file.

#######################################################################
#
# Given a search word, this function tries to retreive the
# text surrounding the search word in the retrieved snippets.
#######################################################################

#$google->getSearchSnippetWords("knife", 5,"test.txt");

# by passing the search string and the tracefile
# Given a google word, this function tries to retreive the
# sentences in the cached web page.
#$google->getCachedSurroundingWords("duluth", "test2.txt");

# Given a search word, this function tries to retreive the
# sentences in the snippet.
#$google->getSnippetSentences("knife", "test.txt");


# given two search words, this function tries to retreive the
# common text surrounding the search words in the retrieved snippets.
#$google->getSearchCommonWords("knife", "scissors");

#$google->getSearchCommonWords("toyota", "ford",10,"result.txt");
#$google->getPairWordClusters("toyota", "ford",10,1,"result1.txt");
#$google->getText("duluth","/home/vold/47/rave0029/Data/");

#Predict Set of Related words for Rachel and Ross.
@terms=();
push(@terms,"rachel");
push(@terms,"ross");

$results=$google->Algorithm1(\@terms,10,25,1,"results.txt","true");

print "\n $results";





