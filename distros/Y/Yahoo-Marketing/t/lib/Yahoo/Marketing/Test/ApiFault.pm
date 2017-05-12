package Yahoo::Marketing::Test::ApiFault;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ApiFault;

sub test_can_create_api_fault_and_set_all_fields : Test(3) {

    my $api_fault = Yahoo::Marketing::ApiFault->new
                                              ->code( 'code' )
                                              ->message( 'message' )
                   ;

    ok( $api_fault );

    is( $api_fault->code, 'code', 'can get code' );
    is( $api_fault->message, 'message', 'can get message' );

};



1;

