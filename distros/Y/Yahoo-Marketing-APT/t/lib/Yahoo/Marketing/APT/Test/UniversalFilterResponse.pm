package Yahoo::Marketing::APT::Test::UniversalFilterResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::UniversalFilterResponse;

sub test_can_create_universal_filter_response_and_set_all_fields : Test(4) {

    my $universal_filter_response = Yahoo::Marketing::APT::UniversalFilterResponse->new
                                                                             ->errors( 'errors' )
                                                                             ->filter( 'filter' )
                                                                             ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $universal_filter_response );

    is( $universal_filter_response->errors, 'errors', 'can get errors' );
    is( $universal_filter_response->filter, 'filter', 'can get filter' );
    is( $universal_filter_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

