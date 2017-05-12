package Yahoo::Marketing::Test::Warning;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Warning;

sub test_can_create_warning_and_set_all_fields : Test(3) {

    my $warning = Yahoo::Marketing::Warning->new
                                           ->code( 'code' )
                                           ->message( 'message' )
                   ;

    ok( $warning );

    is( $warning->code, 'code', 'can get code' );
    is( $warning->message, 'message', 'can get message' );

};



1;

