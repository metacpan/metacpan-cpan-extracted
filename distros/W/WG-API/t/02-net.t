#!/usr/bin/env perl

use Modern::Perl '2015';

use WG::API;

use Test::More;

my $net = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' )->net();
isa_ok( $net, 'WG::API::NET', 'valid instance' );

can_ok( $net, qw/servers_info/ );
can_ok( $net, qw/accounts_list account_info/ );
can_ok( $net, qw/clans_info clans_membersinfo clans_glossary clans_messageboard/ );

SKIP: {
    skip 'developers only', 26 unless $ENV{'WGMODE'} && $ENV{'WGMODE'} eq 'dev';

    subtest 'servers info' => sub {
        ok( $net->servers_info, 'get servers info without params' );
        ok( $net->servers_info( game => 'wot' ), 'get servers info with params' );
        ok( $net->servers_info( game => 'wot', fields => 'server' ), 'get servers info with params' );
        ok( $net->servers_info( game => 'wot', fields => 'server, players_online' ), 'get servers info with params' );
        ok( $net->servers_info( fields => 'server, players_online' ), 'get servers info with params' );
        ok( $net->servers_info( fields => 'server' ), 'get servers info with params' );
        ok( !$net->servers_info( fields => 'sever' ), 'get servers info with invalid params' );
        ok( $net->error, 'error with invalid field name' );
    };

    subtest 'accounts' => sub {
        my $accounts;
        is( $accounts = $net->accounts_list( game => 'wot' ), undef, 'Get accounts without search field' );
        is( $net->error->code, '997', 'get error' );
        ok( $accounts = $net->accounts_list( search => 'test' ), 'Search accounts' );
        is( $net->error, undef, 'search accounts without errors' );

        my $account_ref;
        ok( $account_ref = $net->account_info( account_id => $accounts->[0]->{'account_id'} ), 'Get account info' );
        is( $net->error, undef, 'Get account info without errors' );
        my ($account_id) = keys %$account_ref;
        like( $account_ref->{$account_id}->{nickname}, qr/test/i, 'Verified account' );

        is( $net->account_info( account_id => undef ),  undef, 'Get account info without account_id' );
        is( $net->account_info( account_id => 'test' ), undef, 'Get account info with invalid account_id' );

    };

    subtest 'clans' => sub {
        my ( $clans, $clan_info );
        is( $clans = $net->clans( game => 'wox', search => 'hellenes' ), undef, 'Search clan with invalid game' );
        is( $net->clans_info( clan_id => 'clan_id' ), undef, 'Get clan info with invalid clan_id' );

        ok( $clans = $net->clans( game => 'wot', search => 'hellenes' ), 'Search clan with valid params' );
        ok( $clan_info = $net->clans_info( clan_id => $clans->[0]->{clan_id} ), 'Get clan info' );

        my ($clan_id) = keys %$clan_info;
        ok( $net->clans_membersinfo( account_id => $clan_info->{$clan_id}->{members}->[0]->{account_id} ), 'Get member info with valid account_id' );
        is( $net->clans_membersinfo( account_id => 'xxx' ), undef, 'Get member info with invalid account_id' );

        ok( $net->clans_glossary( game => 'wot' ), 'Get clans glossary with valid game' );
        is( $net->clans_glossary( game => 'xxx' ), undef, 'Get clans glossary with invalid game' );

        is( $net->clans_messageboard( game => 'wot' ), undef, 'Get clan messageboard without access token' );

        isnt( $net->clans_memberhistory( account_id => $clan_info->{$clan_id}->{members}->[0]->{account_id} ), undef, 'Get clan members history with valid accout_id' );
    };
}

done_testing();
