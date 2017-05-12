package Yahoo::Marketing::Test::CarrierBidInformation;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CarrierBidInformation;

sub test_can_create_carrier_bid_information_and_set_all_fields : Test(5) {

    my $carrier_bid_information = Yahoo::Marketing::CarrierBidInformation->new
                                                                         ->bidInformation( 'bid information' )
                                                                         ->carrier( 'carrier' )
                                                                         ->error( 'error' )
                                                                         ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $carrier_bid_information );

    is( $carrier_bid_information->bidInformation, 'bid information', 'can get bid information' );
    is( $carrier_bid_information->carrier, 'carrier', 'can get carrier' );
    is( $carrier_bid_information->error, 'error', 'can get error' );
    is( $carrier_bid_information->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

