package Yahoo::Marketing::APT::Test::Role;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Role;

sub test_can_create_role_and_set_all_fields : Test(7) {

    my $role = Yahoo::Marketing::APT::Role->new
                                     ->ID( 'id' )
                                     ->createTimestamp( '2009-01-06T17:51:55' )
                                     ->description( 'description' )
                                     ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                     ->name( 'name' )
                                     ->privilegeIDs( 'privilege ids' )
                   ;

    ok( $role );

    is( $role->ID, 'id', 'can get id' );
    is( $role->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $role->description, 'description', 'can get description' );
    is( $role->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $role->name, 'name', 'can get name' );
    is( $role->privilegeIDs, 'privilege ids', 'can get privilege ids' );

};



1;

