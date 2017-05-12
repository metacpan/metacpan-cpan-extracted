#!perl -T
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use Test::More tests => 35;

use Yahoo::Marketing::Service;
use Cache::SizeAwareFileCache;

my $ysm_ws = Yahoo::Marketing::Service->new;

ok( $ysm_ws, 'can intantiate' );

is( $ysm_ws->use_wsse_security_headers, 1, 'use wsse security headers defaults' );
is( $ysm_ws->use_location_service,      1, 'use location service defaults' );
is( $ysm_ws->version, 'V7', 'version defaults' );
is( $ysm_ws->uri, 'http://marketing.ews.yahooapis.com/V7', 'uri defaults' );
is( $ysm_ws->cache_expire_time, '1 day', 'cache expire time defaults' );
is( ref $ysm_ws->cache, 'Cache::FileCache', 'cache defaults' );


ok( $ysm_ws->username( 'our test username' ), 'can set username' );
ok( $ysm_ws->password( 'our test password' ), 'can set password' );
ok( $ysm_ws->license( 'our test license' ), 'can set license' );
ok( $ysm_ws->master_account( 'our test master_account' ), 'can set master_account' );
ok( $ysm_ws->account( 'our test account' ), 'can set account' );
ok( $ysm_ws->endpoint( 'our test endpoint' ), 'can set endpoint' );
ok( $ysm_ws->use_wsse_security_headers( 'our test use_wsse_security_headers' ), 'can set use_wsse_security_headers' );
ok( $ysm_ws->use_location_service( 'our test use_location_service' ), 'can set use_location_service' );
ok( $ysm_ws->last_command_group( 'our test last_command_group' ), 'can set last_command_group' );
ok( $ysm_ws->remaining_quota( 'our test remaining_quota' ), 'can set remaining_quota' );
ok( $ysm_ws->uri( 'our test uri' ), 'can set uri' );


is( $ysm_ws->username, 'our test username', 'can get username' );
is( $ysm_ws->password, 'our test password', 'can get password' );
is( $ysm_ws->license, 'our test license', 'can get license' );
is( $ysm_ws->master_account, 'our test master_account', 'can get master_account' );
is( $ysm_ws->account, 'our test account', 'can get account' );
is( $ysm_ws->endpoint, 'our test endpoint', 'can get endpoint' );
is( $ysm_ws->use_wsse_security_headers, 'our test use_wsse_security_headers', 'can get use_wsse_security_headers' );
is( $ysm_ws->use_location_service, 'our test use_location_service', 'can get use_location_service' );
is( $ysm_ws->last_command_group, 'our test last_command_group', 'can get last_command_group' );
is( $ysm_ws->remaining_quota, 'our test remaining_quota', 'can get remaining_quota' );
is( $ysm_ws->uri, 'our test uri', 'can get uri' );


my $ysm_ws2 = Yahoo::Marketing::Service->new( use_wsse_security_headers => 0,
                                              use_location_service      => undef,
                                              version                   => 'V7',
                                              uri                       => 'http://foo.bar',
                                              cache_expire_time         => '2 weeks',
                                              cache                     => Cache::SizeAwareFileCache->new,
                                             );

is( $ysm_ws2->use_wsse_security_headers, 0,     'can set use_wsse_security_headers in new' );
is( $ysm_ws2->use_location_service,      undef, 'can set use_location_service in new' );
is( $ysm_ws2->version, 'V7', 'can set version in new' );
is( $ysm_ws2->uri, 'http://foo.bar', 'can set uri in new' );
is( $ysm_ws2->cache_expire_time, '2 weeks', 'can set cache expire time in new' );
is( ref $ysm_ws2->cache, 'Cache::SizeAwareFileCache', 'can set cache in new' );

