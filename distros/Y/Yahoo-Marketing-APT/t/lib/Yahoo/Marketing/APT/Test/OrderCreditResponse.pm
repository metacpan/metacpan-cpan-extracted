package Yahoo::Marketing::APT::Test::OrderCreditResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OrderCreditResponse;

sub test_can_create_order_credit_response_and_set_all_fields : Test(4) {

    my $order_credit_response = Yahoo::Marketing::APT::OrderCreditResponse->new
                                                                     ->errors( 'errors' )
                                                                     ->operationSucceeded( 'operation succeeded' )
                                                                     ->orderCredit( 'order credit' )
                   ;

    ok( $order_credit_response );

    is( $order_credit_response->errors, 'errors', 'can get errors' );
    is( $order_credit_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $order_credit_response->orderCredit, 'order credit', 'can get order credit' );

};



1;

