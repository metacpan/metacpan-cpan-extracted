package Yahoo::Marketing::APT::Test::LinkParticipantDetails;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LinkParticipantDetails;

sub test_can_create_link_participant_details_and_set_all_fields : Test(5) {

    my $link_participant_details = Yahoo::Marketing::APT::LinkParticipantDetails->new
                                                                           ->acceptedTimestamp( '2009-01-06T17:51:55' )
                                                                           ->accountID( 'account id' )
                                                                           ->comments( 'comments' )
                                                                           ->contact( 'contact' )
                   ;

    ok( $link_participant_details );

    is( $link_participant_details->acceptedTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $link_participant_details->accountID, 'account id', 'can get account id' );
    is( $link_participant_details->comments, 'comments', 'can get comments' );
    is( $link_participant_details->contact, 'contact', 'can get contact' );

};



1;

