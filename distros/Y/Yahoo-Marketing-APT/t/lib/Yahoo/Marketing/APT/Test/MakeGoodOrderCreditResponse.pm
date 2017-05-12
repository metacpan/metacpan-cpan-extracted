package Yahoo::Marketing::APT::Test::MakeGoodOrderCreditResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::MakeGoodOrderCreditResponse;

sub test_can_create_make_good_order_credit_response_and_set_all_fields : Test(4) {

    my $make_good_order_credit_response = Yahoo::Marketing::APT::MakeGoodOrderCreditResponse->new
                                                                                       ->errors( 'errors' )
                                                                                       ->makeGoodOrderCredit( 'make good order credit' )
                                                                                       ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $make_good_order_credit_response );

    is( $make_good_order_credit_response->errors, 'errors', 'can get errors' );
    is( $make_good_order_credit_response->makeGoodOrderCredit, 'make good order credit', 'can get make good order credit' );
    is( $make_good_order_credit_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

