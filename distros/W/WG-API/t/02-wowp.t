#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use lib ('lib');
use Test::More;

BEGIN {
    use_ok( 'WG::API::WoWp' )               || say "WG::API::WoWp loaded";
}

my $wowp = WG::API::WoWp->new( application_id =>'demo' );
ok( $wowp && ref $wowp, 'create class' );

can_ok( $wowp, qw/account_list account_info account_planes/ );
can_ok( $wowp, qw/ratings_types ratings_accounts ratings_neighbors ratings_top ratings_dates/ );

SKIP: {
    skip 'developers only', 21  unless $ENV{ 'WGMODE' } && $ENV{ 'WGMODE' } eq 'dev';
    my $accounts;
    ok( ! $wowp->account_list,                                                                  'get accounts list without params' );
    ok(   $accounts = $wowp->account_list( search => 'test' ),                                  'get accounts list with params' );
    ok( ! $wowp->account_info,                                                                  'get account info without params' );
    ok(   $wowp->account_info( account_id => $accounts->[ 0 ]->{ 'account_id' } ),              'get account info with valid params' );
    ok( ! $wowp->account_info( account_id => 'xxx' ),                                           'get account info with invalid params' );
    ok( ! $wowp->account_planes,                                                                'get account planes without params' );
    ok(   $wowp->account_planes( account_id => $accounts->[ 0 ]->{ 'account_id' } ),            'get account planes with valid params' );
    ok( ! $wowp->account_planes( account_id => 'xxx' ),                                         'get account planes with invalid params' );

    ok(   $wowp->ratings_types,                                                                 'get ratings types' ); 
    ok( ! $wowp->ratings_accounts,                                                              'get account rating without params' );
    ok( ! $wowp->ratings_accounts( type => 1, account_id => 'xxx' ),                            'get account rating with invalid params' );
    ok(   $wowp->ratings_accounts( 
            type => 1, account_id => '19580656' ),                                              'get account rating without params' );
    ok( ! $wowp->ratings_neighbors,                                                             'get rating neighbors without params');
    ok( ! $wowp->ratings_neighbors( 
            type => 1, account_id => 'xxx', rank_field => 'battles_count'),                     'get rating neighbors with invalid params');
    ok(   $wowp->ratings_neighbors(
            type => 1, account_id => '19580656', rank_field => 'battles_count'),                'get rating neighbors with valid params');
    ok( ! $wowp->ratings_top,                                                                   'get rating top without params' );
    ok( ! $wowp->ratings_top( type => '1', rank_field => 'xxx' ),                               'get rating top for invalid rank field' );
    ok(   $wowp->ratings_top( type => '1', rank_field => 'battles_count' ),                     'get rating top for valid rank field' );
    ok( ! $wowp->ratings_dates,                                                                 'get rating dates without rating type' );
    ok( ! $wowp->ratings_dates( type => 'xxx' ),                                                'get rating dates with invalid rating type' );
    ok(   $wowp->ratings_dates( type => '1' ),                                                  'get rating dates with valid rating type' );
};

done_testing();
