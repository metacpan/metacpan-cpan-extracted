package Yahoo::Marketing::APT::Test::ReferralSegment;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReferralSegment;

sub test_can_create_referral_segment_and_set_all_fields : Test(12) {

    my $referral_segment = Yahoo::Marketing::APT::ReferralSegment->new
                                                            ->ID( 'id' )
                                                            ->accountID( 'account id' )
                                                            ->activationTimestamp( '2009-01-06T17:51:55' )
                                                            ->audienceSegmentCategoryID( 'audience segment category id' )
                                                            ->createTimestamp( '2009-01-07T17:51:55' )
                                                            ->deactivationTimestamp( '2009-01-08T17:51:55' )
                                                            ->description( 'description' )
                                                            ->lastUpdateTimestamp( '2009-01-09T17:51:55' )
                                                            ->name( 'name' )
                                                            ->referralUrls( 'referral urls' )
                                                            ->status( 'status' )
                   ;

    ok( $referral_segment );

    is( $referral_segment->ID, 'id', 'can get id' );
    is( $referral_segment->accountID, 'account id', 'can get account id' );
    is( $referral_segment->activationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $referral_segment->audienceSegmentCategoryID, 'audience segment category id', 'can get audience segment category id' );
    is( $referral_segment->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $referral_segment->deactivationTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $referral_segment->description, 'description', 'can get description' );
    is( $referral_segment->lastUpdateTimestamp, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $referral_segment->name, 'name', 'can get name' );
    is( $referral_segment->referralUrls, 'referral urls', 'can get referral urls' );
    is( $referral_segment->status, 'status', 'can get status' );

};



1;

