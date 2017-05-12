package Yahoo::Marketing::APT::Test::GuaranteedDeal;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::GuaranteedDeal;

sub test_can_create_guaranteed_deal_and_set_all_fields : Test(14) {

    my $guaranteed_deal = Yahoo::Marketing::APT::GuaranteedDeal->new
                                                          ->activationTimestamp( '2009-01-06T17:51:55' )
                                                          ->audienceSharingRuleID( 'audience sharing rule id' )
                                                          ->buyerDetails( 'buyer details' )
                                                          ->buyerRevenueSharePercentage( 'buyer revenue share percentage' )
                                                          ->createTimestamp( '2009-01-07T17:51:55' )
                                                          ->endDate( '2009-01-08T17:51:55' )
                                                          ->lastUpdateTimestamp( '2009-01-09T17:51:55' )
                                                          ->name( 'name' )
                                                          ->sellerDetails( 'seller details' )
                                                          ->sellerRevenueSharePercentage( 'seller revenue share percentage' )
                                                          ->sellingRuleID( 'selling rule id' )
                                                          ->startDate( '2009-01-10T17:51:55' )
                                                          ->status( 'status' )
                   ;

    ok( $guaranteed_deal );

    is( $guaranteed_deal->activationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $guaranteed_deal->audienceSharingRuleID, 'audience sharing rule id', 'can get audience sharing rule id' );
    is( $guaranteed_deal->buyerDetails, 'buyer details', 'can get buyer details' );
    is( $guaranteed_deal->buyerRevenueSharePercentage, 'buyer revenue share percentage', 'can get buyer revenue share percentage' );
    is( $guaranteed_deal->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $guaranteed_deal->endDate, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $guaranteed_deal->lastUpdateTimestamp, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $guaranteed_deal->name, 'name', 'can get name' );
    is( $guaranteed_deal->sellerDetails, 'seller details', 'can get seller details' );
    is( $guaranteed_deal->sellerRevenueSharePercentage, 'seller revenue share percentage', 'can get seller revenue share percentage' );
    is( $guaranteed_deal->sellingRuleID, 'selling rule id', 'can get selling rule id' );
    is( $guaranteed_deal->startDate, '2009-01-10T17:51:55', 'can get 2009-01-10T17:51:55' );
    is( $guaranteed_deal->status, 'status', 'can get status' );

};



1;

