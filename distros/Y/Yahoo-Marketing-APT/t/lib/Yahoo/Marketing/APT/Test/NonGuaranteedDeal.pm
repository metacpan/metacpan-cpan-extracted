package Yahoo::Marketing::APT::Test::NonGuaranteedDeal;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::NonGuaranteedDeal;

sub test_can_create_non_guaranteed_deal_and_set_all_fields : Test(12) {

    my $non_guaranteed_deal = Yahoo::Marketing::APT::NonGuaranteedDeal->new
                                                                 ->activationTimestamp( '2009-01-06T17:51:55' )
                                                                 ->buyerDetails( 'buyer details' )
                                                                 ->buyerRevenueSharePercentage( 'buyer revenue share percentage' )
                                                                 ->createTimestamp( '2009-01-07T17:51:55' )
                                                                 ->endDate( '2009-01-08T17:51:55' )
                                                                 ->lastUpdateTimestamp( '2009-01-09T17:51:55' )
                                                                 ->name( 'name' )
                                                                 ->sellerDetails( 'seller details' )
                                                                 ->sellerRevenueSharePercentage( 'seller revenue share percentage' )
                                                                 ->startDate( '2009-01-10T17:51:55' )
                                                                 ->status( 'status' )
                   ;

    ok( $non_guaranteed_deal );

    is( $non_guaranteed_deal->activationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $non_guaranteed_deal->buyerDetails, 'buyer details', 'can get buyer details' );
    is( $non_guaranteed_deal->buyerRevenueSharePercentage, 'buyer revenue share percentage', 'can get buyer revenue share percentage' );
    is( $non_guaranteed_deal->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $non_guaranteed_deal->endDate, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $non_guaranteed_deal->lastUpdateTimestamp, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $non_guaranteed_deal->name, 'name', 'can get name' );
    is( $non_guaranteed_deal->sellerDetails, 'seller details', 'can get seller details' );
    is( $non_guaranteed_deal->sellerRevenueSharePercentage, 'seller revenue share percentage', 'can get seller revenue share percentage' );
    is( $non_guaranteed_deal->startDate, '2009-01-10T17:51:55', 'can get 2009-01-10T17:51:55' );
    is( $non_guaranteed_deal->status, 'status', 'can get status' );

};



1;

