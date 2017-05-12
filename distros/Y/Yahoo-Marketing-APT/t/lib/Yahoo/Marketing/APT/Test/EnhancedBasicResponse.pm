package Yahoo::Marketing::APT::Test::EnhancedBasicResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::EnhancedBasicResponse;

sub test_can_create_enhanced_basic_response_and_set_all_fields : Test(3) {

    my $enhanced_basic_response = Yahoo::Marketing::APT::EnhancedBasicResponse->new
                                                                         ->errors( 'errors' )
                                                                         ->operationResult( 'operation result' )
                   ;

    ok( $enhanced_basic_response );

    is( $enhanced_basic_response->errors, 'errors', 'can get errors' );
    is( $enhanced_basic_response->operationResult, 'operation result', 'can get operation result' );

};



1;

