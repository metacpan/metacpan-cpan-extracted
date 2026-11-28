use strict;
use warnings;
use Test::More;

my $class = 'Web::Session::Redis';

# Lemonldap::NG purge calls them on the backend module itself
SKIP: {
    skip 'Redis module is needed', 2 unless eval "require $class";
    ok( $class->can('searchLt'), 'Redis: searchLt' );
    ok( $class->can('searchGt'), 'Redis: searchGt' );
}

SKIP: {
    skip 'Set REDIS_URL to run Redis tests', 1 unless $ENV{REDIS_URL};
    skip 'Redis module is needed',           1 unless eval "require $class";

    # _oidcRtUpdate is indexed, rt is not: both hold the same values. Not the
    # database of the other Redis tests, to run them in parallel
    my $args = {
        server   => $ENV{REDIS_URL},
        database => ( ( $ENV{REDIS_DBNUM} || 15 ) + 15 ) % 16,
        Index    => '_session_kind _oidcRtUpdate uid',
        backend  => $class,
    };
    my $redis = $class->_getRedis($args);
    $redis->flushdb;

    my $latin = "\x{c9}lodie";
    my %ids;
    my %data = (
        s1  => { v => 100, cn => $latin, uid => "\x{e9}ric" },
        s2  => { v => 200, cn => "\x{c3}\x{a9}" },
        s3  => { v => 300 },
        s4  => { v => 150.5 },
        s5  => { v => -50 },
        sp  => { v => ' 42 ' },
        abc => { v => 'abc' },
        emp => { v => '' },
        inf => { v => 'Inf' },
        exp => { v => '1e1' },
        but => { v => '0 but true' },
        no  => {},
    );
    foreach my $s ( sort keys %data ) {
        my %session;
        tie %session, $class, undef, $args;
        $session{uid} = $data{$s}->{uid} // $s;
        $session{cn}  = $data{$s}->{cn}  // $s;
        if ( exists $data{$s}->{v} ) {
            $session{_oidcRtUpdate} = $data{$s}->{v};
            $session{rt}            = $data{$s}->{v};
        }
        $ids{ $session{_session_id} } = $s;
        untie %session;
    }

    my $names = sub {
        [ sort map { $ids{$_} } keys %{ $_[0] } ]
    };

    foreach my $field (qw(_oidcRtUpdate rt)) {
        my $desc  = $field eq 'rt' ? 'not indexed' : 'indexed';
        my @tests = (
            [ searchLt => 200,       [qw(s1 s4 s5 sp)] ],
            [ searchGt => 200,       ['s3'] ],
            [ searchLt => 100,       [qw(s5 sp)] ],
            [ searchGt => 300,       [] ],
            [ searchLt => 150.5,     [qw(s1 s5 sp)] ],
            [ searchGt => -1,        [qw(s1 s2 s3 s4 sp)] ],
            [ searchLt => 1000,      [qw(s1 s2 s3 s4 s5 sp)] ],
            [ searchLt => 0,         ['s5'] ],
            [ searchLt => ' 123 ',   [qw(s1 s5 sp)] ],
            [ searchGt => '  250  ', ['s3'] ],
        );
        foreach (@tests) {
            my ( $m, $v, $expect ) = @$_;
            is_deeply( $names->( $class->$m( $args, $field, $v ) ),
                $expect, "$desc: $m '$v'" );
        }

        # Whole sessions or requested fields, non-ASCII values unchanged
        my $res   = $class->searchLt( $args, $field, 250 );
        my ($id1) = grep { $ids{$_} eq 's1' } keys %$res;
        my ($id2) = grep { $ids{$_} eq 's2' } keys %$res;
        is( $res->{$id1}->{_session_id}, $id1,        "$desc: whole session" );
        is( $res->{$id1}->{cn},          $latin,      "$desc: Latin-1 value" );
        is( $res->{$id1}->{uid},         "\x{e9}ric", "$desc: Latin-1 uid" );
        is( $res->{$id2}->{cn},          "\x{c3}\x{a9}", "$desc: UTF-8 bytes" );
        $res = $class->searchGt( $args, $field, 50, 'cn', $field );
        is_deeply(
            $res->{$id1},
            { cn => $latin, $field => 100 },
            "$desc: requested fields only"
        );
        is( keys %$res, 4, "$desc: searchGt with fields" );

        # Invalid values: nothing returned, no die
        my @bad = ( '1 OR 1=1', '1e3', '', 'abc', ' ', '1 2', '1.', undef );
        foreach my $bad (@bad) {
            my $err = '';
            {
                local *STDERR;
                open STDERR, '>', \$err;
                $res = eval { $class->searchLt( $args, $field, $bad ) };
            }
            my $l = defined($bad) ? "'$bad'" : 'undef';
            is_deeply( $res, {}, "$desc: $l returns nothing" );
            like(
                $err,
                qr/^searchLt: value must be a number/,
                "$desc: $l warns"
            );
        }
        my $err = '';
        {
            local *STDERR;
            open STDERR, '>', \$err;
            $res = $class->searchGt( $args, $field, 'x' );
        }
        is_deeply( $res, {}, "$desc: searchGt invalid value" );
        like(
            $err,
            qr/^searchGt: value must be a number/,
            "$desc: searchGt warns"
        );
    }

    # Indexed field: sessions are not all read
    {
        no warnings qw(redefine once);
        local *Web::Session::Redis::get_key_from_all_sessions =
          sub { die "full scan\n" };
        is_deeply( $names->( $class->searchLt( $args, '_oidcRtUpdate', 200 ) ),
            [qw(s1 s4 s5 sp)], 'indexed: no full scan' );
    }

    # Stale index entries: the session value is checked, orphans are removed
    my ($id3) = grep { $ids{$_} eq 's3' } keys %ids;
    my $orphan = 'f' x 64;
    $redis->sadd( '_oidcRtUpdate_10', $id3, $orphan );
    is_deeply( $names->( $class->searchLt( $args, '_oidcRtUpdate', 20 ) ),
        ['s5'], 'indexed: stale index entry ignored' );
    ok( !$redis->sismember( '_oidcRtUpdate_10', $orphan ),
        'indexed: orphan removed from index' );
    $redis->del('_oidcRtUpdate_10');

    # Keys that may belong to another application are neither read nor
    # removed from index sets
    $redis->sadd( 'uid_1', 'otherapp:member', 'cart:42' );
    is_deeply( $class->searchLt( $args, 'uid', 10 ),
        {}, 'foreign members: nothing returned' );
    is_deeply(
        [ sort $redis->smembers('uid_1') ],
        [ 'cart:42', 'otherapp:member' ],
        'foreign members: kept'
    );

    # Wrong types: skipped, a key that isn't a string stays in the index
    my ( $hashKey, $junk ) = ( 'e' x 64, 'd' x 64 );
    $redis->hset( $hashKey, a => 'b' );
    $redis->set( $junk, 'not a session' );
    $redis->sadd( '_oidcRtUpdate_5', $hashKey, $junk );
    $redis->set( '_oidcRtUpdate_6', 'not a set' );
    {
        my $err = '';
        my $res;
        {
            local *STDERR;
            open STDERR, '>', \$err;
            $res = eval { $class->searchLt( $args, '_oidcRtUpdate', 10 ) };
        }
        is( $@, '', 'wrong types: no die' );
        is_deeply( $names->($res), ['s5'], 'wrong types: skipped' );
        like( $err, qr/^Error in session $junk/, 'wrong types: bad session' );
        ok( $redis->sismember( '_oidcRtUpdate_5', $hashKey ),
            'wrong types: hash kept in index' );
    }
    $redis->del( $hashKey, $junk, '_oidcRtUpdate_5', '_oidcRtUpdate_6' );

    # Sets of other fields sharing the prefix or matching the glob pattern
    # aren't read: their orphan members would be removed
    my $args2 = { %$args, Index => 'x x_y f* fz' };
    my %cid;
    foreach (
        [ xs  => x    => 3 ],
        [ xys => x_y  => 5 ],
        [ fs  => 'f*' => 3 ],
        [ fzs => fz   => 5 ]
      )
    {
        my %session;
        tie %session, $class, undef, $args2;
        $session{ $_->[1] } = $_->[2];
        $cid{ $session{_session_id} } = $_->[0];
        untie %session;
    }
    $redis->sadd( $_, $orphan ) foreach (qw(x_y_5 fz_5));
    foreach ( [ x => 'xs', 'x_y_5' ], [ 'f*' => 'fs', 'fz_5' ] ) {
        my ( $f, $expect, $other ) = @$_;
        my $res = $class->searchLt( $args2, $f, 10 );
        is_deeply( [ map { $cid{$_} } keys %$res ],
            [$expect], "$f: own sessions only" );
        ok( $redis->sismember( $other, $orphan ), "$f: $other not read" );
    }
    $redis->del( keys %cid );

    # Like Lemonldap::NG::Common::Session::Purge
    my $now = time;
    my %rt;
    foreach ( [ old => $now - 7200 ], [ recent => $now - 60 ] ) {
        my %session;
        tie %session, $class, undef, $args;
        $session{_session_kind}      = 'OIDCI';
        $session{_type}              = 'refresh_token';
        $session{client_id}          = 'rp';
        $session{_oidcRtUpdate}      = $_->[1];
        $rt{ $session{_session_id} } = $_->[0];
        untie %session;
    }
    my $rtSessions =
      $args->{backend}->searchLt( $args, '_oidcRtUpdate', $now - 3600 );

    # The old refresh token and all test sessions with a number
    is_deeply(
        [ sort map { $rt{$_} // $ids{$_} } keys %$rtSessions ],
        [qw(old s1 s2 s3 s4 s5 sp)],
        'purge: old RT found'
    );
    my ($old) = grep { $rt{$_} } keys %$rtSessions;
    is( $rtSessions->{$old}->{client_id},
        'rp', 'purge: whole session returned' );

    $redis->flushdb;
}

done_testing();
