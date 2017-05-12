package Yahoo::Marketing::APT::Test::RoleResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::RoleResponse;

sub test_can_create_role_response_and_set_all_fields : Test(4) {

    my $role_response = Yahoo::Marketing::APT::RoleResponse->new
                                                      ->errors( 'errors' )
                                                      ->operationSucceeded( 'operation succeeded' )
                                                      ->role( 'role' )
                   ;

    ok( $role_response );

    is( $role_response->errors, 'errors', 'can get errors' );
    is( $role_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $role_response->role, 'role', 'can get role' );

};



1;

