package Yahoo::Marketing::APT::Test::BasicResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BasicResponse;

sub test_can_create_basic_response_and_set_all_fields : Test(3) {

    my $basic_response = Yahoo::Marketing::APT::BasicResponse->new
                                                        ->errors( 'errors' )
                                                        ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $basic_response );

    is( $basic_response->errors, 'errors', 'can get errors' );
    is( $basic_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

