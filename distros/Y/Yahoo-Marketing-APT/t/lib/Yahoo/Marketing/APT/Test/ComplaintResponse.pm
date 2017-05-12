package Yahoo::Marketing::APT::Test::ComplaintResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ComplaintResponse;

sub test_can_create_complaint_response_and_set_all_fields : Test(4) {

    my $complaint_response = Yahoo::Marketing::APT::ComplaintResponse->new
                                                                ->complaint( 'complaint' )
                                                                ->errors( 'errors' )
                                                                ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $complaint_response );

    is( $complaint_response->complaint, 'complaint', 'can get complaint' );
    is( $complaint_response->errors, 'errors', 'can get errors' );
    is( $complaint_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

