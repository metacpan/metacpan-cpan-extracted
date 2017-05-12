package Yahoo::Marketing::APT::Test::ApiFault;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApiFault;

sub test_can_create_api_fault_and_set_all_fields : Test(3) {

    my $api_fault = Yahoo::Marketing::APT::ApiFault->new
                                              ->code( 'code' )
                                              ->message( 'message' )
                   ;

    ok( $api_fault );

    is( $api_fault->code, 'code', 'can get code' );
    is( $api_fault->message, 'message', 'can get message' );

};



1;

