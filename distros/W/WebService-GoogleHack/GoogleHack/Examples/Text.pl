#!/usr/local/bin/perl
=head1 NAME 

	Text - This is a perl program that gives the example use of the 
	Google-Hack Text functions which manipulate the text retrieved
	from the web.

=head1 SYNOPSIS

	#include GoogleHack, so that it can be used

	use WebService::GoogleHack;

	#Change this variable if you are running this program from a directory
	#Other than WebService/GoogleHack/Example/

	$PATHCONFIGFILE="../Datafiles/initconfig.txt";


	#create an instance of GoogleHack called "google".

	$google = new WebService::GoogleHack;


	#initialize the object to required parameters by giving path to config
	#file.

	$google->initConfig("$PATHCONFIGFILE");

	# given a search word, this function tries to retreive the

	# text surrounding the search word in the retrieved snippets.

	# in this case the search word is "knife" and the results

	# will be written out to test.txt

	$google->getSearchSnippetWords("knife", 5,"test.txt");

	# by passing the search string and the tracefile

	# Given a search word, this function tries to retreive the

	# sentences in the cached web page.

	# in this case the search word is "knife" and the results

	# will be written out to test2.txt

	$google->getCachedSurroundingWords("knife", "test2.txt");

	# Given a search word, this function tries to retreive the

	# sentences in the snippet

	# in this case the search word is "knife" and the results

	# will be written out to test.txt

	$google->getSnippetSentences("knife", "test.txt");

=head1 DESCRIPTION

Example usage Text functions.

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

#create an instance of GoogleHack called "Search".

$google = new WebService::GoogleHack;

#initialize the object to required parameters by giving path to config
#file.

$google->initConfig("$PATHCONFIGFILE");

# given a search word, this function tries to retreive the
# text surrounding the search word in the retrieved snippets.
# in this case the search word is "knife" and the results
# will be written out to test.txt

$google->getSearchSnippetWords("knife", 5,"test.txt");

# by passing the search string and the tracefile
# Given a search word, this function tries to retreive the
# sentences in the cached web page.
# in this case the search word is "knife" and the results
# will be written out to test2.txt

$google->getCachedSurroundingWords("knife", "test2.txt");

# Given a search word, this function tries to retreive the
# sentences in the snippet
# in this case the search word is "knife" and the results
# will be written out to test.txt

$google->getSnippetSentences("knife", "test.txt");


# given two search words, this function tries to retreive the
# common text surrounding the search words in the retrieved snippets.
$google->getSearchCommonWords("knife", "scissors");




