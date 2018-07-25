#!/usr/bin/env perl

use Modern::Perl '2015';

use WG::API;

use Log::Any::Test;
use Log::Any qw($log);
use Test::More;

my $wot = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' )->wot;
isa_ok( $wot, 'WG::API::WoT' );

can_ok( $wot, qw/account_list account_info account_tanks account_achievements/ );
can_ok( $wot, qw/stronghold_claninfo stronghold_clanreserves/ );
can_ok(
    $wot, qw/encyclopedia_vehicles encyclopedia_vehicleprofile encyclopedia_achievements
        encyclopedia_info encyclopedia_arenas encyclopedia_provisions encyclopedia_personalmissions
        encyclopedia_boosters encyclopedia_vehicleprofiles encyclopedia_modules
        encyclopedia_badges encyclopedia_crewroles encyclopedia_crewskills
        /
);
can_ok( $wot, qw/clanratings_dates clanratings_dates clanratings_clans clanratings_neighbors clanratings_top/ );
can_ok( $wot, qw/tanks_stats tanks_achievements/ );

SKIP: {
    skip 'developers only', 14 unless $ENV{'WGMODE'} && $ENV{'WGMODE'} eq 'dev';

    subtest 'accounts' => sub {
        ok( !$wot->account_list, 'get account list without params' );
        ok( $wot->account_list( search => 'test' ), 'get account list with params' );
        ok( !$wot->account_info, 'get account info without params' );
        ok( $wot->account_info( account_id => '244468' ), 'get account info with params' );
        ok( !$wot->account_tanks, 'get account tanks without params' );
        ok( $wot->account_tanks( account_id => '244468' ), 'get account tanks with params' );
        ok( !$wot->account_achievements, 'get account achievements without params' );
        ok( $wot->account_achievements( account_id => '244468' ), 'get account achievements with params' );
    };

    subtest 'strongholds' => sub {
        ok( !$wot->stronghold_claninfo, "can't get stronghold claninfo wo required fields" );
        ok( $wot->stronghold_claninfo( clan_id => _get_clan()->{clan_id} ), "get stronghold claninfo" );
        ok( !$wot->stronghold_clanreserves, "can't get stronghold clanreserves wo required fields" );
    };

    subtest 'encyclopedia' => sub {
        my $tanks;
        ok( $tanks = $wot->encyclopedia_vehicles( limit => 1 ), "get information about available vehicles" );

        my ($tank_id) = keys %$tanks;
        is( $wot->encyclopedia_vehicleprofile(), undef, "get vehicle configuration characteristics wo tank_id" );
        is( $wot->encyclopedia_vehicleprofile( tank_id => 'XXX' ), undef, "get vehicle configuration w invalid tank_id" );
        ok( $wot->encyclopedia_vehicleprofile( tank_id => $tank_id ), "get vehicle configuration w valid tank id" );

        ok( $wot->encyclopedia_achievements(),     "get information about achievements" );
        ok( $wot->encyclopedia_info(),             "get information about tankopedia" );
        ok( $wot->encyclopedia_arenas(),           "get information about maps" );
        ok( $wot->encyclopedia_provisions(),       "get information about available equipment" );
        ok( $wot->encyclopedia_personalmissions(), "get information about personal missions" );
        ok( $wot->encyclopedia_boosters(),         "get information about personal reserves" );

        is( $wot->encyclopedia_vehicleprofiles(), undef, "get information about vehicle configurations wo tank id" );
        is( $wot->encyclopedia_vehicleprofiles( tank_id => 'XXX' ), undef, "get information about vehicle configurations w invalid tank id" );
        ok( $wot->encyclopedia_vehicleprofiles( tank_id => $tank_id ), "get information about vehicle configurations w valid tank id" );

        ok( $wot->encyclopedia_modules(),    "get information about available modules" );
        ok( $wot->encyclopedia_badges(),     "get information about available badgets" );
        ok( $wot->encyclopedia_crewroles(),  "get full description of all crew qualifications" );
        ok( $wot->encyclopedia_crewskills(), "get full description of all crew skills" );
    };

    subtest 'clan ratings' => sub {
        ok( $wot->clanratings_types,  "get clan ratings types" );
        ok( $wot->clanratings_dates,  "get clan ratings dates" );
        ok( !$wot->clanratings_clans, "can't get clan ratings wo required fields" );

        my $clan = _get_clan();
        ok( $wot->clanratings_clans( clan_id => $clan->{clan_id} ), "get clan ratings clan" );

        my $type = $wot->clanratings_types();
        ok( !$wot->clanratings_neighbors, "can't get clan ratings neighbors wo required fields" );
        ok( $wot->clanratings_neighbors( clan_id => $clan->{clan_id}, rank_field => $type->{all}->{rank_fields}->[0] ), "get clan ratings neighbors" );

        ok( !$wot->clanratings_top, "can't get clan ratings top wo required fields" );
        ok( $wot->clanratings_top( rank_field => $type->{all}->{rank_fields}->[0] ), "get clan ratings top" );
    };

    subtest 'tanks' => sub {
        ok( !$wot->tanks_stats, 'get tanks stats without params' );
        ok( !$wot->tanks_stats( account_id => 'xxx' ), 'get tanks stats with invalid params' );
        ok( $wot->tanks_stats( account_id => '244468' ), 'get tanks stats with valid params' );
        ok( !$wot->tanks_achievements, 'get tanks achievements without params' );
        ok( !$wot->tanks_achievements( account_id => 'xxx' ), 'get tanks achievements with invalid params' );
        ok( $wot->tanks_achievements( account_id => '244468' ), 'get tanks achievements with valid params' );
    };
}

$wot->set_debug(1);
$wot->account_info( account_id => '123' );
$log->contains_ok( qr/METHOD GET/, 'params for GET request logged' );

done_testing();

sub _get_clan {
    my $net = WG::API->new( application_id => $ENV{'WG_KEY'} )->net;
    return $net->clans( limit => 1, fields => 'clan_id' )->[0];
}

sub _get_account {
    return $wot->account_list( search => 'test' )->[0];
}
