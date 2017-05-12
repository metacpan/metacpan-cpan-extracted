package Yahoo::Marketing::APT::Test::UserResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::UserResponse;

sub test_can_create_user_response_and_set_all_fields : Test(4) {

    my $user_response = Yahoo::Marketing::APT::UserResponse->new
                                                      ->errors( 'errors' )
                                                      ->operationSucceeded( 'operation succeeded' )
                                                      ->user( 'user' )
                   ;

    ok( $user_response );

    is( $user_response->errors, 'errors', 'can get errors' );
    is( $user_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $user_response->user, 'user', 'can get user' );

};



1;

