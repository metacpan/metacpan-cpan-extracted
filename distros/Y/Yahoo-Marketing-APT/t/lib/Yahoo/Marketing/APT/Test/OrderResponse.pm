package Yahoo::Marketing::APT::Test::OrderResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OrderResponse;

sub test_can_create_order_response_and_set_all_fields : Test(4) {

    my $order_response = Yahoo::Marketing::APT::OrderResponse->new
                                                        ->errors( 'errors' )
                                                        ->operationSucceeded( 'operation succeeded' )
                                                        ->order( 'order' )
                   ;

    ok( $order_response );

    is( $order_response->errors, 'errors', 'can get errors' );
    is( $order_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $order_response->order, 'order', 'can get order' );

};



1;

