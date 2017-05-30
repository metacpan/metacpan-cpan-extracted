#!/usr/bin/env perl
#

use v5.014;
use strict;
use warnings;
use lib ( 'lib' );

use WG::API;

use Test::More;

my $wg = WG::API->new( application_id => $ENV{ 'WG_KEY' } || 'demo' );
ok( $wg && ref $wg, 'create class' );
ok( $wg = $wg->net, 'get WG::API::NET instance');
isa_ok( $wg, 'WG::API::NET', 'valid instance');

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

    #accounts
    my $accounts;
    is( $accounts = $wg->accounts_list( game => 'wot' ), undef, 'Get accounts without search field' );
    is( $wg->error->code, '997', 'get error' );
    ok( $accounts = $wg->accounts_list( search => 'test' ), 'Search accounts' );
    is( $wg->error, undef, 'search accounts without errors' );
    
    my $account_ref;
    ok( $account_ref = $wg->account_info( account_id => $accounts->[0]->{'account_id'} ), 'Get account info' );
    is( $wg->error, undef, 'Get account info without errors' );
    my ($account_id) = keys %$account_ref;
    like( $account_ref->{$account_id}->{nickname}, qr/test/i, 'Verified account' );
    
    is( $wg->account_info( account_id => undef ), undef, 'Get account info without account_id' );
    is( $wg->account_info( account_id => 'test' ), undef, 'Get account info with invalid account_id' );

    #clans
    my ($clans, $clan_info);
    is( $clans = $wg->clans_list( game => 'wox', search => 'hellenes' ), undef, 'Search clan with invalid game' );
    is( $wg->clans_info( clan_id => 'clan_id' ), undef, 'Get clan info with invalid clan_id' );

    ok( $clans = $wg->clans_list( game => 'wot', search => 'hellenes' ), 'Search clan with valid params' );
    ok( $clan_info = $wg->clans_info( clan_id => $clans->[0]->{clan_id} ), 'Get clan info' );

    my ($clan_id) = keys %$clan_info;
    ok( $wg->clans_membersinfo( account_id => $clan_info->{$clan_id}->{members}->[0]->{account_id} ), 'Get member info with valid account_id' );
    is( $wg->clans_membersinfo( account_id => 'xxx' ), undef, 'Get member info with invalid account_id' );

    ok( $wg->clans_glossary( game => 'wot' ), 'Get clans glossary with valid game' );
    is( $wg->clans_glossary( game => 'xxx' ), undef, 'Get clans glossary with invalid game' );

    is( $wg->clans_messageboard( game => 'wot' ), undef, 'Get clan messageboard without access token' );
};

done_testing();
