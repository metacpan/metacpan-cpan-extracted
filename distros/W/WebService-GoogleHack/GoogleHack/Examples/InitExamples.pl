#!/usr/local/bin/perl
=head1 NAME

InitExample - This program provides an example of the initialization function.

=head1 SYNOPSIS

	#include GoogleHack, so that it can be used

	use WebService::GoogleHack;

	$PATHCONFIGFILE="../Datafiles/initconfig.txt";

	#Create an Object of type WebService::GoogleHack
	
	$google = new WebService::GoogleHack;

	#Give the path to the configuration file to the config functions.

	$google->initConfig("$PATHCONFIGFILE");

=head1 DESCRIPTION

This program is intended to show the user how they can call the function 
to initialize the Google-Hack key, WSDL file path, and the word lists. 

1) Initialization through a configuration file.

Initialization through a configuration file is the most efficient method,
since, you would not need to type the Google-API key more than once.

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

###############################################################


#include GoogleHack, so that it can be used

use WebService::GoogleHack;

#Change this variable if you are running this program from a directory
#Other than WebService/GoogleHack/Example/

$PATHCONFIGFILE="initconfig.txt";

#create an instance of GoogleHack called "google".

$google = new WebService::GoogleHack;

#initialize the object to required parameters by giving path to config 
#file.

$google->initConfig("$PATHCONFIGFILE");

#Print the config file information that has been parsed

$google->printConfig();

$google->temp("input.txt");
















