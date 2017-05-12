package Yahoo::Marketing::APT::Test::BidDescriptor;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BidDescriptor;

sub test_can_create_bid_descriptor_and_set_all_fields : Test(4) {

    my $bid_descriptor = Yahoo::Marketing::APT::BidDescriptor->new
                                                        ->bidDate( '2009-01-06T17:51:55' )
                                                        ->maxBid( 'max bid' )
                                                        ->pricingModel( 'pricing model' )
                   ;

    ok( $bid_descriptor );

    is( $bid_descriptor->bidDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $bid_descriptor->maxBid, 'max bid', 'can get max bid' );
    is( $bid_descriptor->pricingModel, 'pricing model', 'can get pricing model' );

};



1;

