package Yahoo::Marketing::Test::ErrorType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ErrorType;

sub test_can_create_error_type_and_set_all_fields : Test(3) {

    my $error_type = Yahoo::Marketing::ErrorType->new
                                                ->key( 'key' )
                                                ->param( 'param' )
                   ;

    ok( $error_type );

    is( $error_type->key, 'key', 'can get key' );
    is( $error_type->param, 'param', 'can get param' );

};



1;

