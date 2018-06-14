#!/usr/bin/env perl

use Modern::Perl '2015';

use WG::API;

use Test::More;

my $wowp = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' )->wowp;
ok( $wowp && ref $wowp, 'create class' );
isa_ok( $wowp, 'WG::API::WoWp' );

can_ok( $wowp, qw/account_list account_info account_planes/ );
can_ok( $wowp, qw/ratings_types ratings_accounts ratings_neighbors ratings_top ratings_dates/ );

SKIP: {
    skip 'developers only', 21 unless $ENV{'WGMODE'} && $ENV{'WGMODE'} eq 'dev';

    subtest 'account' => sub {
        my $accounts;
        is( $wowp->account_list, undef, 'get accounts list without params' );
        ok( $accounts = $wowp->account_list( search => 'test' ), 'get accounts list with params' );
        is( $wowp->account_info, undef, 'get account info without params' );
        ok( $wowp->account_info( account_id => $accounts->[0]->{'account_id'} ), 'get account info with valid params' );
        is( $wowp->account_info( account_id => 'xxx' ), undef, 'get account info with invalid params' );

        is( $wowp->account_planes, undef, 'get account planes without params' );
        ok( $wowp->account_planes( account_id => $accounts->[0]->{'account_id'} ), 'get account planes with valid params' );
        is( $wowp->account_planes( account_id => 'xxx' ), undef, 'get account planes with invalid params' );
    };

    subtest 'ratings' => sub {
        my $accounts = $wowp->account_list( search => 'test' );

        is( $wowp->ratings_top, undef, 'get rating top without params' );
        is( $wowp->ratings_top( type => '1', rank_field => 'xxx' ), undef, 'get rating top for invalid rank field' );
        ok( $accounts = $wowp->ratings_top( type => '1', rank_field => 'battles_count' ), 'get rating top for valid rank field' );
        is( ref $accounts, 'ARRAY', 'get real top list' );

        ok( $wowp->ratings_types, 'get ratings types' );

        is( $wowp->ratings_accounts, undef, 'get account rating without params' );
        is( $wowp->ratings_accounts( type => 1, account_id => 'xxx' ), undef, 'get account rating with invalid params' );
        ok( $wowp->ratings_accounts( type => 1, account_id => $accounts->[0]->{'account_id'} ), 'get account rating without params' );

        is( $wowp->ratings_neighbors, undef, 'get rating neighbors without params' );
        is( $wowp->ratings_neighbors( type => 1, account_id => 'xxx', rank_field => 'battles_count' ), undef, 'get rating neighbors with invalid params' );
        ok( $wowp->ratings_neighbors( type => 1, account_id => $accounts->[1]->{'account_id'}, rank_field => 'battles_count', ), 'get rating neighbors with valid params' );

        is( $wowp->ratings_dates, undef, 'get rating dates without rating type' );
        is( $wowp->ratings_dates( type => 'xxx' ), undef, 'get rating dates with invalid rating type' );
        ok( $wowp->ratings_dates( type => '1' ), 'get rating dates with valid rating type' );
    };
}

done_testing();
