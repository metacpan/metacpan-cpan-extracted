use strict;
use Test::More;

# searchLt() and searchGt() without database: SQL queries sent by each
# backend, fields compared in Perl
{

    package FakeDbh;
    sub new { bless {}, shift }

    sub quote {
        my ( $self, $s ) = @_;
        $s =~ s/'/''/g;
        return "'$s'";
    }

    # MariaDBJSON checks that Index columns are generated from a_session: all
    # the tested ones are
    sub prepare { return bless {}, 'FakeSth' }

    package FakeSth;

    # Arguments: table name, then the Index fields
    sub execute {
        my ( $self, $table, @fields ) = @_;
        $self->{fields} = \@fields;
        return 1;
    }

    sub fetchall_arrayref {
        return [ map { [ $_, "JSON_VALUE(a_session, '\$.$_')" ] }
              @{ $_[0]->{fields} } ];
    }
    sub finish { return 1 }
}

my $t     = 1700000000;
my $index = { Index => '_utime _oidcRtUpdate' };
my @tests = (
    [ 'PgJSON',    q{cast(a_session ->> '_oidcRtUpdate' as bigint)} ],
    [ 'Patroni',   q{cast(a_session ->> '_oidcRtUpdate' as bigint)} ],
    [ 'Postgres',  q{cast(a_session ->> '_oidcRtUpdate' as bigint)} ],
    [ 'MySQLJSON', q{cast(a_session->>'$._oidcRtUpdate' as UNSIGNED)} ],
    [ 'MySQL',     q{cast(a_session->>'$._oidcRtUpdate' as UNSIGNED)} ],
    [
        'MariaDBJSON',
        q{cast(JSON_VALUE(a_session, '$._oidcRtUpdate') as UNSIGNED)}
    ],
    [
        'MariaDB',
        q{cast(JSON_VALUE(a_session, '$._oidcRtUpdate') as UNSIGNED)}
    ],
    [ 'MariaDBJSON', '`_oidcRtUpdate`',                $index ],
    [ 'MariaDB',     '`_oidcRtUpdate`',                $index ],
    [ 'SQLite',      'cast(_oidcRtUpdate as integer)', $index ],
);

# Sessions returned by the mocked get_key_from_all_sessions()
my %sessions = (
    s1 => { _oidcRtUpdate => 100,   uid => 'a' },
    s2 => { _oidcRtUpdate => 200,   uid => 'b' },
    s3 => { _oidcRtUpdate => 'abc', uid => 'c' },
    s4 => { uid           => 'd' },
);

foreach (@tests) {
    my ( $backend, $expr, $args ) = @$_;
    $args ||= {};
    my $class = "Web::Session::$backend";
    my $desc  = $backend . ( $args->{Index} ? ' (indexed)' : '' );
  SKIP: {
        skip "$class can't be loaded", 12 unless ( eval "require $class" );
        my ( @queries, $scans );
        no strict 'refs';
        no warnings 'redefine';
        local *{"${class}::_classDbh"} = sub { FakeDbh->new };
        local *{"${class}::_query"}    = sub {
            my ( $c, @a ) = @_;
            shift @a
              while ( @a and !( ref( $a[0] ) eq 'HASH' and $a[0]->{query} ) );
            push @queries,
              [ $a[0]->{query}, @{ $a[0]->{values} }, '|', @a[ 1 .. $#a ] ];
            return {};
        };
        local *{"${class}::get_key_from_all_sessions"} = sub { $scans++; {} };

        foreach ( [ searchLt => '<' ], [ searchGt => '>' ] ) {
            my ( $m, $op ) = @$_;
            @queries = ();
            my $res = $class->$m( $args, '_oidcRtUpdate', $t, 'uid' );
            is_deeply( $res, {}, "$desc: $m returns query result" );
            is_deeply(
                \@queries,
                [ [ "$expr $op $t", '|', 'uid' ] ],
                "$desc: $m query"
            );
        }

        # Surrounding spaces are removed (the Lemonldap::NG CLI keeps them)
        @queries = ();
        $class->searchGt( $args, '_oidcRtUpdate', " $t \n" );
        is_deeply(
            \@queries,
            [ [ "$expr > $t", '|' ] ],
            "$desc: spaces around value removed"
        );

        # Values are checked before being inserted in queries
        @queries = ();
        foreach my $bad ( "$t OR 1=1", '1e3', '', ' ', undef,
            '1' x 21, '1.' . '1' x 21, '9' x 400 ) {
            local *STDERR;
            open STDERR, '>', \my $err;
            is_deeply( $class->searchLt( $args, '_oidcRtUpdate', $bad ),
                {}, "$desc: bad value returns nothing" );
        }
        is_deeply( \@queries, [], "$desc: bad values: no query" );
        ok( !$scans, "$desc: sessions not read" );
    }
}

# The SQL query fails (in PostgreSQL, the cast of a value that isn't an
# integer, for example): the error is printed and the sessions are compared
# in Perl, as the generic search of Lemonldap::NG does. Nothing if reading
# the sessions fails too
foreach (@tests) {
    my ( $backend, undef, $args ) = @$_;
    $args ||= {};
    my $class = "Web::Session::$backend";
    my $desc  = $backend . ( $args->{Index} ? ' (indexed)' : '' );
  SKIP: {
        skip "$class can't be loaded", 6 unless ( eval "require $class" );
        no strict 'refs';
        no warnings 'redefine';
        my $scanFails;
        local *{"${class}::_classDbh"} = sub { FakeDbh->new };
        local *{"${class}::_query"}    = sub { die "query failed\n" };
        local *{"${class}::get_key_from_all_sessions"} = sub {
            my ( $c, $args, $sub ) = @_;
            die "scan failed\n" if ($scanFails);
            $sub->( $sessions{$_}, $_ ) foreach ( sort keys %sessions );
            return {};
        };
        foreach ( [ searchLt => [qw(s1 s3)] ], [ searchGt => ['s2'] ] ) {
            my ( $m, $expected ) = @$_;
            my $err = '';
            my $res;
            {
                local *STDERR;
                open STDERR, '>', \$err;
                $res = $class->$m( $args, '_oidcRtUpdate', 150 );
            }
            is_deeply( [ sort keys %$res ],
                $expected, "$desc: failed $m query, compared in Perl" );
            is(
                $err,
                "$m: query failed\n$m: comparing all sessions in Perl instead\n",
                "$desc: failed $m query: errors printed"
            );
        }
        $scanFails = 1;
        my $err = '';
        my $res;
        {
            local *STDERR;
            open STDERR, '>', \$err;
            $res = $class->searchLt( $args, '_oidcRtUpdate', 150 );
        }
        is_deeply( $res, {}, "$desc: query and scan fail: nothing" );
        like(
            $err,
            qr/searchLt: scan failed\n\z/,
            "$desc: query and scan fail: errors printed"
        );
    }
}

# Perl comparison: "inf" and "nan" are 0 as in SQL, not Infinity and NaN
foreach my $backend (qw(SQLite Cassandra)) {
    my $class = "Web::Session::$backend";
    my $args  = $backend eq 'Cassandra' ? $index : {};
  SKIP: {
        skip "$class can't be loaded", 4 unless ( eval "require $class" );
        no strict 'refs';
        no warnings 'redefine';
        local *{"${class}::get_key_from_all_sessions"} = sub {
            my ( $c, $args, $sub ) = @_;
            $sub->( { n => $_ }, $_ ) foreach (qw(inf Infinity nan NaN 5));
            return {};
        };
        my $res = $class->searchLt( $args, 'n', 1 );
        is_deeply( [ sort keys %$res ],
            [qw(Infinity NaN inf nan)],
            "$backend: inf and nan are lower than 1" );
        $res = $class->searchGt( $args, 'n', -1 );
        is_deeply( [ sort keys %$res ],
            [qw(5 Infinity NaN inf nan)],
            "$backend: inf and nan are greater than -1" );
        $res = $class->searchGt( $args, 'n', 0 );
        is_deeply( [ sort keys %$res ],
            ['5'], "$backend: inf and nan are not greater than 0" );
        $res = $class->searchLt( $args, 'n', 0 );
        is_deeply( $res, {}, "$backend: inf and nan are not lower than 0" );
    }
}

# Column backends: fields not listed in Index are compared in Perl (always
# with Cassandra: CQL can't compare them). Sessions without the field are
# skipped; "abc" is 0 as in Perl
foreach my $backend (qw(SQLite Cassandra)) {
    my $class = "Web::Session::$backend";
    my $args  = $backend eq 'Cassandra' ? $index : {};
  SKIP: {
        skip "$class can't be loaded", 4 unless ( eval "require $class" );
        my $queries = 0;
        no strict 'refs';
        no warnings 'redefine';
        local *{"${class}::_query"}                    = sub { $queries++; {} };
        local *{"${class}::get_key_from_all_sessions"} = sub {
            my ( $c, $args, $sub ) = @_;
            $sub->( $sessions{$_}, $_ ) foreach ( sort keys %sessions );
            return {};
        };
        my $res = $class->searchLt( $args, '_oidcRtUpdate', 150 );
        is_deeply( [ sort keys %$res ],
            [qw(s1 s3)], "$backend: searchLt in Perl" );
        is_deeply( $res->{s1}, $sessions{s1}, "$backend: whole session" );
        $res = $class->searchGt( $args, '_oidcRtUpdate', -1, 'uid' );
        is_deeply(
            $res,
            {
                s1 => { uid => 'a' },
                s2 => { uid => 'b' },
                s3 => { uid => 'c' }
            },
            "$backend: searchGt in Perl, with fields"
        );
        is( $queries, 0, "$backend: no SQL comparison" );
    }
}

# Cassandra: as the other backends, a non numeric value returns nothing and
# prints an error instead of being compared as 0
SKIP: {
    my $class = 'Web::Session::Cassandra';
    skip "$class can't be loaded", 6 unless ( eval "require $class" );
    no strict 'refs';
    no warnings 'redefine';
    foreach my $m (qw(searchLt searchGt)) {
        my $scans = 0;
        local *{"${class}::get_key_from_all_sessions"} = sub { $scans++; {} };
        local *STDERR;
        open STDERR, '>', \my $err;
        my $res = $class->$m( $index, '_oidcRtUpdate', 'abc' );
        is_deeply( $res, {},
            "Cassandra: $m with a non numeric value returns nothing" );
        like( $err, qr/value must be a number/,
            "Cassandra: $m with a non numeric value prints an error" );
        is( $scans, 0, "Cassandra: $m with a non numeric value reads nothing" );
    }
}

# _buildCompareExpression() only accepts the operators it knows, in each
# backend
foreach my $backend ( 'Postgres', 'PgJSON', 'MySQL', 'MySQLJSON', 'MariaDB',
    'MariaDBJSON', 'SQLite', 'Patroni' )
{
    my $class = "Web::Session::$backend";
  SKIP: {
        skip "$class can't be loaded", 4 unless ( eval "require $class" );
        foreach my $op ( '; DROP TABLE x', '<=', '', undef ) {
            eval {
                $class->_buildCompareExpression( '_utime', $op, 1,
                    FakeDbh->new, {} );
            };
            like( $@, qr/invalid operator/,
                "$backend: _buildCompareExpression rejects "
                  . ( defined $op ? "'$op'" : 'undef' ) );
        }
    }
}

# No public fallback in _common.pm: File keeps the Lemonldap::NG one
SKIP: {
    my $class = 'Web::Session::File';
    skip "$class can't be loaded", 2 unless ( eval "require $class" );
    ok( !$class->can('searchLt'), 'File: no searchLt' );
    ok( !$class->can('searchGt'), 'File: no searchGt' );
}

done_testing();
