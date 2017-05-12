#!/usr/local/bin/perl
=head1 NAME 

	Spelling - This is a perl program that gives the example use of 
	the Google-Hack function to retrieve a spelling suggestion.


=head1 SYNOPSIS
	
	#include GoogleHack, so that it can be used

	use WebService::GoogleHack;

	#Change this variable if you are running this program from a directory
	#Other than WebService/GoogleHack/Example/

	$PATHCONFIGFILE="../Datafiles/initconfig.txt";

	#Create an Object of type WebService::GoogleHack

	$google = new WebService::GoogleHack;
 
	#Initialize WebService::GoogleHack object to the key and WSDL 
        #config file path through config file.

	 $google->initConfig("$PATHCONFIGFILE");

	#Issuing a search request to the spelling suggestion function
	#Retrieve a spelling suggestion for the search String "dulut"

	$correction=$google->phraseSpelling("dulut");

	#If the string is "No Spelling Suggested", that means there was no spelling 
	#suggestions from Google.

	#I am just printing the suggested spelling

	print "\n\n The suggested spelling for dulut is : $correction\n\n";

=head1 DESCRIPTION

This program basically gives an example call to the phraseSpelling 
function in the Google-Hack.

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

# Retrieve a spelling suggestion for the search String "dulut" 
# The suggested spelling will be stored in the variable correction
# as a string. If the string is "No Spelling Suggested", that means there was no 
# suggestions from Google.


#issuing a search request to the spelling suggestion function

$correction=$google->phraseSpelling("dulut");


# I am just printing the suggested spelling

print "\nThe suggested spelling for \"dulut\" is : \"$correction\"\n";


$correction=$google->phraseSpelling("briney");


print "\nThe suggested spelling for \"briney\" is : \"$correction\"\n";

















