package Yahoo::Marketing::Test::Capability;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Capability;

sub test_can_create_capability_and_set_all_fields : Test(3) {

    my $capability = Yahoo::Marketing::Capability->new
                                                 ->description( 'description' )
                                                 ->name( 'name' )
                   ;

    ok( $capability );

    is( $capability->description, 'description', 'can get description' );
    is( $capability->name, 'name', 'can get name' );

};



1;

