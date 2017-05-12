#!/usr/local/bin/perl

=head1 NAME 

	Rate - This is a perl program that gives the example use of the 
	Google-Hack Rate functions which manipulate the text 
	retrieved from the web to .

=head1 SYNOPSIS

	#include GoogleHack, so that it can be used

	use WebService::GoogleHack;

	#Change this variable if you are running this program from a directory
	#Other than WebService/GoogleHack/Example/

	$PATHCONFIGFILE="../Datafiles/initconfig.txt";

	#Create an Object of type WebService::GoogleHack

	$rate = new WebService::GoogleHack;

	#Initialize WebService::GoogleHack object using the config file.
 
	$rate->initConfig("$PATHCONFIGFILE");

	#Now call measureSemanticRelatedness function like this to find the 
	#relatedness measure between the words "knife" and "cut":

	$Relatedness = $rate-> measureSemanticRelatedness1("knife", "cut");

	#The variable $Relatedness will now contain the results of your query.
 
	$rate->predictSemanticOrientation("PATH TO REVIEW FILE","excellent","bad","
	PATH TO TRACE FILE");

=head1 DESCRIPTION

This program gives examples of calling the relatedness
functions (NLP related functions).

=head1 AUTHOR

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt>

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt>

=head1 BUGS

=head1 SEE ALSO

GoogleHack home page - http://google-hack.sourceforge.net

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


use WebService::GoogleHack;
use strict;

#Create an Object of type WebService::GoogleHack

my $rate = new WebService::GoogleHack;


#######################################################################
# Preferred initialization method
#
#######################################################################
# Initialize search to the contents of the configuration file
#######################################################################

#######################################################################
# Make sure to pass the ENTIRE path to the configuration file
# Config file should be in WebService/GoogleHack/Datafiles/
#######################################################################
my $PATHCONFIGFILE="../Datafiles/initconfig.txt";

$rate->initConfig("$PATHCONFIGFILE");

#printing the config file information that has been parsed

$rate->printConfig();

# Given two words, this function will try to predict the relatedness between
# the two words. This relatedness is a measure of calculated using the PMI
# formula.

my $Relatedness = $rate-> measureSemanticRelatedness1("knife", "cut");

print "\n The measure is $Relatedness";
#predict the semantic orientation of the given review file, and use the word 
#"excellent" to denote a positive semantic orientation and the word "bad" to 
#denote a negative semanctic orientation.

#write the output to the exp,txt file.


#######################################################################
# Make sure to pass the ENTIRE path to the review file & tracefile
# An example REVIEW FILE is given in the Webservice/GoogleHack/Datafiles 
#######################################################################

my $PATHREVIEWFILE="/home/vold/47/rave0029/WebService/GoogleHack/Datafiles/review.txt";

#output would be written to the file trace.txt

my $output=$rate->predictSemanticOrientation("$PATHREVIEWFILE","excellent","bad","trace,txt");

print $output;




