#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    10/11/2016                                                             #
#    Revised: 01/31/2017                                                             #
#    Word Sense Disambiguation - Data Entry Class For Use With Interface.pm          #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#       Word Sense Disambiguation Data Entry Class - Stores Instance/Sense Data      #
#                                                                                    #
######################################################################################


package Word2vec::Wsddata;

use strict;
use warnings;

# Standard Package(s)
use Class::Struct;


use vars qw($VERSION);

$VERSION = '0.02';


# Declare struct for storing instance/sense data.
struct( WSDData => {
    instanceID        => '$',
    answerInstanceID  => '$',
    senseID           => '$',
    contextStr        => '$',
    calculatedSenseID => '$',
    cosSimValue       => '$',
    vectorAvgStr      => '$',
} );

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Wsddata - Word Sense Disambiguation Data Module.

=head1 SYNOPSIS

 use Word2vec::Wsddata;

 my $wsddata = Word2vec::Wsddata->new();

 die "Error creating Word2vec::Wsddata\n" if !defined( $wsddata );

 $wsddata->instanceID( "08132016" );
 $wsddata->senseID( "1207" );
 $wsddata->calculatedSenseID( "0.0" );

 my $instanceID = $wsddata->instanceID;
 my $senseID = $wsddata->senseID;
 my $calcSenseID = $wsddata->calculatedSenseID;

 print( "InstanceID: $instanceID\n" );
 print( "Assigned SenseID: $senseID\n" );
 print( "Calculated SenseID: $calcSenseID\n" );

 undef( $wsddata );

=head1 DESCRIPTION

Word2vec::Wsddata is a Word Sense Disambiguation data module which
stores instance/sense data for use with Word2vec::Interface.

=head1 Author

 Clint Cuffy, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2016

 Bridget T McInnes, Virginia Commonwealth University
 btmcinnes at vcu dot edu

 Clint Cuffy, Virginia Commonwealth University
 cuffyca at vcu dot edu

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut
