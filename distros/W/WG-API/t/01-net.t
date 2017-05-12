#!/usr/bin/env perl
#

use v5.014;
use strict;
use warnings;
use lib ( 'lib' );

use Test::More;

BEGIN: {
    use_ok( 'WG::API::NET'              || say "WG::API::NET loaded" );
}

my $wg = WG::API::NET->new( application_id => 'demo' );
ok( $wg && ref $wg, 'create class' );

can_ok( $wg, qw/servers_info/ );
can_ok( $wg, qw/accounts_list account_info/ );
can_ok( $wg, qw/clans_list clans_info clans_membersinfo clans_glossary clans_messageboard/ );

SKIP: {
    skip 'developers only', 8 unless $ENV{ 'WGMODE' } && $ENV{ 'WGMODE' } eq 'dev';

    ok( $wg->servers_info, 'get servers info without params' );
    ok( $wg->servers_info( game => 'wot' ), 'get servers info with params' );
    ok( $wg->servers_info( game => 'wot', fields => 'server' ), 'get servers info with params' );
    ok( $wg->servers_info( game => 'wot', fields => 'server, players_online' ), 'get servers info with params' );
    ok( $wg->servers_info( fields => 'server, players_online' ), 'get servers info with params' );
    ok( $wg->servers_info( fields => 'server' ), 'get servers info with params' );
    ok( ! $wg->servers_info( fields => 'sever' ), 'get servers info with invalid params' );
    ok( $wg->error, 'error with invalid field name' );
};

done_testing();
