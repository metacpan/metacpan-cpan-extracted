package Yahoo::Marketing::Test::BasicResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BasicResponse;

sub test_can_create_basic_response_and_set_all_fields : Test(4) {

    my $basic_response = Yahoo::Marketing::BasicResponse->new
                                                        ->errors( 'errors' )
                                                        ->operationSucceeded( 'operation succeeded' )
                                                        ->warnings( 'warnings' )
                   ;

    ok( $basic_response );

    is( $basic_response->errors, 'errors', 'can get errors' );
    is( $basic_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $basic_response->warnings, 'warnings', 'can get warnings' );

};



1;

