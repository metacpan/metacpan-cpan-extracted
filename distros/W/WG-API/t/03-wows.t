#!/usr/bin/env perl

use Modern::Perl '2015';

use WG::API;

use Test::More;
use Test::Exception;

my $wows = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' )->wows();
isa_ok( $wows, 'WG::API::WoWs' );

can_ok( $wows, qw/account_list account_info account_achievements/ );
can_ok( $wows, qw/ships_stats/ );
can_ok( $wows, qw/seasons_info seasons_shipstats seasons_accountinfo/ );
can_ok( $wows, qw/clans clans_details clans_accountinfo clans_glossary clans_season/ );

SKIP: {
    skip 'developers only', 8 unless $ENV{'WGMODE'} && $ENV{'WGMODE'} eq 'dev';

    subtest 'accounts' => sub {
        my $accounts;
        is( $wows->account_list, undef, 'account list without params' );
        ok( $accounts = $wows->account_list( search => 'test' ), 'account list with params' );
        is( $wows->account_info, undef, 'account info without params' );
        is( $wows->account_info( account_id => 'xxx' ), undef, 'account info with invalid params' );
        ok( $wows->account_info( account_id => $accounts->[0]->{'account_id'} ), 'account info with valid params' );

        is( $wows->account_achievements, undef, 'account achievements without params' );
        is( $wows->account_achievements( account_id => 'xxx' ), undef, 'account achievements with invalid params' );
        ok( $wows->account_achievements( account_id => $accounts->[0]->{'account_id'} ), 'account achievements with valid params' );

        isnt( $wows->account_statsbydate( account_id => $accounts->[0]->{account_id} ), undef, 'account stats by date with valid params' );
    };

    subtest 'ships' => sub {
        my $accounts = $wows->account_list( search => 'test' );
        ok( $wows->ships_stats( account_id => $accounts->[0]->{account_id} ), 'Get ships info for valid account_id' );
        is( $wows->ships_stats( account_id => 'xxx' ), undef, 'Get ships info for invalid account_id' );
    };

    subtest 'seasons' => sub {
        lives_ok { $wows->seasons_info } "Get seasons info";

        my $clans = $wows->clans( limit => 1 );
        my $clan = $wows->clans_details( clan_id => $clans->[0]->{clan_id} )->{ $clans->[0]->{clan_id} };
        ok( !$wows->seasons_shipstats, "Can't get seasons_shipstats wo required fields" );
        ok( $wows->seasons_shipstats( account_id => $clan->{members_ids}->[0] ), "Get seasons_shipstats" );

        ok( !$wows->seasons_accountinfo, "Ca;n get seasons accountinfo wo required feilds" );
        ok( $wows->seasons_accountinfo( account_id => $clan->{members_ids}->[0] ), "Get seasons accountinfo" );
    };

    subtest 'clans' => sub {
        my $clans;
        lives_ok { $clans = $wows->clans( limit => 1 ) } "Get clan list";
        ok( @$clans, "clans list is not empty" );

        my $clan;
        ok( !$wows->clans_details(), "Can't get clan details wo required fields" );
        lives_ok { $clan = $wows->clans_details( clan_id => $clans->[0]->{clan_id} )->{ $clans->[0]->{clan_id} } } "Get clans details";

        ok( !$wows->clans_accountinfo(), "Can't get clan account info wo required fields" );
        ok( $wows->clans_accountinfo( account_id => $clan->{members_ids}->[0] ), "Get clans account info" );

        lives_ok { $wows->clans_glossary } "Get clans glossay";

        lives_ok { $wows->clans_season } "Get clans season";
    };
}

done_testing();
