#!/usr/bin/env perl

use Modern::Perl '2015';

use WG::API;

use Test::More;

my $wows = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' )->wows();
isa_ok( $wows, 'WG::API::WoWs' );

can_ok( $wows, qw/account_list account_info account_achievements/ );
can_ok( $wows, qw/ships_stats/ );

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
}

done_testing();
