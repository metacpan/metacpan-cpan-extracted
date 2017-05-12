#!/usr/local/bin/perl

=head1 NAME 

	Search - Examples of GoogleHack search function.

=head1 SYNOPSIS

	#include GoogleHack, so that it can be used

	use WebService::GoogleHack;

	#Change this variable if you are running this program from a directory
	#Other than WebService/GoogleHack/Example/

	$PATHCONFIGFILE="../Datafiles/initconfig.txt";

	#Create an Object of type WebService::GoogleHack

	$google = new WebService::GoogleHack;

	#initialize the object to required parameters by giving path to config
	#file.

	$google->initConfig("$PATHCONFIGFILE");

	#Now call search function like this

	#Here I am searching for duluth.

	$results=$google->Search("duluth");

	#The results variable will now contain the results of your query.

	#Printing the searchtime

	print "\n Search Time".$google->{'searchTime'};

	#Printing the snippet element 0

	print "\n\nSnippet".$google->{'snippet'}->[0];

=head1 DESCRIPTION

The examples in this module are meant to serve as a means of introducing to the user how to
use GoogleHack to use the search method, and retrieve the results.

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

#create an instance of GoogleHack called "google".

$google = new WebService::GoogleHack;

#initialize the object to required parameters by giving path to config
#file.

$google->initConfig("$PATHCONFIGFILE");

# Results will now contain the search results for the string "duluth".
$results=$google->Search("duluth");

# printing the searchtime
print "\nSearch Time ".$google->{'searchTime'};

#printing the snippet element 0
print "\n\nSnippet ".$google->{'snippet'}->[0];

#printing URL of the first result of the search for duluth.

print "\n\nURL ".$google->{'url'}->[0];

print "\n";
