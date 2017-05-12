package Yahoo::Marketing::APT::Test::OrderFeeResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OrderFeeResponse;

sub test_can_create_order_fee_response_and_set_all_fields : Test(4) {

    my $order_fee_response = Yahoo::Marketing::APT::OrderFeeResponse->new
                                                               ->errors( 'errors' )
                                                               ->operationSucceeded( 'operation succeeded' )
                                                               ->orderFee( 'order fee' )
                   ;

    ok( $order_fee_response );

    is( $order_fee_response->errors, 'errors', 'can get errors' );
    is( $order_fee_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $order_fee_response->orderFee, 'order fee', 'can get order fee' );

};



1;

