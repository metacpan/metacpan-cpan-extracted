package Yahoo::Marketing::APT::Test::MakeGoodOrderCredit;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::MakeGoodOrderCredit;

sub test_can_create_make_good_order_credit_and_set_all_fields : Test(7) {

    my $make_good_order_credit = Yahoo::Marketing::APT::MakeGoodOrderCredit->new
                                                                      ->ID( 'id' )
                                                                      ->amount( 'amount' )
                                                                      ->createdByUserName( 'created by user name' )
                                                                      ->date( 'date' )
                                                                      ->orderID( 'order id' )
                                                                      ->status( 'status' )
                   ;

    ok( $make_good_order_credit );

    is( $make_good_order_credit->ID, 'id', 'can get id' );
    is( $make_good_order_credit->amount, 'amount', 'can get amount' );
    is( $make_good_order_credit->createdByUserName, 'created by user name', 'can get created by user name' );
    is( $make_good_order_credit->date, 'date', 'can get date' );
    is( $make_good_order_credit->orderID, 'order id', 'can get order id' );
    is( $make_good_order_credit->status, 'status', 'can get status' );

};



1;

