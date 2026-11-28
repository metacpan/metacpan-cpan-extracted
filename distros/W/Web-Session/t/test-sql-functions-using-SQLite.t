# SQL correctness tests of Web::Session::DBI using SQLite

use strict;
use warnings;
use Test::More;
use File::Temp qw(mktemp);

my $dbfile = mktemp('tmp.db_XXXX');

plan skip_all => "DBD::SQLite is needed for this test"
  unless eval {
    require DBI;
    require DBD::SQLite;
    1;
  };

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, PrintError => 0 } );
$dbh->do( 'CREATE TABLE sessions(id char(64) not null primary key,'
      . 'a_session text,_utime text,_lastSeen text,_session_kind text,uid text)'
);

my $class = 'Web::Session::SQLite';
use_ok($class);

my $args = {
    DataSource => "dbi:SQLite:$dbfile",
    Index      => '_utime _lastSeen _session_kind uid',
};

sub newSession {
    my %data = @_;
    my %session;
    tie %session, $class, undef, $args;
    $session{$_} = $data{$_} foreach ( keys %data );
    my $id = $session{_session_id};
    untie %session;
    return $id;
}

sub reset_sessions {
    $dbh->do('DELETE FROM sessions');
    my %ids;
    while (@_) {
        my ( $name, $data ) = splice @_, 0, 2;
        $ids{$name} = newSession(%$data);
    }
    return \%ids;
}

sub remaining {
    my ($ids) = @_;
    my $all   = $class->get_key_from_all_sessions($args);
    my %rev   = reverse %$ids;
    return join ',', sort map { $rev{$_} } keys %$all;
}

sub quiet(&) {
    my ($code) = @_;
    local *STDERR;
    my $err = '';
    open STDERR, '>', \$err;
    return $code->();
}

# Like quiet(), but also returns what was written to STDERR
sub quiet_err(&) {
    my ($code) = @_;
    local *STDERR;
    my $err = '';
    open STDERR, '>', \$err;
    my $res = $code->();
    return ( $res, $err );
}

my ( $ids, $res, @res, $rule, $ret, $err );

# searchOnExpr() on a value containing a quote
$ids = reset_sessions(
    obrien  => { uid => "O'Brien",  f3 => "O'Brien" },
    obriena => { uid => "O'Briena", f3 => "O'Briena" },
    other   => { uid => 'OBrien',   f3 => 'OBrien' },
);
my %rev = reverse %$ids;
$res = $class->searchOnExpr( $args, 'uid', "O'Brien*" );
is( join( ',', sort map { $rev{$_} } keys %$res ),
    'obrien,obriena', 'searchOnExpr with a quote on an indexed field' );
$res = $class->searchOnExpr( $args, 'uid', "O'Brien*", 'uid' );
is( join( ',', sort map { $res->{$_}->{uid} } keys %$res ),
    "O'Brien,O'Briena",
    'searchOnExpr with a quote on an indexed field, with fields' );
$res = $class->searchOnExpr( $args, 'f3', "O'Brien*" );
is( join( ',', sort map { $rev{$_} } keys %$res ),
    'obrien,obriena', 'searchOnExpr with a quote on an unindexed field' );
$res = $class->searchOn( $args, 'uid', "O'Brien" );
is( join( ',', keys %$res ),
    $ids->{obrien}, 'searchOn with a quote on an indexed field' );
# Caller data must not be modified
$ids = reset_sessions( obrien => { uid => "O'Brien", _utime => 100 } );
my $fields = [ 'uid', '_utime' ];
$res = $class->get_key_from_all_sessions( $args, $fields );
is( $res->{ $ids->{obrien} }->{uid},
    "O'Brien", 'get_key_from_all_sessions with indexed fields' );
is_deeply( $fields, [ 'uid', '_utime' ], 'Fields list not modified' );

my $qargs = { %$args, Index => [ 'uid', "a'b" ] };
$fields = [ 'uid', "a'b" ];
quiet {
    eval { $class->get_key_from_all_sessions( $qargs, $fields ) }
};
is_deeply(
    $fields,
    [ 'uid', "a'b" ],
    'Fields list not modified (field containing a quote)'
);

require Web::Session::Store::SQLite;
my $store = Web::Session::Store::SQLite->new;
quiet {
    eval {
        $store->insert(
            {
                args       => $qargs,
                data       => { _session_id => 'x' },
                serialized => '{}'
            }
        );
    }
};
is_deeply( $qargs->{Index}, [ 'uid', "a'b" ], 'Store: Index not modified' );
# deleteIfLowerThan with only "not" does nothing
$ids = reset_sessions(
    a => { _utime => 100, _session_kind => 'SSO' },
    b => { _utime => 100, _session_kind => 'Persistent' },
);
is(
    eval {
        $class->deleteIfLowerThan( $args,
            { not => { _session_kind => 'Persistent' } } );
    },
    0,
    'only not: returns 0'
) or diag $@;
is( remaining($ids), 'a,b', 'only not: nothing deleted' );

# "or" / "and" that are not hash refs
foreach my $bad ( 'a', [ _utime => 250 ], \'x' ) {
    foreach my $type (qw(or and)) {
        is(
            quiet {
                eval { $class->deleteIfLowerThan( $args, { $type => $bad } ) };
            },
            0,
            "\"$type\" is not a hash ref ("
              . ( ref($bad) || $bad )
              . '): returns 0'
        ) or diag $@;
    }
}
is( remaining($ids), 'a,b', 'invalid "or"/"and": nothing deleted' );

# empty or invalid "not" in the rule
$ids = reset_sessions(
    old => { _utime => 100, _session_kind => 'SSO' },
    new => { _utime => 300, _session_kind => 'SSO' },
);
( $ret, $err ) = quiet_err {
    eval {
        $class->deleteIfLowerThan( $args,
            { or => { _utime => 200 }, not => {} } );
    };
};
is( $ret, 1, 'empty not: returns 1' ) or diag $@;
is( $err, '', 'empty not: no warning' );
is( remaining($ids), 'new', 'empty not: clause ignored' );

foreach my $bad ( 'x', [ _session_kind => 'y' ], \'x' ) {
    ( $ret, $err ) = quiet_err {
        eval {
            $class->deleteIfLowerThan( $args,
                { or => { _utime => 200 }, not => $bad } );
        };
    };
    is( $ret, 0,
        '"not" is not a hash ref (' . ( ref($bad) || $bad ) . '): returns 0' )
      or diag $@;
    like( $err, qr/not must be a hash reference/,
        '"not" is not a hash ref (' . ( ref($bad) || $bad ) . '): warning' );
}
foreach my $bad ( 'x', [ _utime => 200 ], \'x', undef ) {
    ( $ret, $err ) =
      quiet_err { eval { $class->deleteIfLowerThan( $args, $bad ) } };
    is( $ret, 0,
        'rule is not a hash ref ('
          . ( ref($bad) || ( defined $bad ? $bad : 'undef' ) )
          . '): returns 0' )
      or diag $@;
    like( $err, qr/rule must be a hash reference/,
        'rule is not a hash ref ('
          . ( ref($bad) || ( defined $bad ? $bad : 'undef' ) )
          . '): warning' );
}
is( remaining($ids), 'new', 'invalid rule: nothing deleted' );

# SQL failure (missing table): no die, false / (0, 0) and a message
my $badArgs = { %$args, TableName => 'no_such_table' };
$rule = { or => { _utime => 250 } };
( $ret, $err ) = quiet_err {
    my @r = eval { $class->deleteIfLowerThan( $badArgs, $rule ) };
    $@ ? 'died' : join( ',', @r );
};
is( $ret, '0,0', 'SQL failure: returns (0, 0) in list context' ) or diag $@;
like( $err, qr/deleteIfLowerThan: /, 'SQL failure: message on STDERR' );
( $ret, $err ) = quiet_err {
    my $r = eval { $class->deleteIfLowerThan( $badArgs, $rule ) };
    $@ ? 'died' : ( $r ? 'true' : 'false' );
};
is( $ret, 'false', 'SQL failure: returns false in scalar context' );
like( $err, qr/deleteIfLowerThan: /, 'SQL failure: message on STDERR' );
# deleteIfLowerThan with "or"
$ids = reset_sessions(
    a => { _utime => 100, _lastSeen => 400 },
    b => { _utime => 200, _lastSeen => 400 },
    c => { _utime => 300, _lastSeen => 400 },
);
@res = $class->deleteIfLowerThan( $args, { or => { _utime => 250 } } );
is_deeply( \@res, [ 1, 2 ], 'or: 2 sessions deleted' );
is( remaining($ids), 'c', 'or: session "c" remains' );

$ids = reset_sessions(
    a => { _utime => 100, _lastSeen => 400 },
    b => { _utime => 400, _lastSeen => 100 },
    c => { _utime => 400, _lastSeen => 400 },
);
ok(
    $class->deleteIfLowerThan(
        $args, { or => { _utime => 250, _lastSeen => 250 } }
    ),
    'or with 2 fields'
);
is( remaining($ids), 'c', 'or: session "c" remains' );

# deleteIfLowerThan with "and"
$ids = reset_sessions(
    a => { _utime => 100, _lastSeen => 100 },
    b => { _utime => 100, _lastSeen => 300 },
    c => { _utime => 300, _lastSeen => 100 },
);
@res = $class->deleteIfLowerThan( $args,
    { and => { _utime => 250, _lastSeen => 250 } } );
is_deeply( \@res, [ 1, 1 ], 'and: 1 session deleted' );
is( remaining($ids), 'b,c', 'and: sessions "b" and "c" remain' );

# deleteIfLowerThan with "not"
$ids = reset_sessions(
    sso     => { _utime => 100, _session_kind => 'SSO' },
    persist => { _utime => 100, _session_kind => 'Persistent' },
    nokind  => { _utime => 100 },
    recent  => { _utime => 300, _session_kind => 'SSO' },
);
$rule =
  { or => { _utime => 250 }, not => { _session_kind => 'Persistent' } };
@res = $class->deleteIfLowerThan( $args, $rule );
is_deeply( \@res, [ 1, 2 ], 'not: 2 sessions deleted' );
is( remaining($ids), 'persist,recent',
    'not: session without _session_kind deleted' );

# "not" value containing a quote is bound, not interpolated
$ids = reset_sessions(
    obrien => { _utime => 100, _session_kind => "O'Brien" },
    other  => { _utime => 100, _session_kind => 'x' },
    recent => { _utime => 300, _session_kind => 'x' },
);
$rule = { or => { _utime => 250 }, not => { _session_kind => "O'Brien" } };
ok( $class->deleteIfLowerThan( $args, $rule ), 'not with quote' );
is( remaining($ids), 'obrien,recent', 'not with quote: "other" deleted' );
is( $rule->{not}->{_session_kind}, "O'Brien", 'rule is not modified' );

$ids = reset_sessions(
    a      => { _utime => 100, _session_kind => 'a' },
    recent => { _utime => 300, _session_kind => 'x' },
);
ok(
    $class->deleteIfLowerThan(
        $args,
        { or => { _utime => 250 }, not => { _session_kind => "x' OR '1'='1" } }
    ),
    'not with injection attempt'
);
is( remaining($ids), 'recent', 'not with injection attempt: no injection' );

# deleteIfLowerThan with a non numeric threshold does nothing
$ids = reset_sessions(
    a => { _utime => 100, _session_kind => 'SSO' },
    b => { _utime => 100, _session_kind => 'Persistent' },
);
foreach my $bad ( '100 OR 1=1', '1e3', '', undef ) {
    is(
        quiet {
            eval {
                $class->deleteIfLowerThan( $args,
                    { or => { _utime => $bad } } );
            }
        },
        0,
        'non numeric threshold: returns 0 ('
          . ( defined $bad ? "'$bad'" : 'undef' ) . ')'
    );
}
is(
    quiet {
        $class->deleteIfLowerThan( $args,
            { and => { _utime => 250, _lastSeen => 'x' } } );
    },
    0,
    'non numeric "and" threshold: returns 0'
);
is(
    quiet {
        $class->deleteIfLowerThan( $args,
            { or => { _utime => "\x{0661}\x{0662}" } } );
    },
    0,
    'non ASCII digits threshold: returns 0'
);
is( remaining($ids), 'a,b', 'non numeric threshold: nothing deleted' );

# deleteIfLowerThan with a decimal or negative threshold
ok( $class->deleteIfLowerThan( $args, { or => { _utime => '100.5' } } ),
    'decimal threshold accepted' );
ok( $class->deleteIfLowerThan( $args, { or => { _utime => '-1' } } ),
    'negative threshold accepted' );

# get_key_from_all_sessions reads sessions by batches
{
    no warnings 'once';
    local $Web::Session::_common::BatchSize = 2;
    my $queries = 0;
    my $cdbh    = $class->_classDbh($args);
    local $cdbh->{Callbacks} =
      { ChildCallbacks => { execute => sub { $queries++; return } } };
    foreach my $n ( 4, 5 ) {
        $ids = reset_sessions( map { ( "s$_" => { uid => "u$_" } ) } 1 .. $n );
        $queries = 0;
        my $calls = 0;
        $res = $class->get_key_from_all_sessions( $args,
            sub { $calls++; $_[0]->{uid} } );
        is( $calls, $n, "$n sessions by batches: callback called for each" );
        is_deeply(
            $res,
            { map { ( $ids->{"s$_"} => "u$_" ) } 1 .. $n },
            "$n sessions by batches: all sessions returned"
        );
        is( $queries, 3, "$n sessions by batches: 3 queries" );
        $res = $class->get_key_from_all_sessions($args);
        is(
            join( ',', sort map { $_->{uid} } values %$res ),
            join( ',', map { "u$_" } 1 .. $n ),
            "$n sessions by batches: all sessions returned without callback"
        );
    }
}

# Invalid batch sizes fall back to the default one
{
    no warnings 'once';
    $ids = reset_sessions( map { ( "s$_" => { uid => "u$_" } ) } 1 .. 3 );
    foreach my $size ( 0, -1, 'abc', undef, 1_000_001, '9' x 26 ) {
        local $Web::Session::_common::BatchSize = $size;
        my $name = defined $size ? "'$size'" : 'undef';
        $res = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 10;
            my $r = $class->get_key_from_all_sessions($args);
            alarm 0;
            $r;
        };
        alarm 0;
        is( $@, '', "BatchSize $name: terminates" );
        is( join( ',', sort map { $_->{uid} } values %{ $res || {} } ),
            'u1,u2,u3', "BatchSize $name: all sessions returned" );
    }
}

# Subclass without its own populate()
{

    package My::SQLiteSubclass;
    our @ISA = ('Web::Session::SQLite');
}
$res = eval { My::SQLiteSubclass->get_key_from_all_sessions($args) };
is( $@, '', 'Subclass without populate: no error' );
is( join( ',', sort map { $_->{uid} } values %{ $res || {} } ),
    'u1,u2,u3', 'Subclass without populate: all sessions returned' );
$res = eval {
    My::SQLiteSubclass->get_key_from_all_sessions( $args,
        sub { $_[0]->{uid} } );
};
is( join( ',', sort values %{ $res || {} } ),
    'u1,u2,u3', 'Subclass without populate: callback called' );

# "not" value containing a quote is bound, not interpolated
$ids = reset_sessions(
    obrien => { _utime => 100, _session_kind => "O'Brien" },
    other  => { _utime => 100, _session_kind => 'x' },
    recent => { _utime => 300, _session_kind => 'x' },
);
$rule = { or => { _utime => 250 }, not => { _session_kind => "O'Brien" } };
ok( $class->deleteIfLowerThan( $args, $rule ), 'not with quote' );
is( remaining($ids), 'obrien,recent', 'not with quote: "other" deleted' );
is( $rule->{not}->{_session_kind}, "O'Brien", 'rule is not modified' );

$ids = reset_sessions(
    a      => { _utime => 100, _session_kind => 'a' },
    recent => { _utime => 300, _session_kind => 'x' },
);
ok(
    $class->deleteIfLowerThan(
        $args,
        { or => { _utime => 250 }, not => { _session_kind => "x' OR '1'='1" } }
    ),
    'not with injection attempt'
);
is( remaining($ids), 'recent', 'not with injection attempt: no injection' );

# deleteIfLowerThan with a non numeric threshold does nothing
$ids = reset_sessions(
    a => { _utime => 100, _session_kind => 'SSO' },
    b => { _utime => 100, _session_kind => 'Persistent' },
);
foreach my $bad ( '100 OR 1=1', '1e3', '', undef, '1' x 21, '9' x 400 ) {
    is(
        quiet {
            eval {
                $class->deleteIfLowerThan( $args,
                    { or => { _utime => $bad } } );
            }
        },
        0,
        'non numeric threshold: returns 0 ('
          . ( defined $bad ? "'$bad'" : 'undef' ) . ')'
    );
}
is(
    quiet {
        $class->deleteIfLowerThan( $args,
            { and => { _utime => 250, _lastSeen => 'x' } } );
    },
    0,
    'non numeric "and" threshold: returns 0'
);
is(
    quiet {
        $class->deleteIfLowerThan( $args,
            { or => { _utime => "\x{0661}\x{0662}" } } );
    },
    0,
    'non ASCII digits threshold: returns 0'
);
is( remaining($ids), 'a,b', 'non numeric threshold: nothing deleted' );

# deleteIfLowerThan with a decimal or negative threshold
ok( $class->deleteIfLowerThan( $args, { or => { _utime => '100.5' } } ),
    'decimal threshold accepted' );
ok( $class->deleteIfLowerThan( $args, { or => { _utime => '-1' } } ),
    'negative threshold accepted' );

# searchLt() and searchGt(): indexed fields are compared in SQL, other
# ones in Perl. Both compare "abc" as 0 and "250x" as 250. Sessions without
# the field are never returned
$ids = reset_sessions(
    a    => { _utime => 100,    n => 100 },
    b    => { _utime => 200,    n => 200 },
    c    => { _utime => 300,    n => 300 },
    str  => { _utime => 'abc',  n => 'abc' },
    pre  => { _utime => '250x', n => '250x' },
    none => { uid    => 'none' },
);
%rev = reverse %$ids;
my @sql;
{
    my $cdbh = $class->_classDbh($args);
    local $cdbh->{Callbacks} = {
        prepare => sub { push @sql, $_[1]; return }
    };
    foreach (
        [ searchLt =>  250,    'a,b,str' ],
        [ searchGt =>  200,    'c,pre' ],
        [ searchLt =>  1,      'str' ],
        [ searchGt => -1,      'a,b,c,pre,str' ],
        [ searchLt => '250.5', 'a,b,pre,str' ],
      )
    {
        my ( $m, $v, $expected ) = @$_;
        foreach my $f (qw(_utime n)) {
            @sql = ();
            $res = $class->$m( $args, $f, $v );
            is( join( ',', sort map { $rev{$_} } keys %$res ),
                $expected, "$m $f $v" );
            my $op = $m eq 'searchLt' ? '<' : '>';
            if ( $f eq '_utime' ) {
                is_deeply(
                    \@sql,
                    [
qq{SELECT id,a_session from "sessions" where cast("_utime" as integer) $op $v}
                    ],
                    "$m $f $v: compared in SQL"
                );
            }
            else {
                unlike( join( "\n", @sql ),
                    qr/cast\(/, "$m $f $v: compared in Perl" );
            }
        }
    }
}
$res = $class->searchLt( $args, '_utime', 150 );
is( $res->{ $ids->{a} }->{n}, 100, 'searchLt without fields returns sessions' );
foreach my $f (qw(_utime n)) {
    $res = $class->searchGt( $args, $f, 250, $f, 'uid' );
    is_deeply( [ map { $_->{$f} } values %$res ],
        [300], "searchGt $f with fields: 1 session" );
    is(
        join( ',', sort grep { $_ ne 'id' } keys %{ ( values %$res )[0] } ),
        join( ',', sort $f, 'uid' ),
        "searchGt $f with fields: requested fields"
    );
}
foreach my $bad ( '100 OR 1=1', '1e3', '', undef, 'abc', '1' x 21, '9' x 400 ) {
    foreach my $m (qw(searchLt searchGt)) {
        $res = quiet { $class->$m( $args, '_utime', $bad ) };
        is_deeply( $res, {},
            "$m with value " . ( $bad // 'undef' ) . ': nothing returned' );
    }
}

# Values that are not integers differ: SQL keeps only an integer prefix
# (12.7 is 12, 1e3 is 1), Perl compares the numeric value
$ids = reset_sessions(
    dec => { _utime => '12.7', n => '12.7' },
    exp => { _utime => '1e3',  n => '1e3' },
);
%rev = reverse %$ids;
$res = $class->searchGt( $args, '_utime', 12 );
is( join( ',', sort map { $rev{$_} } keys %$res ),
    '', 'searchGt in SQL: integer prefix' );
$res = $class->searchGt( $args, 'n', 12 );
is( join( ',', sort map { $rev{$_} } keys %$res ),
    'dec,exp', 'searchGt in Perl: numeric value' );

# A field name containing a quote is quoted as an identifier, as in
# searchOn(): never interpolated as is in SQL. The table has no such column
# (SQLite then reads the quoted name as a string: results aren't checked)
$ids = reset_sessions(
    a => { uid => 'a', "a'b" => 100 },
    b => { uid => 'b', "a'b" => 300 },
);
my $quoteArgs = { %$args, Index => [ 'uid', "a'b" ] };
{
    my @sql;
    my $cdbh = $class->_classDbh($quoteArgs);
    local $cdbh->{Callbacks} = {
        prepare => sub { push @sql, $_[1]; return }
    };
    foreach my $m (qw(searchLt searchGt)) {
        @sql = ();
        quiet_err { eval { $class->$m( $quoteArgs, "a'b", 200 ) } };
        is( $@, '', "$m with a quoted field name: no error" );
        like(
            join( "\n", @sql ),
            qr/cast\("a'b" as integer\)/,
            "$m with a quoted field name: quoted identifier"
        );
    }
}

# An SQL error in searchLt() and searchGt() doesn't die: nothing is
# returned and the error is printed on STDERR
foreach my $m (qw(searchLt searchGt)) {
    ( $ret, $err ) = quiet_err {
        eval {
            $class->$m( { %$args, TableName => 'no_such_table' },
                '_utime', 150 );
        };
    };
    is_deeply( $ret, {}, "$m: SQL error returns nothing" ) or diag $@;
    like( $err, qr/^$m: .*no_such_table/m, "$m: SQL error printed on STDERR" );
}

done_testing();

END {
    unlink $dbfile if ( $dbfile and -e $dbfile );
}
