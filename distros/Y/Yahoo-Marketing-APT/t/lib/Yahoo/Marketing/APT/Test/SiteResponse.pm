package Yahoo::Marketing::APT::Test::SiteResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SiteResponse;

sub test_can_create_site_response_and_set_all_fields : Test(4) {

    my $site_response = Yahoo::Marketing::APT::SiteResponse->new
                                                      ->errors( 'errors' )
                                                      ->operationSucceeded( 'operation succeeded' )
                                                      ->site( 'site' )
                   ;

    ok( $site_response );

    is( $site_response->errors, 'errors', 'can get errors' );
    is( $site_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $site_response->site, 'site', 'can get site' );

};



1;

