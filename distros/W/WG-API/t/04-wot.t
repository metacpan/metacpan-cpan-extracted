#!/usr/bin/env perl

use Modern::Perl '2015';
use lib ('lib');

use WG::API;

use Log::Any::Test;
use Log::Any qw($log);
use Test::More;

my WG::API::WoT $wot = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' )->wot;
isa_ok( $wot, 'WG::API::WoT' );

can_ok( $wot, qw/account_list account_info account_tanks account_achievements/ );
can_ok( $wot, qw/ratings_types ratings_dates ratings_accounts ratings_neighbors ratings_top/ );
can_ok( $wot, qw/tanks_stats tanks_achievements/ );

SKIP: {
    skip 'developers only', 26 unless $ENV{'WGMODE'} && $ENV{'WGMODE'} eq 'dev';

    #accounts
    ok( !$wot->account_list, 'get account list without params' );
    ok( $wot->account_list( search => 'test' ), 'get account list with params' );
    ok( !$wot->account_info, 'get account info without params' );
    ok( $wot->account_info( account_id => '244468' ), 'get account info with params' );
    ok( !$wot->account_tanks, 'get account tanks without params' );
    ok( $wot->account_tanks( account_id => '244468' ), 'get account tanks with params' );
    ok( !$wot->account_achievements, 'get account achievements without params' );
    ok( $wot->account_achievements( account_id => '244468' ), 'get account achievements with params' );

    #ratings
    ok( $wot->ratings_types,  'get ratings types without params' );
    ok( !$wot->ratings_dates, 'get ratings dates without params' );
    ok( $wot->ratings_dates( type => 'all' ), 'get ratings dates with params' );
    ok( !$wot->ratings_accounts, 'get ratings account without params' );
    ok( !$wot->ratings_accounts( account_id => 'xxx', type => 1 ), 'get ratings account with invalid params' );
    ok( $wot->ratings_accounts( account_id => '244468', type => 1 ), 'get ratings account with valit params' );
    ok( !$wot->ratings_neighbors, 'get list of adjacent positions in specified rating without params' );
    ok( !$wot->ratings_neighbors( account_id => 'xxx', type => 'all', rank_field => 'damage_dealt' ),
        'get list of adjacent positions in specified rating with invalid params' );
    ok( $wot->ratings_neighbors( account_id => '244468', type => 'all', rank_field => 'damage_dealt' ),
        'get list of adjacent positions in specified rating with valid params' );
    ok( !$wot->ratings_top, 'get ratings top without params' );
    ok( !$wot->ratings_top( type => 'xxx', rank_field => 'damage_dealt' ), 'get ratings top with invalid params' );
    ok( $wot->ratings_top( type => 'all', rank_field => 'damage_dealt' ), 'get ratings top with valid params' );

    #tanks
    ok( !$wot->tanks_stats, 'get tanks stats without params' );
    ok( !$wot->tanks_stats( account_id => 'xxx' ), 'get tanks stats with invalid params' );
    ok( $wot->tanks_stats( account_id => '244468' ), 'get tanks stats with valid params' );
    ok( !$wot->tanks_achievements, 'get tanks achievements without params' );
    ok( !$wot->tanks_achievements( account_id => 'xxx' ), 'get tanks achievements with invalid params' );
    ok( $wot->tanks_achievements( account_id => '244468' ), 'get tanks achievements with valid params' );
}

$wot->set_debug(1);
$wot->account_info( account_id => '123' );
$log->contains_ok( qr/METHOD GET/, 'params for GET request logged' );

done_testing();
