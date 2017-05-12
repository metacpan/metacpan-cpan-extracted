package Yahoo::Marketing::Test::Error;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Error;

sub test_can_create_error_and_set_all_fields : Test(3) {

    my $error = Yahoo::Marketing::Error->new
                                       ->code( 'code' )
                                       ->message( 'message' )
                   ;

    ok( $error );

    is( $error->code, 'code', 'can get code' );
    is( $error->message, 'message', 'can get message' );

};



1;

