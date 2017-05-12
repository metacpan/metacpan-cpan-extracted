package Yahoo::Marketing::APT::Test::OrderFee;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OrderFee;

sub test_can_create_order_fee_and_set_all_fields : Test(9) {

    my $order_fee = Yahoo::Marketing::APT::OrderFee->new
                                              ->ID( 'id' )
                                              ->amount( 'amount' )
                                              ->endDate( '2009-01-06T17:51:55' )
                                              ->orderID( 'order id' )
                                              ->siteID( 'site id' )
                                              ->startDate( '2009-01-07T17:51:55' )
                                              ->status( 'status' )
                                              ->type( 'type' )
                   ;

    ok( $order_fee );

    is( $order_fee->ID, 'id', 'can get id' );
    is( $order_fee->amount, 'amount', 'can get amount' );
    is( $order_fee->endDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $order_fee->orderID, 'order id', 'can get order id' );
    is( $order_fee->siteID, 'site id', 'can get site id' );
    is( $order_fee->startDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $order_fee->status, 'status', 'can get status' );
    is( $order_fee->type, 'type', 'can get type' );

};



1;

