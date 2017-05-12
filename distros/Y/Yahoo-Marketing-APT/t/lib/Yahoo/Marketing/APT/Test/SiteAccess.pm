package Yahoo::Marketing::APT::Test::SiteAccess;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SiteAccess;

sub test_can_create_site_access_and_set_all_fields : Test(9) {

    my $site_access = Yahoo::Marketing::APT::SiteAccess->new
                                                  ->ID( 'id' )
                                                  ->method( 'method' )
                                                  ->password( 'password' )
                                                  ->passwordParameter( 'password parameter' )
                                                  ->siteID( 'site id' )
                                                  ->url( 'url' )
                                                  ->username( 'username' )
                                                  ->usernameParameter( 'username parameter' )
                   ;

    ok( $site_access );

    is( $site_access->ID, 'id', 'can get id' );
    is( $site_access->method, 'method', 'can get method' );
    is( $site_access->password, 'password', 'can get password' );
    is( $site_access->passwordParameter, 'password parameter', 'can get password parameter' );
    is( $site_access->siteID, 'site id', 'can get site id' );
    is( $site_access->url, 'url', 'can get url' );
    is( $site_access->username, 'username', 'can get username' );
    is( $site_access->usernameParameter, 'username parameter', 'can get username parameter' );

};



1;

