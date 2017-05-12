package Yahoo::Marketing::Test::Role;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Role;

sub test_can_create_role_and_set_all_fields : Test(2) {

    my $role = Yahoo::Marketing::Role->new
                                     ->name( 'name' )
                   ;

    ok( $role );

    is( $role->name, 'name', 'can get name' );

};



1;

