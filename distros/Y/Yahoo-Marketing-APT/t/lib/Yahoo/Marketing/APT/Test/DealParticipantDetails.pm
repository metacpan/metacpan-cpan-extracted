package Yahoo::Marketing::APT::Test::DealParticipantDetails;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DealParticipantDetails;

sub test_can_create_deal_participant_details_and_set_all_fields : Test(3) {

    my $deal_participant_details = Yahoo::Marketing::APT::DealParticipantDetails->new
                                                                           ->acceptedTimestamp( '2009-01-06T17:51:55' )
                                                                           ->comments( 'comments' )
                   ;

    ok( $deal_participant_details );

    is( $deal_participant_details->acceptedTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $deal_participant_details->comments, 'comments', 'can get comments' );

};



1;

