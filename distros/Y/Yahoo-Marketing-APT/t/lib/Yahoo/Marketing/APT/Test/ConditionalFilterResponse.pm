package Yahoo::Marketing::APT::Test::ConditionalFilterResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ConditionalFilterResponse;

sub test_can_create_conditional_filter_response_and_set_all_fields : Test(4) {

    my $conditional_filter_response = Yahoo::Marketing::APT::ConditionalFilterResponse->new
                                                                                 ->errors( 'errors' )
                                                                                 ->filter( 'filter' )
                                                                                 ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $conditional_filter_response );

    is( $conditional_filter_response->errors, 'errors', 'can get errors' );
    is( $conditional_filter_response->filter, 'filter', 'can get filter' );
    is( $conditional_filter_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

