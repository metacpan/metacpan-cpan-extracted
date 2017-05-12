package Yahoo::Marketing::Test::ResponseStatusType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ResponseStatusType;

sub test_can_create_response_status_type_and_set_all_fields : Test(3) {

    my $response_status_type = Yahoo::Marketing::ResponseStatusType->new
                                                                   ->error( 'error' )
                                                                   ->status( 'status' )
                   ;

    ok( $response_status_type );

    is( $response_status_type->error, 'error', 'can get error' );
    is( $response_status_type->status, 'status', 'can get status' );

};



1;

