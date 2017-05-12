package Yahoo::Marketing::APT::Test::LinkResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LinkResponse;

sub test_can_create_link_response_and_set_all_fields : Test(4) {

    my $link_response = Yahoo::Marketing::APT::LinkResponse->new
                                                      ->errors( 'errors' )
                                                      ->link( 'link' )
                                                      ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $link_response );

    is( $link_response->errors, 'errors', 'can get errors' );
    is( $link_response->link, 'link', 'can get link' );
    is( $link_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

