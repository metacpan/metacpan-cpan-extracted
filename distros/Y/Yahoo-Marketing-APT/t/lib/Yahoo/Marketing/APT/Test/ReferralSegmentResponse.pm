package Yahoo::Marketing::APT::Test::ReferralSegmentResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReferralSegmentResponse;

sub test_can_create_referral_segment_response_and_set_all_fields : Test(4) {

    my $referral_segment_response = Yahoo::Marketing::APT::ReferralSegmentResponse->new
                                                                             ->errors( 'errors' )
                                                                             ->operationSucceeded( 'operation succeeded' )
                                                                             ->referralSegment( 'referral segment' )
                   ;

    ok( $referral_segment_response );

    is( $referral_segment_response->errors, 'errors', 'can get errors' );
    is( $referral_segment_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $referral_segment_response->referralSegment, 'referral segment', 'can get referral segment' );

};



1;

