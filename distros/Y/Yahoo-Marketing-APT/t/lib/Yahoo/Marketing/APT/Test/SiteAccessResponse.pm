package Yahoo::Marketing::APT::Test::SiteAccessResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SiteAccessResponse;

sub test_can_create_site_access_response_and_set_all_fields : Test(4) {

    my $site_access_response = Yahoo::Marketing::APT::SiteAccessResponse->new
                                                                   ->errors( 'errors' )
                                                                   ->operationSucceeded( 'operation succeeded' )
                                                                   ->siteAccess( 'site access' )
                   ;

    ok( $site_access_response );

    is( $site_access_response->errors, 'errors', 'can get errors' );
    is( $site_access_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $site_access_response->siteAccess, 'site access', 'can get site access' );

};



1;

