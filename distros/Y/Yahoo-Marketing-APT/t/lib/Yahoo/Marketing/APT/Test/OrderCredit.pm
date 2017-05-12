package Yahoo::Marketing::APT::Test::OrderCredit;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OrderCredit;

sub test_can_create_order_credit_and_set_all_fields : Test(10) {

    my $order_credit = Yahoo::Marketing::APT::OrderCredit->new
                                                    ->ID( 'id' )
                                                    ->amount( 'amount' )
                                                    ->billingMonth( 'billing month' )
                                                    ->createdByUserName( 'created by user name' )
                                                    ->date( 'date' )
                                                    ->orderID( 'order id' )
                                                    ->placementID( 'placement id' )
                                                    ->reason( 'reason' )
                                                    ->status( 'status' )
                   ;

    ok( $order_credit );

    is( $order_credit->ID, 'id', 'can get id' );
    is( $order_credit->amount, 'amount', 'can get amount' );
    is( $order_credit->billingMonth, 'billing month', 'can get billing month' );
    is( $order_credit->createdByUserName, 'created by user name', 'can get created by user name' );
    is( $order_credit->date, 'date', 'can get date' );
    is( $order_credit->orderID, 'order id', 'can get order id' );
    is( $order_credit->placementID, 'placement id', 'can get placement id' );
    is( $order_credit->reason, 'reason', 'can get reason' );
    is( $order_credit->status, 'status', 'can get status' );

};



1;

