#!/usr/local/bin/perl

=head1 NAME 

	Rate_Sentiment - Simple program that interacts with GoogleHack to 
        classify the sentiment of words etc.

=head1 SYNOPSIS

	#Change this variable if you are running this program from a directory

	#Other than WebService/GoogleHack/Example/

	$PATHCONFIGFILE="../Datafiles/initconfig.txt";

        #set to the entire path to inpute file

        $INPUTFILE="";

        # give string such as excellent as a positive inference
        
        $POSITIVE="";

        # give string such as bad as a negative inference

        $NEGATIVE="";

        # Set to true if you want the result sin html format

        $HTML="";

        #Set to trace file locations
        
        $TRACEFILE="";

	#Create an Object of type WebService::GoogleHack

	$google = new WebService::GoogleHack;
 
	#initialize the object to required parameters by giving path to config

	#file.

	$google->initConfig("$PATHCONFIGFILE");

        #predict the semantic orientation of the words given text file, and use the word 

        $results=$google->predictWordSentiment($INPUTFILE,$POSITIVE,$NEGATIVE,$HTML,$TRACEFILE);

        print $results;

        #predict the semantic orientation of the phrases given text file, and use the word 

        $results=$google->predictPhraseSentiment($INPUTFILE,$POSITIVE,$NEGATIVE,$HTML,$TRACEFILE);

	
=head1 DESCRIPTION

This program contains example usage of the GoogleHack sentiment classification functions.

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

#set to the entire path to inpute file

$INPUTFILE="";

# give string such as excellent as a positive inference
$POSITIVE="";

# give string such as bad as a negative inference
$NEGATIVE="";

# Set to true if you want the result sin html format
$HTML="";

#Set to trace file locations
$TRACEFILE="";

#create an instance of WebService::GoogleHack called "google".

$google = new WebService::GoogleHack;

#initialize the object to required parameters by giving path to config
#file.

$google->initConfig("$PATHCONFIGFILE");

#print the config file information that has been parsed

$google->printConfig();

#predict the semantic orientation of the words given text file, and use the word 
$results=$google->predictWordSentiment($INPUTFILE,$POSITIVE,$NEGATIVE,$HTML,$TRACEFILE);

print $results;

#predict the semantic orientation of the phrases given text file, and use the word 
$results=$google->predictPhraseSentiment($INPUTFILE,$POSITIVE,$NEGATIVE,$HTML,$TRACEFILE);

print $results;

print "\nRelatedness measure $measure";







