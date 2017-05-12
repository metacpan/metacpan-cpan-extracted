package Yahoo::Marketing::APT::Test::Privilege;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Privilege;

sub test_can_create_privilege_and_set_all_fields : Test(4) {

    my $privilege = Yahoo::Marketing::APT::Privilege->new
                                               ->ID( 'id' )
                                               ->description( 'description' )
                                               ->name( 'name' )
                   ;

    ok( $privilege );

    is( $privilege->ID, 'id', 'can get id' );
    is( $privilege->description, 'description', 'can get description' );
    is( $privilege->name, 'name', 'can get name' );

};



1;

