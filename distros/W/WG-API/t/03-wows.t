#!/usr/bin/env perl
#
#

use 5.014;
use warnings;
use lib ( 'lib' );
use Test::More;

BEGIN {
    use_ok( 'WG::API::WoWs' || say 'WG::API::WoWs loaded' );
}

#my $wows = WG::API::WoWs->new( application_id => 'demo' );
my $wows = WG::API::WoWs->new( application_id => 'd7b121cb9253f4e609b6ef258e8203f6' );
ok( $wows && ref $wows, 'create class' );

can_ok( $wows, qw/account_list account_info account_achievements/ );
can_ok( $wows, qw/ships_stats/ );

SKIP: {
    skip 'developers only', 8 unless $ENV{ 'WGMODE' } && $ENV{ 'WGMODE' } eq 'dev';
    my $accounts;
    ok( ! $wows->account_list, 'account list without params' );
    ok(   $accounts = $wows->account_list( search => 'test' ), 'account list with params' );
    ok( ! $wows->account_info, 'account info without params' );
    ok( ! $wows->account_info( account_id => 'xxx' ), 'account info with invalid params' );
    ok(   $wows->account_info( account_id => $accounts->[ 0 ]->{ 'account_id' } ), 'account info with valid params' );

    ok( ! $wows->account_achievements, 'account achievements without params' );
    ok( ! $wows->account_achievements( account_id => 'xxx' ), 'account achievements with invalid params' );
    ok(   $wows->account_achievements( account_id => $accounts->[ 0 ]->{ 'account_id' } ), 'account achievements with valid params' );
};

done_testing();
