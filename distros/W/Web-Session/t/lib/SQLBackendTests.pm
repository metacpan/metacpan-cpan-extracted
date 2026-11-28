package SQLBackendTests;

# Common tests for SQL backends, run only if <env>_DSN is set (credentials
# are read from <env>_USER and <env>_PASSWORD). Parameters:
#  - class:   Web::Session class to test
#  - driver:  DBD driver name (Pg, mysql, MariaDB); if not set, it
#             is read from <env>_DSN
#  - env:     environment variables prefix (PG, MYSQL, MARIADB, ORACLE)
#  - table:   table name (dropped before and after tests)
#  - create:  SQL statements to create table (__TABLE__ is replaced)
#  - index:   indexed fields (DBI based backends, one column per field)
#  - corrupt: a_session value that can't be unserialized
#  - null:    1 if a field can be stored as JSON null (JSON backends)
#  - json:    1 if any field can be queried (JSON backends)
#  - weird:   field names that need quoting (JSON backends)
#  - scs:     1 to also test with standard_conforming_strings=off (PostgreSQL)
#  - reserved: an indexed field named after a reserved word (quoted column)
#  - tableCase: 1 to also use the table with its name in upper case
#               (PostgreSQL folds unquoted names to lower case)
#  - gin:     1 to compare searchOn() results with and without GinIndex
#  - args:    other arguments given to the backend (KeepConnections...)
#  - pool:    if set, 1 if sessions must use the connection pool of the
#             PostgreSQL store, 0 if they must not
#  - todo:    known bugs of this backend: { test group => reason }. Tests of
#             these groups are run as TODO tests and may die without
#             breaking the rest of the suite
#  - utf8:    1 to test non-ASCII field names and values (JSON backends)
#  - utf8_todo: reason why get_key_from_all_sessions() without fields doesn't
#               return non-ASCII values yet (marks this test as TODO)
#  - exact:   1 to check that searches are case and accent sensitive
#  - deferredInsert: 1 if the backend inserts a new session at its untie,
#             not at its tie (PgJSON with the connection pool)
#  - explain: sub( $class, $dbh, $args ) returning a list of
#             [ description, WHERE clause, index or array ref of indexes,
#               statement ]:
#             the plan of each WHERE clause must use all these indexes.
#             Statement defaults to "SELECT id" (use "DELETE" to explain a
#             deletion); a sub( $table, $where ) returns the whole statement
#             instead
#  - explain_key:  1 to check that MySQL/MariaDB chooses these indexes, not
#                  only lists them in possible_keys
#  - explain_fill: number of sessions to add to a new table before explaining
#                  queries, so that the optimizer choices don't depend on a
#                  tiny table
#
# ASB_TEST_TABLE_PREFIX environment variable replaces the "asb_test_" prefix
# of table names.

use strict;
use warnings;
use Test::More;
use Exporter 'import';
use JSON;
use Scalar::Util qw(refaddr);

our @EXPORT = qw(run_tests);
our $TODO;

# Diagnostics may contain non-ASCII values
binmode( Test::More->builder->$_, ':encoding(UTF-8)' )
  foreach (qw(output failure_output todo_output));

sub run_tests {
    my %o = @_;
    my ( $class, $table ) = @o{qw(class table)};
    my $dsn = $ENV{"$o{env}_DSN"};
    $table =~ s/^asb_test_/$ENV{ASB_TEST_TABLE_PREFIX}/
      if $ENV{ASB_TEST_TABLE_PREFIX};

    $o{driver} ||= ( ( $dsn // '' ) =~ /^dbi:(\w+):/i )[0];
    plan skip_all => "Set $o{env}_DSN to run this test" unless $o{driver};
    plan skip_all => "DBD::$o{driver} is needed for this test"
      unless eval "require DBI; require DBD::$o{driver}; 1";
    plan skip_all => "Set $o{env}_DSN to run this test" unless $dsn;

    my $dbh = DBI->connect(
        $dsn, $ENV{"$o{env}_USER"},
        $ENV{"$o{env}_PASSWORD"},
        { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 }
    );

    my $drop = sub { $dbh->do("DROP TABLE IF EXISTS $table") };
    my $create = sub {
        $drop->();
        foreach ( @{ $o{create} } ) {
            ( my $sql = $_ ) =~ s/__TABLE__/$table/g;
            $dbh->do($sql);
        }
    };
    $create->();

    use_ok($class);

    my $args = {
        DataSource => $dsn,
        UserName   => $ENV{"$o{env}_USER"},
        Password   => $ENV{"$o{env}_PASSWORD"},
        TableName  => $table,
        Commit     => 1,
        ( $o{index} ? ( Index => $o{index} ) : () ),
        %{ $o{args} || {} },
    };
    my %todo  = %{ $o{todo}  || {} };
    my @weird = @{ $o{weird} || [] };

    my $newSession = sub {
        my %data = @_;
        my %session;
        tie %session, $class, undef, $args;
        $session{$_} = $data{$_} foreach ( keys %data );
        my $id = $session{_session_id};
        untie %session;
        return $id;
    };

    my %data = (
        dwho => {
            uid           => 'dwho',
            _whatToTrace  => 'dwho',
            _session_kind => 'SSO',
            _utime        => 100,
            _lastSeen     => 100,
            _oidcRtUpdate => 150,
            counter       => 1,
            mail          => 'dwho@badwolf.org',
            ( map { ( $_ => 'w1' ) } @weird ),
        },
        rtyler => {
            uid           => 'rtyler',
            _whatToTrace  => 'rtyler',
            _session_kind => 'Persistent',
            _utime        => 100,
            _lastSeen     => 300,
            _oidcRtUpdate => 250,
            counter       => 3,
            mail          => 'rtyler@badwolf.org',
            ( map { ( $_ => 'w2' ) } @weird ),
        },
        obrien => {
            uid           => "O'Brien",
            _whatToTrace  => "O'Brien",
            _session_kind => 'SSO',
            _utime        => 300,
            _lastSeen     => 100,
            counter       => 2,
            mail          => 'obrien@badwolf.org',
        },
        nokind => {
            uid           => 'nokind',
            _whatToTrace  => 'nokind',
            _utime        => 100,
            _lastSeen     => 100,
            _oidcRtUpdate => 200,
            mail          => 'nokind@badwolf.org',
        },
    );

    my $ids;
    my $reset = sub {
        $dbh->do("DELETE FROM $table");
        $ids = { map { ( $_ => $newSession->( %{ $data{$_} } ) ) } keys %data };
    };
    my $name = sub {
        my %rev = reverse %{ $ids || {} };
        return join ',', sort map { $rev{$_} // $_ } keys %{ $_[0] || {} };
    };
    my $remaining = sub {
        return $name->( $class->get_key_from_all_sessions($args) );
    };
    my $quiet = sub {
        my ($code) = @_;
        local *STDERR;
        my $err = '';
        open STDERR, '>', \$err;
        return $code->();
    };

    # Whether class methods borrow their connection from the pool of the
    # PostgreSQL store (Web::Session::PgJSON, see _borrowDbh())
    my $classPool = sub {
        return ( $class->can('_classPool') and $class->_classPool( $_[0] ) );
    };

    # Handle that the next class method call will use: the connect_cached()
    # handle of _classDbh(), or with the pool, the connection it lends next
    # (the last one given back: borrowed, then given back at once)
    my $nextClassDbh = sub {
        my ($a) = @_;
        return $class->_classDbh($a) unless ( $classPool->($a) );
        my $loan = Web::Session::Store::Postgres->_lend($a);
        my $h    = $loan->{dbh};
        undef $loan;
        return $h;
    };

    # Run a group of tests. If the group is a known bug of this backend, run
    # it as TODO: STDERR is silenced and a die is reported as a failure
    my $group = sub {
        my ( $key, $code ) = @_;
        return $code->() unless $todo{$key};
      TODO: {
            local $TODO = $todo{$key};
            local *STDERR;
            my $err = '';
            open STDERR, '>', \$err;
            eval { $code->(); 1 } or fail("$key died: $@");
        }
    };

    # Store / retrieve
    $group->(
        store => sub {
            my $id = $newSession->( %{ $data{dwho} }, list => [ 1, 2 ] );
            ok( $id, 'Session created' );
            my %session;
            ok( tie( %session, $class, $id, $args ), 'Session retrieved' );
            is( $session{$_}, $data{dwho}->{$_}, "Field $_ retrieved" )
              foreach ( sort keys %{ $data{dwho} } );
            is_deeply( $session{list}, [ 1, 2 ], 'Array retrieved' );
            untie %session;
        }
    );

    # New session with an id given by the caller (Lemonldap::NG's setId)
    # that is already used, and new session still tied at the end of the
    # program
    $group->(
        deferredInsert => sub {
            {
                no strict 'refs';
                @{'SQLBackendTests::SetId::ISA'} = ($class);
            }
            my $id      = $newSession->( uid => 'first' );
            my $setArgs = { %$args, setId => $id };
            my $stored  = sub {
                my ($v) = $dbh->selectrow_array(
                    "SELECT a_session FROM $table WHERE id = ?",
                    undef, $_[0] // $id );
                return $v && JSON->new->decode($v)->{uid};
            };
            my %s;
            ok( !eval { tie( %s, 'SQLBackendTests::SetId', undef, $setArgs ) },
                'Deferred INSERT: new session with a used id, tie dies' );
            is( $stored->(), 'first',
                'Deferred INSERT: used id, other session kept' );

            # The id is free at tie, another process inserts it before untie
            my $race = 'r' x 64;
            my $inserted = sub {
                $dbh->do( "INSERT INTO $table (id, a_session) VALUES (?, ?)",
                    undef, $race,
                    JSON->new->encode( { _session_id => $race, uid => 'other' } )
                );
            };
            ok( tie( %s, 'SQLBackendTests::SetId', undef,
                    { %$args, setId => $race } ),
                'Deferred INSERT: new session with a free id tied' );
            $inserted->();
            tied(%s)->delete;
            untie %s;
            is( $stored->($race), 'other',
                'Deferred INSERT: deleted in its tie, other session kept' );
            $dbh->do( "DELETE FROM $table WHERE id = ?", undef, $race );

            my @warnings;
            {
                local $SIG{__WARN__} = sub { push @warnings, @_ };
                tie %s, 'SQLBackendTests::SetId', undef,
                  { %$args, setId => $race };
                $inserted->();
                $s{uid} = 'second';
                ok( !eval { tied(%s)->save; 1 },
                    'Deferred INSERT: id inserted since the tie, save() dies' );
                untie %s;
            }
            like(
                join( '', @warnings ),
                qr/unable to store new session \Q$race\E/,
                'Deferred INSERT: id inserted since the tie, untie warns'
            );
            is( $stored->($race), 'other',
                'Deferred INSERT: other session not overwritten' );
            $dbh->do( "DELETE FROM $table WHERE id = ?", undef, $race );

            # _session_id changed while tied and not put back (Lemonldap::NG's
            # hashed session store): the session is inserted under its id
            {
                my $other = 'c' x 64;
                tie %s, $class, undef, $args;
                my $tieId = $s{_session_id};
                $s{_session_id} = $other;
                $s{uid}         = 'changed';
                untie %s;
                is( $stored->($tieId), 'changed',
                    'Deferred INSERT: changed id, inserted under the tie id' );
                ok(
                    !$dbh->selectrow_array(
                        "SELECT count(*) FROM $table WHERE id = ?",
                        undef, $other
                    ),
                    'Deferred INSERT: changed id, nothing under the other id'
                );
                $dbh->do( "DELETE FROM $table WHERE id = ?", undef, $tieId );
            }

            # In another process, so that the session is freed by the global
            # destruction
            my $script = <<'EOS';
use strict;
use JSON;
my ( $class, $args ) = @ARGV;
eval "require $class; 1" or die $@;
our %session;
tie %session, $class, undef, JSON->new->decode($args);
print $session{_session_id};
EOS
            open(
                my $fh, '-|', $^X, ( map { "-I$_" } @INC ),
                '-e', $script, $class, JSON->new->encode($args)
            ) or die $!;
            my $new = <$fh>;
            close $fh;
            ok(
                $new
                  && $dbh->selectrow_array(
                    "SELECT count(*) FROM $table WHERE id = ?",
                    undef, $new
                  ),
                'Deferred INSERT: new session tied at the end of the program'
                  . ' inserted'
            );
            $dbh->do( "DELETE FROM $table WHERE id IN (?, ?)",
                undef, $id, $new // '' );
        }
    ) if ( $o{deferredInsert} );

    # Non-ASCII values, in Latin-1 range and beyond
    foreach my $v ( "\x{c9}lodie", "\x{c9}lodie \x{3a9}" ) {
        ( my $l = $v ) =~ s/[^ -~]/?/g;
        my $u8 = $newSession->( uid => 'u8', cn => $v, list => [$v] );
        my %session;
        my $check = sub {
            my ($step) = @_;
            tie %session, $class, $u8, $args;
            is( $session{cn}, $v, "Value $l$step retrieved" );
            is_deeply( $session{list}, [$v], "Array with $l$step retrieved" );
            untie %session;
            my $r = $class->get_key_from_all_sessions($args);
            is( $r->{$u8}->{cn}, $v, "get_key_from_all_sessions returns $l$step" );
            $r = $class->get_key_from_all_sessions( $args, sub { $_[0]->{cn} } );
            is( $r->{$u8}, $v, "get_key_from_all_sessions with a code ref: $l$step" );
            $group->(
                gkfasArray => sub {
                    my $r = $class->get_key_from_all_sessions( $args, ['cn'] );
                    is( $r->{$u8}->{cn}, $v,
                        "get_key_from_all_sessions with fields: $l$step" );
                }
            );
            $group->(
                searchOnData => sub {
                    my $r = $class->searchOn( $args, 'uid', 'u8' );
                    is( $r->{$u8}->{cn}, $v,
                        "searchOn without fields returns $l$step" );
                }
            );
            $r = $class->searchOn( $args, 'uid', 'u8', 'cn' );
            is( $r->{$u8}->{cn}, $v, "searchOn with fields returns $l$step" );
        };
        $check->('');

        # Update the session: the store rewrites the non-ASCII values
        tie %session, $class, $u8, $args;
        $session{x} = 1;
        untie %session;
        $check->(' after update');
        $dbh->do( "DELETE FROM $table WHERE id=?", undef, $u8 );
    }

    # Unchanged sessions are not rewritten. The row is changed behind the tied
    # session, which then stores back the values it read: the row must be
    # left as is. jsonb (PostgreSQL) and json (MySQL) columns return a
    # normalized text, so this goes through the comparison of the data
    $group->(
        unchanged => sub {
            my $id = $newSession->(
                %{ $data{dwho} },
                list => [ 1, { b => 2, a => 1 } ],
                ( $o{utf8} ? ( cn => "\x{c9}lodie \x{3a9}" ) : () ),
            );
            my $other = to_json( { _session_id => $id, uid => 'other' } );
            my $uid   = sub {
                my $text = $dbh->selectrow_array(
                    "SELECT a_session FROM $table WHERE id = ?",
                    undef, $id );
                return $text =~ /"uid"\s*:\s*"(\w+)"/ ? $1 : undef;
            };
            my $storeBack = sub {
                my ( $targs, $change ) = @_;
                my %s;
                tie %s, $class, $id, $targs;
                my @keys = keys %s;
                $s{$_} = $s{$_} foreach (@keys);
                $change->( \%s ) if ($change);
                $dbh->do( "UPDATE $table SET a_session = ? WHERE id = ?",
                    undef, $other, $id );
                untie %s;
            };

            $storeBack->($args);
            is( $uid->(), 'other', 'Same values stored back: no UPDATE' );

            $dbh->do( "DELETE FROM $table WHERE id=?", undef, $id );
            $id = $newSession->( %{ $data{dwho} } );
            $other = to_json( { _session_id => $id, uid => 'other' } );
            $storeBack->( $args, sub { $_[0]->{uid} = 'changed' } );
            is( $uid->(), 'changed', 'Real change: UPDATE' );

            $storeBack->( { %$args, RewriteUnchanged => 1 } );
            is( $uid->(), 'changed', 'RewriteUnchanged: UPDATE' );
            $dbh->do( "DELETE FROM $table WHERE id=?", undef, $id );
        }
    );

    # Connection reuse (default) and "noreuse" option
    {
        my $rargs = $args;
        my $dbhOf = sub { tied( %{ $_[0] } )->{object_store}->{dbh} };
        my %s;

        # No reference to the tied object is kept: untie must free it
        unless ( eval { tie %s, $class, undef, $rargs; 1 } ) {
            fail("reuse: tie failed: $@");
            last;
        }
        $s{$_} = $data{dwho}->{$_} foreach ( keys %{ $data{dwho} } );
        my $rid  = $s{_session_id};
        my $rdbh = $dbhOf->( \%s );

        # Connection pool of the PostgreSQL store (see the "pool" parameter)
        my $pooled = defined tied(%s)->{object_store}->{pool_key};
        is(
            $pooled  ? 1            : 0,
            $o{pool} ? 1            : 0,
            $o{pool} ? 'pool: used' : 'pool: not used'
        ) if ( exists $o{pool} );

        # Two sessions tied at once never share a pooled connection, so never
        # a transaction
        if ($pooled) {
            my %other;
            tie %other, $class, undef, $rargs;
            isnt( refaddr( $dbhOf->( \%other ) ),
                refaddr($rdbh),
                'pool: two sessions tied at once, two handles' );
            my $oid = $other{_session_id};
            untie %other;
            $dbh->do( "DELETE FROM $table WHERE id = ?", undef, $oid );
        }
        untie %s;
        ok( $rdbh->{Active}, 'reuse: connection kept at untie' );

        tie %s, $class, $rid, { %$args, noreuse => 1 };
        my $ndbh = $dbhOf->( \%s );
        untie %s;
        isnt( refaddr($ndbh), refaddr($rdbh), 'noreuse: new handle' );
        ok( !$ndbh->{Active}, 'noreuse: connection closed at untie' );

        tie %s, $class, $rid, $rargs;
        is( refaddr( $dbhOf->( \%s ) ), refaddr($rdbh),
            'reuse: handle reused' );
        is( $s{mail}, 'dwho@badwolf.org', 'reuse: session retrieved' );
        $s{mail} = 'reuse@badwolf.org';
        untie %s;
        tie %s, $class, $rid, { %$args, noreuse => 1 };
        is( $s{mail}, 'reuse@badwolf.org', 'reuse: update committed' );
        untie %s;

        # Without Commit, the transaction ends at untie: rolled back if
        # AutoCommit is off, which releases the row locked by the write
        tie %s, $class, $rid, { %$rargs, Commit => 0 };
        my $autoCommit = $dbhOf->( \%s )->{AutoCommit};
        $s{mail} = 'rollback@badwolf.org';
        untie %s;
        $dbh->do(
            $o{driver} eq 'Pg'
            ? "SET lock_timeout = '5s'"
            : 'SET SESSION innodb_lock_wait_timeout = 5'
        );
        ok(
            eval {
                $dbh->do(
                    "UPDATE $table SET a_session = a_session WHERE id = ?",
                    undef, $rid );
                1;
            },
            'reuse: row not locked after untie'
        ) or diag $@;
        $dbh->do('RESET lock_timeout') if ( $o{driver} eq 'Pg' );
        tie %s, $class, $rid, $args;
        is(
            $s{mail},
            $autoCommit ? 'rollback@badwolf.org' : 'reuse@badwolf.org',
            'reuse: Commit => 0 commits only with AutoCommit'
        );
        untie %s;

        # A failed operation (which aborts a PostgreSQL transaction) doesn't
        # break the next ones
        $quiet->(
            sub {
                eval {
                    tie %s, $class, undef,
                      { %$rargs, TableName => "${table}_missing" };
                };
            }
        );
        tie %s, $class, $rid, $rargs;

        # The pool closes a connection that met an error
        if ($pooled) {
            ok( $dbhOf->( \%s )->{Active},
                'pool: connection available after a failure' );
        }
        else {
            is( refaddr( $dbhOf->( \%s ) ),
                refaddr($rdbh), 'reuse: handle reused after a failure' );
        }
        is( $s{uid}, 'dwho', 'reuse: session retrieved after a failure' );
        tied(%s)->delete;
        untie %s;
        ok( !eval { tie %s, $class, $rid, $args; 1 },
            'reuse: session deleted' );
    }

    $reset->();

    # searchOn / searchOnExpr
    $group->(
        searchOn => sub {
            my $res = $class->searchOn( $args, 'uid', 'dwho' );
            is( $name->($res), 'dwho', 'searchOn without fields' );

            $res = $class->searchOn( $args, '_whatToTrace', "O'Brien", 'uid' );
            is_deeply(
                $res,
                {
                    $ids->{obrien} => { id => $ids->{obrien}, uid => "O'Brien" }
                },
                'searchOn on a value containing a quote'
            );

            $res = $class->searchOn( $args, '_session_kind', 'SSO', '_utime' );
            is( $name->($res), 'dwho,obrien', 'searchOn on _session_kind' );

            $res = $class->searchOnExpr( $args, '_whatToTrace', '*t*' );
            is( $name->($res), 'rtyler', 'searchOnExpr without fields' );
        }
    );
    $group->(
        searchOnData => sub {
            my $res = $class->searchOn( $args, 'uid', 'dwho' );
            is( $res->{ $ids->{dwho} }->{mail},
                'dwho@badwolf.org',
                'searchOn without fields returns session data' );
            $res = $class->searchOnExpr( $args, 'uid', 'dw*' );
            is( $res->{ $ids->{dwho} }->{mail},
                'dwho@badwolf.org',
                'searchOnExpr without fields returns session data' );
        }
    );
    $group->(
        searchOnFields => sub {
            my $res =
              $class->searchOn( $args, 'uid', 'dwho', '_whatToTrace', 'uid' );
            is_deeply(
                $res,
                {
                    $ids->{dwho} => {
                        id           => $ids->{dwho},
                        _whatToTrace => 'dwho',
                        uid          => 'dwho'
                    }
                },
                'searchOn with fields keeps field name case'
            );
            $res =
              $class->searchOnExpr( $args, '_whatToTrace', '*t*',
                '_whatToTrace' );
            is_deeply(
                $res,
                {
                    $ids->{rtyler} =>
                      { id => $ids->{rtyler}, _whatToTrace => 'rtyler' }
                },
                'searchOnExpr with fields keeps field name case'
            );
        }
    );
    $group->(
        searchOnExprQuote => sub {
            my $res = $class->searchOnExpr( $args, 'uid', "O'Br*" );
            is( $name->($res), 'obrien',
                'searchOnExpr on a value containing a quote' );
        }
    );

    # searchLt / searchGt: sessions without the field are never returned.
    # "counter" is never indexed (Perl comparison with column backends)
    $group->(
        searchLt => sub {
            foreach (
                [ searchLt => _oidcRtUpdate => 200,     'dwho' ],
                [ searchGt => _oidcRtUpdate => 200,     'rtyler' ],
                [ searchLt => _oidcRtUpdate => 1000,    'dwho,nokind,rtyler' ],
                [ searchGt => _oidcRtUpdate => -1,      'dwho,nokind,rtyler' ],
                [ searchLt => _oidcRtUpdate => '200.5', 'dwho,nokind' ],
                [ searchGt => _oidcRtUpdate => '199.5', 'nokind,rtyler' ],
                [ searchLt => _utime        => 300,     'dwho,nokind,rtyler' ],
                [ searchGt => _utime        => 100,     'obrien' ],
                [ searchLt => counter       => 3,       'dwho,obrien' ],
                [ searchGt => counter       => 1,       'obrien,rtyler' ],
                [ searchGt => counter       => 0,       'dwho,obrien,rtyler' ],
                [ searchLt => unknown       => 1000,    '' ],
                [ searchGt => _oidcRtUpdate => ' 200 ', 'rtyler' ],
                [ searchGt => counter       => ' 2 ',   'rtyler' ],
              )
            {
                my ( $m, $f, $v, $expected ) = @$_;
                my $res = $class->$m( $args, $f, $v );
                is( $name->($res), $expected, "$m $f $v" );
            }
            $group->(
                searchOnData => sub {
                    my $res = $class->searchLt( $args, '_oidcRtUpdate', 200 );
                    is( $res->{ $ids->{dwho} }->{mail},
                        'dwho@badwolf.org',
                        'searchLt without fields returns session data' );
                    is( $res->{ $ids->{dwho} }->{_oidcRtUpdate},
                        150, 'searchLt without fields returns field value' );
                }
            );
            my $noId = sub {
                my ($h) = @_;
                return {
                    map { $_ eq 'id' ? () : ( $_ => $h->{$_} ) }
                      keys %$h
                };
            };
            foreach (
                [
                    'searchLt', '_oidcRtUpdate',
                    200,        'dwho',
                    [qw(uid _oidcRtUpdate)]
                ],
                [
                    'searchGt', '_utime',
                    100,        'obrien',
                    [qw(_whatToTrace _utime)]
                ],
                [ 'searchGt', 'counter', 2, 'rtyler', [qw(mail counter)] ],
              )
            {
                my ( $m, $f, $v, $s, $fields ) = @$_;
                my $res = $class->$m( $args, $f, $v, @$fields );
                is( $name->($res), $s, "$m $f $v with fields" );
                is_deeply(
                    $noId->( $res->{ $ids->{$s} } || {} ),
                    { map { ( $_ => $data{$s}->{$_} ) } @$fields },
                    "$m $f $v with fields returns these fields"
                );
            }
            foreach
              my $bad ( '200 OR 1=1', '1e3', '', ' ', undef, "\x{0661}", '2 0' )
            {
                ( my $label = $bad // 'undef' ) =~ s/[^ -~]/?/g;
                foreach my $m (qw(searchLt searchGt)) {
                    my $res =
                      $quiet->( sub { $class->$m( $args, '_utime', $bad ) } );
                    is_deeply( $res, {},
                        "$m with value '$label' returns nothing" );
                }
            }
        }
    );

    # searchLt / searchGt when the SQL query fails: the error is printed,
    # then the sessions are compared in Perl, with the same result
    $group->(
        searchFallback => sub {
            no strict 'refs';
            no warnings 'redefine';
            foreach (
                [ searchLt => _oidcRtUpdate => 200, 'dwho' ],
                [ searchGt => _oidcRtUpdate => 200, 'rtyler' ],
                [ searchLt => _utime        => 300, 'dwho,nokind,rtyler' ],
              )
            {
                my ( $m, $f, $v, $expected ) = @$_;
                my ( $res, $err ) = ( undef, '' );
                {
                    local *{"${class}::_buildCompareExpression"} =
                      sub { 'no_such_column < 0' };
                    local *STDERR;
                    open STDERR, '>', \$err;
                    $res = $class->$m( $args, $f, $v );
                }
                is( $name->($res), $expected,
                    "$m $f $v: failed query, compared in Perl" );
                like(
                    $err,
                    qr/^$m: .+^$m: comparing all sessions in Perl instead$/ms,
                    "$m $f $v: errors printed"
                );
            }

            # A value that isn't an integer is 0 (PostgreSQL can't cast it:
            # compared in Perl). An index on the cast refuses to store it:
            # this runs on the table without the CREATE INDEX statements, and
            # is skipped if the table itself refuses it (MySQL generated
            # columns in strict mode)
            {
                my $plain = "${table}_noindex";
                ( my $sql = $o{create}->[0] ) =~ s/__TABLE__/$plain/g;
                $dbh->do("DROP TABLE IF EXISTS $plain");
                $dbh->do($sql);
                local $args->{TableName} = $plain;
                my %id = map {
                    my $v = $_;
                    my $sid = $quiet->(
                        sub {
                            eval {
                                $newSession->(
                                    uid           => "rt$v",
                                    _oidcRtUpdate => $v
                                );
                            };
                        }
                    );
                    ( $v => $sid )
                } qw(150 abc 250);
                my $all = $quiet->(
                    sub { $class->get_key_from_all_sessions($args) } );
              SKIP: {
                    skip 'this table refuses a non numeric value', 2
                      unless ( $id{abc}
                        and ( $all->{ $id{abc} }->{_oidcRtUpdate} // '' ) eq
                        'abc' );
                    my $res = $quiet->(
                        sub {
                            $class->searchLt( $args, '_oidcRtUpdate', 200 );
                        }
                    );
                    is_deeply(
                        [ sort keys %$res ],
                        [ sort @id{qw(150 abc)} ],
                        'searchLt: a non numeric value is 0'
                    );
                    $res = $quiet->(
                        sub {
                            $class->searchGt( $args, '_oidcRtUpdate', 200 );
                        }
                    );
                    is_deeply(
                        [ keys %$res ],
                        [ $id{250} ],
                        'searchGt: a non numeric value is 0'
                    );
                }
                $dbh->do("DROP TABLE IF EXISTS $plain");
            }

            # Both the query and the Perl comparison fail: nothing
            my ( $res, $err ) = ( undef, '' );
            {
                local $args->{TableName} = 'no_such_table';
                local *STDERR;
                open STDERR, '>', \$err;
                $res = $class->searchLt( $args, '_oidcRtUpdate', 200 );
            }
            is_deeply( $res, {}, 'searchLt: query and scan fail: nothing' );
            like(
                $err,
                qr/^searchLt: comparing all sessions in Perl instead\n.*^searchLt: /ms,
                'searchLt: query and scan fail: errors printed'
            );
        }
    );

    # Case and accent sensitive searches, on indexed and non indexed fields
    if ( $o{exact} ) {
        # Character string: DBD::mysql sends other strings in Latin-1, which
        # an utf8mb4 column rejects
        my $elodie = "\x{c9}lodie";
        utf8::upgrade($elodie);
        my $uid = $newSession->(
            %{ $data{dwho} },
            uid          => $elodie,
            _whatToTrace => $elodie,
        );
        foreach my $f (qw(_whatToTrace uid)) {
            my $res = $class->searchOn( $args, $f, 'DWHO' );
            is_deeply( $res, {}, "searchOn on $f is case sensitive" );
            $res = $class->searchOnExpr( $args, $f, 'DW*' );
            is_deeply( $res, {}, "searchOnExpr on $f is case sensitive" );
            foreach my $v (qw(elodie ELODIE)) {
                $res = $class->searchOn( $args, $f, $v );
                is_deeply( $res, {}, "searchOn on $f: $v doesn't match" );
                $res = $class->searchOnExpr( $args, $f, "$v*" );
                is_deeply( $res, {}, "searchOnExpr on $f: $v* doesn't match" );
            }

            $res = $class->searchOn( $args, $f, $elodie );
            is( $name->($res), $uid, "searchOn on $f: exact value found" );
        }
        $dbh->do( "DELETE FROM $table WHERE id=?", undef, $uid );
    }

    # get_key_from_all_sessions
    $group->(
        gkfas => sub {
            my $res = $class->get_key_from_all_sessions($args);
            is( $name->($res), 'dwho,nokind,obrien,rtyler',
                'get_key_from_all_sessions without argument' );
            is( $res->{ $ids->{rtyler} }->{mail},
                'rtyler@badwolf.org',
                'get_key_from_all_sessions returns session data' );

            $res = $class->get_key_from_all_sessions( $args,
                sub { $_[0]->{uid} eq 'dwho' ? $_[0]->{mail} : undef } );
            is_deeply(
                $res,
                { $ids->{dwho} => 'dwho@badwolf.org' },
                'get_key_from_all_sessions with a code ref'
            );
        }
    );
    $group->(
        gkfasArray => sub {
            my $fields = [ 'uid', '_utime' ];
            my $res    = $class->get_key_from_all_sessions( $args, $fields );
            is( $name->($res), 'dwho,nokind,obrien,rtyler',
                'get_key_from_all_sessions with an array ref' );
            is( $res->{ $ids->{obrien} }->{uid},
                "O'Brien",
                'get_key_from_all_sessions with an array ref returns data' );
            is_deeply(
                $fields,
                [ 'uid', '_utime' ],
                'Array ref is not modified'
            );
        }
    );
    $group->(
        gkfasField => sub {
            my $res =
              $class->get_key_from_all_sessions( $args, '_whatToTrace' );
            is_deeply(
                $res->{ $ids->{rtyler} },
                { id => $ids->{rtyler}, _whatToTrace => 'rtyler' },
                'get_key_from_all_sessions with a field name'
            );
        }
    );

    $group->(
        callerArray => sub {
            my $fields = [ 'uid', "x'y" ];
            {
                local *STDERR;
                my $err = '';
                open STDERR, '>', \$err;
                eval { $class->get_key_from_all_sessions( $args, $fields ) };
            }
            is_deeply(
                $fields,
                [ 'uid', "x'y" ],
                'Array ref with a quote is not modified'
            );
        }
    );
    # Mixed-case field with a false value
    my $zero = $newSession->( %{ $data{dwho} }, _whatToTrace => '0' );
    $group->(
        searchOnFields => sub {
            my $res = $class->searchOn( $args, 'uid', 'dwho', '_whatToTrace' );
            is( $res->{$zero}->{_whatToTrace},
                '0',
                'searchOn with fields keeps false value under original case' );
        }
    );
    $group->(
        gkfasArray => sub {
            my $res =
              $class->get_key_from_all_sessions( $args, ['_whatToTrace'] );
            is( $res->{$zero}->{_whatToTrace},
                '0',
                'get_key_from_all_sessions with array ref and false value' );
        }
    );
    $group->(
        gkfasField => sub {
            my $res =
              $class->get_key_from_all_sessions( $args, '_whatToTrace' );
            is( $res->{$zero}->{_whatToTrace},
                '0',
                'get_key_from_all_sessions with a field name and false value' );
        }
    );
    $dbh->do( "DELETE FROM $table WHERE id=?", undef, $zero );
    # Fields needing quotes
    foreach my $w (@weird) {
        $group->(
            weird => sub {
                my $res = $class->searchOn( $args, $w, 'w1', $w, 'uid' );
                is_deeply(
                    $res,
                    {
                        $ids->{dwho} =>
                          { id => $ids->{dwho}, $w => 'w1', uid => 'dwho' }
                    },
                    "searchOn on field [$w]"
                );
                $res = $class->searchOnExpr( $args, $w, 'w*', 'uid' );
                is( $name->($res), 'dwho,rtyler',
                    "searchOnExpr on field [$w]" );
            }
        );
        $group->(
            gkfasArray => sub {
                my $res =
                  $class->get_key_from_all_sessions( $args, [ $w, 'uid' ] );
                is( $res->{ $ids->{rtyler} }->{$w},
                    'w2', "get_key_from_all_sessions with field [$w]" );
            }
        );
    }
    if ( $o{json} ) {
        foreach my $w ( "x' OR '1'='1", 'x" OR "1"="1', "x`y" ) {
            $group->(
                fieldInjection => sub {
                    my $res = eval { $class->searchOn( $args, $w, 'w1', $w ) };
                    is_deeply( $res, {},
                        "searchOn on field [$w]: no injection" )
                      or diag $@;
                    $res = eval { $class->searchLt( $args, $w, 1000 ) };
                    is_deeply( $res, {},
                        "searchLt on field [$w]: no injection" )
                      or diag $@;
                }
            );
            $group->(
                gkfasArray => sub {
                    my $res =
                      eval { $class->get_key_from_all_sessions( $args, [$w] ); };
                    is( scalar( keys %{ $res || {} } ),
                        4, "get_key_from_all_sessions with field [$w]" )
                      or diag $@;
                }
            );
        }

        # Field names are case sensitive (MySQL/MariaDB column names aren't)
        $group->(
            fieldCase => sub {
                my $res = $class->searchOn( $args, '_WhatToTrace', 'dwho' );
                is_deeply( $res, {},
                    'searchOn: field names are case sensitive' );
                $res = $class->searchOnExpr( $args, '_WhatToTrace', 'dw*' );
                is_deeply( $res, {},
                    'searchOnExpr: field names are case sensitive' );
            }
        );
        $group->(
            gkfasArray => sub {
                my $res =
                  $class->get_key_from_all_sessions( $args, ['_WhatToTrace'] );
                is_deeply(
                    $res->{ $ids->{dwho} },
                    { id => $ids->{dwho}, _WhatToTrace => undef },
                    'get_key_from_all_sessions: field names are case sensitive'
                );
            }
        );
    }

    # Non-ASCII field names and values
    if ( $o{utf8} ) {
        my $uid = $newSession->(
            %{ $data{dwho} },
            uid          => "\x{c9}lodie",
            _whatToTrace => "\x{c9}lodie",
            cn           => "Zo\x{eb} \x{20ac}",
            "cl\x{e9}"   => 'v',
        );
        $group->(
            utf8 => sub {
                my $res =
                  $class->searchOn( $args, '_whatToTrace', "\x{c9}lodie",
                    'cn' );
                is_deeply(
                    $res,
                    { $uid => { id => $uid, cn => "Zo\x{eb} \x{20ac}" } },
                    'searchOn with non-ASCII value'
                );
                $res = $class->searchOn( $args, 'cn', "Zo\x{eb} \x{20ac}",
                    '_whatToTrace', "cl\x{e9}" );
                is_deeply(
                    $res,
                    {
                        $uid => {
                            id           => $uid,
                            _whatToTrace => "\x{c9}lodie",
                            "cl\x{e9}"   => 'v'
                        }
                    },
                    'searchOn with non-ASCII field name and value'
                );
            }
        );
        $group->(
            gkfasArray => sub {
                my $res = $class->get_key_from_all_sessions( $args,
                    [ 'cn', "cl\x{e9}" ] );
                is_deeply(
                    $res->{$uid},
                    {
                        id         => $uid,
                        cn         => "Zo\x{eb} \x{20ac}",
                        "cl\x{e9}" => 'v'
                    },
                    'get_key_from_all_sessions with non-ASCII field name'
                );
            }
        );
        $group->(
            utf8Read => sub {
                my $res = $class->get_key_from_all_sessions($args);
                is(
                    $res->{$uid}->{cn},
                    "Zo\x{eb} \x{20ac}",
                    'get_key_from_all_sessions returns non-ASCII value'
                );
            }
        );
        foreach (
            [ value => { _whatToTrace => "\x{c9}lodie" }, 'utf8' ],
            [
                'value (UTF-8 bytes)' => { _whatToTrace => "\xc3\x89lodie" },
                'utf8'
            ],
            [ 'field name' => { "cl\x{e9}" => 'v' }, 'deleteNot' ]
          )
        {
            my ( $l, $not, $key ) = @$_;

            # Other sessions don't have the field name: they must be deleted
            $group->(
                $key => sub {
                    my @r = $class->deleteIfLowerThan( $args,
                        { or => { _utime => 200 }, not => $not } );
                    is_deeply(
                        \@r,
                        [ 1, 3 ],
                        "deleteIfLowerThan \"not\" non-ASCII $l"
                    );
                    is(
                        $remaining->(),
                        join( ',', sort 'obrien', $uid ),
"deleteIfLowerThan \"not\" non-ASCII $l: right sessions kept"
                    );
                }
            );
            $reset->();
            $uid = $newSession->(
                %{ $data{dwho} },
                _whatToTrace => "\x{c9}lodie",
                "cl\x{e9}"   => 'v',
            );
        }
        $reset->();
    }

    # get_key_from_all_sessions reads sessions by batches
    {
        local $Web::Session::_common::BatchSize = 2;
        my $queries = 0;
        my $cdbh    = $nextClassDbh->($args);
        local $cdbh->{Callbacks} =
          { ChildCallbacks => { execute => sub { $queries++; return } } };
        foreach my $n ( 4, 5 ) {
            $newSession->( uid => 'extra' ) if ( $n == 5 );
            $queries = 0;
            my $calls = 0;
            my $res   = $class->get_key_from_all_sessions( $args,
                sub { $calls++; $_[1] } );
            is( $calls, $n,
                "$n sessions by batches: callback called for each" );
            is( scalar( keys %$res ),
                $n, "$n sessions by batches: all returned" );
            is( $queries, 3, "$n sessions by batches: 3 queries" );
        }
        my $res = $class->get_key_from_all_sessions($args);
        is( scalar( keys %$res ), 5, 'Sessions by batches without callback' );
        $reset->();
    }

    # A purge larger than the batch size deletes everything
    $group->(
        deleteBatches => sub {
            local $Web::Session::_common::BatchSize = 2;
            foreach my $count ( 4, 5, 7 ) {

                # Empty table: $reset adds the default sessions
                $dbh->do("DELETE FROM $table");
                $newSession->( uid => "old$_", _utime => 100 + $_ )
                  foreach ( 1 .. $count );
                $newSession->( uid => 'recent', _utime => 100_000 );
                my @r = $class->deleteIfLowerThan( $args,
                    { or => { _utime => 200 } } );
                is_deeply( \@r, [ 1, $count ],
                    "deleteIfLowerThan: $count sessions by batches of 2" );
                is(
                    scalar( keys %{ $class->get_key_from_all_sessions($args) } ),
                    1, 'deleteIfLowerThan by batches: only 1 session left'
                );
            }
            $reset->();
        }
    );

    # With the pool of the PostgreSQL store, class methods borrow one of its
    # connections for the duration of the call: a callback of
    # get_key_from_all_sessions() that ties a session or calls a class method
    # gets another connection. Without it, they use connect_cached()
    if ( exists $o{pool} ) {
        my $cached        = 0;
        my $connectCached = \&DBI::connect_cached;
        no warnings 'redefine';
        local *DBI::connect_cached = sub { $cached++; goto &$connectCached };
        use warnings 'redefine';
        my ( $tied, $found ) = ( 0, 0 );
        my $res = $class->get_key_from_all_sessions(
            $args,
            sub {
                my ( $s, $id ) = @_;
                my %t;
                tie %t, $class, $id, $args;
                $tied++ if ( $t{uid} eq $s->{uid} );
                untie %t;
                $found++
                  if ( $class->searchOn( $args, 'uid', $s->{uid} )->{$id} );
                return 1;
            }
        );
        my $n = scalar keys %$res;
        is( $n, 4, 'class methods: sessions read' );
        is( $tied, $n, 'class methods: session tied in a callback' );
        is( $found, $n, 'class methods: class method called in a callback' );
        is( $classPool->($args) ? 1 : 0, $o{pool} ? 1 : 0,
            $o{pool} ? 'class methods: pool used' : 'class methods: no pool' );
        is(
            $cached ? 0 : 1,
            $o{pool} ? 1 : 0,
            $o{pool}
            ? 'class methods: connect_cached() not used'
            : 'class methods: connect_cached() used'
        );
        # DBI returns "0E0" when no row is deleted
        my @r = $class->deleteIfLowerThan( $args, { or => { _utime => 0 } } );
        is_deeply( [ map { 0 + $_ } @r ],
            [ 1, 0 ], 'class methods: deleteIfLowerThan' );
    }

    # deleteIfLowerThan
    $group->(
        delete => sub {
            $reset->();
            my @r =
              $class->deleteIfLowerThan( $args, { or => { _utime => 200 } } );
            is_deeply(
                \@r,
                [ 1, 3 ],
                'deleteIfLowerThan "or": 3 sessions deleted'
            );
            is( $remaining->(), 'obrien',
                'deleteIfLowerThan "or": 1 session kept' );

            $reset->();
            @r = $class->deleteIfLowerThan( $args,
                { or => { _utime => 200, _lastSeen => 200 } } );
            is_deeply( \@r, [ 1, 4 ], 'deleteIfLowerThan "or" with 2 fields' );
        }
    );
    $group->(
        deleteAnd => sub {
            $reset->();
            my @r = $class->deleteIfLowerThan( $args,
                { and => { _utime => 200, _lastSeen => 200 } } );
            is_deeply(
                \@r,
                [ 1, 2 ],
                'deleteIfLowerThan "and": 2 sessions deleted'
            );
            is( $remaining->(), 'obrien,rtyler',
                'deleteIfLowerThan "and": 2 kept' );
        }
    );
    $group->(
        deleteNot => sub {
            $reset->();
            my @r = $class->deleteIfLowerThan(
                $args,
                {
                    or  => { _utime        => 200 },
                    not => { _session_kind => 'Persistent' }
                }
            );
            is_deeply(
                \@r,
                [ 1, 2 ],
                'deleteIfLowerThan "not": 2 sessions deleted'
            );
            is( $remaining->(), 'obrien,rtyler',
                'deleteIfLowerThan "not": session without field deleted' );
        }
    );
    $group->(
        deleteAndNot => sub {
            $reset->();
            my @r = $class->deleteIfLowerThan(
                $args,
                {
                    and => { _utime        => 200, _lastSeen => 400 },
                    not => { _session_kind => 'Persistent' }
                }
            );
            is_deeply( \@r, [ 1, 2 ], 'deleteIfLowerThan "and" with "not"' );
            is( $remaining->(), 'obrien,rtyler',
                'deleteIfLowerThan "and" with "not": right sessions kept' );
        }
    );
    $group->(
        deleteNotQuote => sub {
            $reset->();
            my @r = $class->deleteIfLowerThan( $args,
                { or => { _utime => 400 }, not => { uid => "O'Brien" } } );
            is_deeply( \@r, [ 1, 3 ], 'deleteIfLowerThan "not" with a quote' );
            is( $remaining->(), 'obrien',
                'deleteIfLowerThan "not" with a quote' );

            $reset->();
            @r = $class->deleteIfLowerThan( $args,
                { or => { _utime => 200 }, not => { uid => "x' OR '1'='1" } } );
            is_deeply( \@r, [ 1, 3 ], 'deleteIfLowerThan "not": no injection' );
        }
    );
    $group->(
        ruleNotModified => sub {
            $reset->();
            my $rule =
              { or => { _utime => 400 }, not => { uid => "O'Brien" } };
            {
                # Some backends die here, only the rule matters
                local *STDERR;
                my $err = '';
                open STDERR, '>', \$err;
                eval { $class->deleteIfLowerThan( $args, $rule ) };
            }
            is( $rule->{not}->{uid}, "O'Brien", 'Rule is not modified' );
        }
    );

    # Corrupted session must not break listing
    if ( $o{corrupt} ) {
        $group->(
            corrupt => sub {
                $reset->();
                $dbh->do(
                    "INSERT INTO $table (id,a_session) VALUES ('corrupt',?)",
                    undef, $o{corrupt} );
                my $res;
                {
                    local *STDERR;
                    my $err = '';
                    open STDERR, '>', \$err;
                    $res = $class->get_key_from_all_sessions($args);
                }
                is( $name->($res), 'dwho,nokind,obrien,rtyler',
                    'get_key_from_all_sessions skips corrupted session' );
            }
        );
    }
    # Database errors are printed, not thrown
    $group->(
        deleteError => sub {
            $reset->();
            my ( @r, $r, $err );
            {
                local $args->{TableName} = 'no_such_table';
                local *STDERR;
                open STDERR, '>', \$err;
                @r = $class->deleteIfLowerThan( $args,
                    { or => { _utime => 200 } } );
                $r = $class->deleteIfLowerThan( $args,
                    { or => { _utime => 200 } } );
            }
            is_deeply( \@r, [ 0, 0 ],
                'deleteIfLowerThan: database error returns (0, 0)' );
            is( $r, 0, 'deleteIfLowerThan: database error returns 0' );
            like(
                $err,
                qr/^deleteIfLowerThan: /m,
                'deleteIfLowerThan: database error printed'
            );
            is( $remaining->(), 'dwho,nokind,obrien,rtyler',
                'deleteIfLowerThan: database error: nothing deleted' );
        }
    );

    # Rules that can't be turned into SQL are rejected without exception;
    # an empty "not" is ignored
    $group->(
        deleteInvalid => sub {
            $reset->();
            my @r = eval {
                $class->deleteIfLowerThan( $args,
                    { not => { uid => 'dwho' } } );
            };
            is_deeply(
                \@r,
                [ 0, 0 ],
                'deleteIfLowerThan with only "not" returns 0'
            ) or diag $@;
            is( $remaining->(), 'dwho,nokind,obrien,rtyler',
                'Nothing deleted' );

            @r = $class->deleteIfLowerThan( $args,
                { or => { _utime => 200 }, not => {} } );
            is_deeply( \@r, [ 1, 3 ], 'deleteIfLowerThan with an empty "not"' );

            foreach my $bad ( 'x', [ _utime => 200 ], \'x' ) {
                my $label = ref($bad) || $bad;
                @r = $quiet->(
                    sub {
                        eval {
                            $class->deleteIfLowerThan( $args,
                                { or => { _utime => 200 }, not => $bad } );
                        };
                    }
                );
                is_deeply(
                    \@r,
                    [ 0, 0 ],
                    "\"not\" is not a hash ref ($label): returns 0"
                );
                @r = $quiet->(
                    sub {
                        eval { $class->deleteIfLowerThan( $args, $bad ) }
                    }
                );
                is_deeply(
                    \@r,
                    [ 0, 0 ],
                    "rule is not a hash ref ($label): returns 0"
                );
            }
            is( $remaining->(), 'obrien',
                'Invalid rule: only empty "not" deleted' );
        }
    );
    # A field stored as JSON null does not protect a session
    if ( $o{null} ) {
        $group->(
            deleteNull => sub {
                $reset->();
                my $nullId =
                  $newSession->( %{ $data{dwho} }, _session_kind => undef );
                my $json =
                  $dbh->selectrow_array(
                    "SELECT a_session FROM $table WHERE id=?",
                    undef, $nullId );
                like(
                    $json,
                    qr/"_session_kind"\s*:\s*null/,
                    'Session with a JSON null field created'
                );
                my @r = $class->deleteIfLowerThan(
                    $args,
                    {
                        or  => { _utime        => 200 },
                        not => { _session_kind => 'SSO' }
                    }
                );
                is_deeply(
                    \@r,
                    [ 1, 3 ],
                    'deleteIfLowerThan "not": JSON null deleted'
                );
                is( $remaining->(), 'dwho,obrien',
                    'deleteIfLowerThan "not": right sessions kept' );
            }
        );
    }

    # Thresholds are inserted into the query: they must be numbers
    $group->(
        deleteThresholds => sub {
            $reset->();
            foreach my $type (qw(or and)) {
                foreach my $bad ( '200 OR 1=1', '1e3', '', "\x{0661}" ) {
                    ( my $label = $bad ) =~ s/[^ -~]/?/g;
                    my @r = $quiet->(
                        sub {
                            eval {
                                $class->deleteIfLowerThan(
                                    $args,
                                    {
                                        $type =>
                                          { _utime => 400, _lastSeen => $bad }
                                    }
                                );
                            };
                        }
                    );
                    is_deeply(
                        \@r,
                        [ 0, 0 ],
                        "\"$type\" with threshold '$label' returns 0"
                    );
                }
            }
            is( $remaining->(), 'dwho,nokind,obrien,rtyler',
                'Nothing deleted' );

            my @r =
              $class->deleteIfLowerThan( $args,
                { or => { _utime => '100.5' } } );
            is_deeply(
                \@r,
                [ 1, 3 ],
                'deleteIfLowerThan with a decimal threshold'
            );
        }
    );

    # "not" on fields needing quotes. Sessions without the field must be
    # deleted too
    foreach my $w (@weird) {
        $group->(
            deleteNot => sub {
                $reset->();
                my @r = $class->deleteIfLowerThan( $args,
                    { or => { _utime => 400 }, not => { $w => 'w1' } } );
                is_deeply(
                    \@r,
                    [ 1, 3 ],
                    "deleteIfLowerThan \"not\" on field [$w]"
                );
                is( $remaining->(), 'dwho',
                    "deleteIfLowerThan \"not\" on field [$w]" );
            }
        );
    }

    # PostgreSQL with standard_conforming_strings=off: backslashes are escape
    # characters in plain string literals
    if ( $o{scs} ) {

        # Set by libpq "options" for every connection to this DataSource:
        # class methods may borrow a pooled connection (another one in a
        # callback, a new one after an error), not a single handle that could
        # be configured with SET
        local $args->{DataSource} =
          "$args->{DataSource};options=-cstandard_conforming_strings=off";
        is( $nextClassDbh->($args)
              ->selectrow_array('SHOW standard_conforming_strings'),
            'off', 'standard_conforming_strings is off for the module' );
        my %isWeird = map { $_ => 1 } @weird;
        my @names = ( @weird, grep { !$isWeird{$_} } "x\\' OR '1'='1", 'x\\' );
        foreach my $w (@names) {
            my $found = $isWeird{$w};
            my $l     = "field [$w] (scs off)";
            $reset->();
            $group->(
                weird => sub {
                    my $res =
                      eval { $class->searchOn( $args, $w, 'w1', 'uid' ) };
                    diag $@ if $@;
                    is( $name->($res), $found ? 'dwho' : '', "searchOn on $l" );
                    $res =
                      eval { $class->searchOnExpr( $args, $w, 'w*', 'uid' ) };
                    diag $@ if $@;
                    is(
                        $name->($res),
                        $found ? 'dwho,rtyler' : '',
                        "searchOnExpr on $l"
                    );
                }
            );
            $group->(
                gkfasArray => sub {
                    my $res =
                      eval { $class->get_key_from_all_sessions( $args, [$w] ) };
                    diag $@ if $@;
                    is( scalar( keys %{ $res || {} } ),
                        4, "get_key_from_all_sessions on $l" );
                    is( $res->{ $ids->{rtyler} }->{$w},
                        'w2', "get_key_from_all_sessions value on $l" )
                      if ($found);
                }
            );
            $group->(
                deleteNot => sub {
                    my @r = eval {
                        $class->deleteIfLowerThan( $args,
                            { or => { _utime => 200 }, not => { $w => 'w1' } }
                        );
                    };
                    diag $@ if $@;
                    is_deeply(
                        \@r,
                        [ 1, $found ? 2 : 3 ],
                        "deleteIfLowerThan \"not\" on $l"
                    );
                    is(
                        $remaining->(),
                        $found ? 'dwho,obrien' : 'obrien',
                        "deleteIfLowerThan \"not\" on $l: right sessions kept"
                    );
                }
            );
        }
    }
    is( $nextClassDbh->($args)
          ->selectrow_array('SHOW standard_conforming_strings'),
        'on', 'standard_conforming_strings is back on' )
      if ( $o{scs} );

    # Identifiers are quoted: an indexed column named after a reserved word
    if ( my $w = $o{reserved} ) {
        $group->(
            reserved => sub {
                $reset->();
                my $id  = $newSession->( %{ $data{dwho} }, $w => 'r1' );
                my $res = $class->searchOn( $args, $w, 'r1', $w );
                is_deeply(
                    $res,
                    { $id => { id => $id, $w => 'r1' } },
                    "searchOn on column [$w]"
                );
                $res = $class->searchOnExpr( $args, $w, 'r*' );
                is( join( ',', keys %$res ),
                    $id, "searchOnExpr on column [$w]" );
                $res = $class->get_key_from_all_sessions( $args, [$w] );
                is( $res->{$id}->{$w},
                    'r1', "get_key_from_all_sessions with column [$w]" );
                $group->(
                    deleteNot => sub {
                        my @r = $class->deleteIfLowerThan( $args,
                            { or => { _utime => 200 }, not => { $w => 'r1' } }
                        );
                        is_deeply(
                            \@r,
                            [ 1, 3 ],
                            "deleteIfLowerThan with column [$w]"
                        );
                        is(
                            $remaining->(),
                            join( ',', sort 'obrien', $id ),
"deleteIfLowerThan with column [$w]: right sessions kept"
                        );
                    }
                );
            }
        );
    }

    # Table name in upper case: it must reach the table created without quotes
    if ( $o{tableCase} ) {
        $group->(
            tableCase => sub {
                $reset->();
                my $uargs = { %$args, TableName => uc($table) };
                my %session;
                tie %session, $class, undef, $uargs;
                $session{uid}    = 'upper';
                $session{_utime} = 100;
                my $id = $session{_session_id};
                untie %session;
                tie %session, $class, $id, $uargs;
                is( $session{uid}, 'upper', 'Upper case table: session read' );
                $session{mail} = 'upper@badwolf.org';
                untie %session;
                my $res = $class->searchOn( $uargs, 'uid', 'upper', 'uid' );
                is_deeply(
                    $res,
                    { $id => { id => $id, uid => 'upper' } },
                    'Upper case table: searchOn'
                );
                $res = $class->get_key_from_all_sessions($uargs);
                is( $res->{$id}->{mail},
                    'upper@badwolf.org',
                    'Upper case table: get_key_from_all_sessions' );
                my @r = $class->deleteIfLowerThan( $uargs,
                    { or => { _utime => 200 } } );
                is_deeply(
                    \@r,
                    [ 1, 4 ],
                    'Upper case table: deleteIfLowerThan'
                );
                is( $remaining->(), 'obrien',
                    'Upper case table: right sessions kept' );
            }
        );
    }

    # GinIndex: searchOn() must return the same results with jsonb
    # containment, whatever the JSON type of the searched field
    if ( $o{gin} ) {
        $dbh->do("DELETE FROM $table");

        # Force the GIN index to be used, even on this small table. Set by
        # libpq "options" for every connection to this DataSource, so also on
        # the connections that class methods borrow from the pool
        local $args->{DataSource} =
          "$args->{DataSource};options=-cenable_seqscan=off";
        my $mdbh = $nextClassDbh->($args);
        is( $mdbh->selectrow_array('SHOW enable_seqscan'),
            'off', 'GinIndex: enable_seqscan is off for the module' );
        my $pi   = '3.14159265358979323846264338327950288419716939937510';
        my $big  = '1' . ( '0' x 131071 );

        # Both numeric limits reached at once: PostgreSQL allows 131072 digits
        # before the decimal point and 16383 after
        my $bigdec = $big . '.' . ( '1' x 16383 );
        my %rows = (
            num      => '{"k":123}',
            str      => '{"k":"123"}',
            dec      => '{"k":1.50}',
            dec2     => '{"k":1.5}',
            negzero  => '{"k":-0}',
            exp      => '{"k":1e2}',
            exp2     => '{"k":1E+2}',
            zero5    => '{"k":0e5}',
            dec4     => '{"k":123.0000}',
            pi       => qq({"k":$pi}),
            big      => qq({"k":$big}),
            bigdec   => qq({"k":$bigdec}),
            true     => '{"k":true}',
            strtrue  => '{"k":"true"}',
            false    => '{"k":false}',
            array    => '{"k":[1,2]}',
            strarray => '{"k":"[1, 2]"}',
            object   => '{"k":{"a":1}}',
            null     => '{"k":null}',
            strnull  => '{"k":"null"}',
            empty    => '{"k":""}',
            other    => '{"j":"123"}',
            quotes   => JSON->new->encode( { k => qq{O'B"r\\n} } ),
            newline  => JSON->new->encode( { k => "x\ny" } ),
            unicode  => JSON->new->ascii->encode( { k => "\x{e9}t\x{e9}" } ),
            smiley   => JSON->new->encode( { k => "\x{263a}" } ),
        );
        $dbh->do( "INSERT INTO $table (id,a_session) VALUES (?,?)",
            undef, $_, $rows{$_} )
          foreach ( keys %rows );
        my $gargs = { %$args, GinIndex => 1 };

        foreach my $v ( 'dwho', '1.5' ) {
            my $q    = $class->_searchOnQuery( $gargs, 'k', $v );
            my $plan = join "\n",
              map { $_->[0] } @{
                $mdbh->selectall_arrayref(
                    "EXPLAIN SELECT id FROM $table WHERE $q->{query}",
                    undef, @{ $q->{values} } )
              };
            like(
                $plan,
                qr/Bitmap Index Scan on \w+_gin/,
                "GinIndex query for '$v' uses the GIN index"
            );
        }

        foreach (
            [ '123',                  'num,str' ],
            [ 123,                    'num,str' ],
            [ '1.5',                  'dec2' ],
            [ '1.50',                 'dec' ],
            [ '123.0000',             'dec4' ],
            [ '123.0',                '' ],
            [ '0',                    'negzero,zero5' ],
            [ '-0',                   '' ],
            [ '0e5',                  '' ],
            [ '100',                  'exp,exp2' ],
            [ '1e2',                  '' ],
            [ '1E+2',                 '' ],
            [ $pi,                    'pi' ],
            [ substr( $pi, 0, 20 ),   '' ],
            [ $big,                   'big' ],
            [ $big . '0',             '' ],
            [ $bigdec,                'bigdec' ],
            [ '0.' . ( '1' x 16384 ), '' ],
            [ 'true',                 'strtrue,true' ],
            [ 'false',                'false' ],
            [ '[1, 2]',               'array,strarray' ],
            [ '{"a": 1}',             'object' ],
            [ 'null',                 'strnull' ],
            [ '',                     'empty' ],
            [ qq{O'B"r\\n},           'quotes' ],
            [ "x\ny",                 'newline' ],
            [ "\x{e9}t\x{e9}",        'unicode' ],
            [ "\x{263a}",             'smiley' ],
            [ 'none',                 '' ],
          )
        {
            my ( $v, $expected ) = @$_;
            ( my $l = $v ) =~ s/[^ -~]/?/g;
            $l = substr( $l, 0, 20 ) . '...(' . length($l) . ')'
              if ( length($l) > 30 );
            my $off = $class->searchOn( $args, 'k', $v, 'k' );
            is( $name->($off), $expected, "searchOn [$l] on JSON types" );
            my $on = eval { $class->searchOn( $gargs, 'k', $v, 'k' ) };
            diag $@ if $@;
            is_deeply( $on, $off, "searchOn [$l] with GinIndex: same result" );
        }
        is_deeply(
            $class->searchOn( $gargs, 'k', '123' ),
            $class->searchOn( $args,  'k', '123' ),
            'searchOn with GinIndex without fields: same result'
        );

        $reset->();
        foreach my $w ( "weird'field", 'uid', '_utime' ) {
            my $v   = $w eq 'uid' ? "O'Brien" : $w eq '_utime' ? 100 : 'w1';
            my $off = $class->searchOn( $args, $w, $v, 'uid' );
            is_deeply( $class->searchOn( $gargs, $w, $v, 'uid' ),
                $off, "searchOn on field [$w] with GinIndex: same result" );
        }
    }


    # Queries must be able to use indexes
    if ( $o{explain} ) {

        # New table: rows deleted by previous tests may still be in indexes
        # and distort the optimizer estimates
        $create->() if ( $o{explain_fill} );
        $reset->();
        if ( $o{explain_fill} ) {
            $newSession->(
                uid           => "filler$_",
                _whatToTrace  => "filler$_",
                _session_kind => 'SSO',
                _utime        => 1000 + $_,
                _lastSeen     => 1000 + $_,
            ) foreach ( 1 .. $o{explain_fill} );
            $dbh->selectall_arrayref(
                ( $o{driver} eq 'Pg' ? 'ANALYZE' : 'ANALYZE TABLE' )
                . " $table" );
        }
        $dbh->do('SET enable_seqscan = off') if ( $o{driver} eq 'Pg' );

        # MySQL >= 8.3: JSON and TREE formats have no possible_keys column
        eval { $dbh->do('SET SESSION explain_format=TRADITIONAL') }
          if ( $o{driver} eq 'mysql' );
        foreach ( $o{explain}->( $class, $dbh, $args ) ) {
            my ( $desc, $where, $indexes, $statement ) = @$_;
            my @indexes =
              map { ( my $i = $_ ) =~ s/__TABLE__/$table/g; $i }
              ref($indexes) ? @$indexes : ($indexes);
            my $index = join ',', @indexes;
            $statement ||= 'SELECT id';
            my $sth = $dbh->prepare(
                ref($statement)
                ? 'EXPLAIN ' . $statement->( $table, $where )
                : "EXPLAIN $statement FROM $table WHERE $where"
            );
            $sth->execute;
            if ( $o{driver} eq 'Pg' ) {
                my $plan = join "\n",
                  map { $_->[0] } @{ $sth->fetchall_arrayref };
                my @missing = grep { $plan !~ /\b\Q$_\E\b/ } @indexes;
                ok( !@missing && $plan =~ /Index Cond/,
                    "$desc uses index $index" )
                  or diag "$where:\n$plan";
            }
            else {
                my $row     = $sth->fetchrow_hashref('NAME_lc');
                my $keys    = $row->{possible_keys} // '';
                my %keys    = map  { $_ => 1 } split /,/, $keys;
                my @missing = grep { !$keys{$_} } @indexes;
                ok( !@missing, "$desc can use index $index" )
                  or diag "$where: possible_keys=$keys";
                if ( $o{explain_key} ) {

                    # The optimizer may combine indexes (index_merge), so the
                    # expected ones must be included in key, not equal it
                    my %used    = map  { $_ => 1 } split /,/, $row->{key} // '';
                    my @missing = grep { !$used{$_} } @indexes;
                    ok( !@missing && ( $row->{type} // '' ) ne 'ALL',
                        "$desc uses index $index" )
                      or diag "$where: key="
                      . ( $row->{key} // '' )
                      . " type="
                      . ( $row->{type} // '' );
                }
                $sth->finish;
            }
        }
        $dbh->do('RESET enable_seqscan') if ( $o{driver} eq 'Pg' );
    }

    $drop->();
    $dbh->disconnect;
    done_testing();
}

# Lemonldap::NG's setId: the id of a new session is given by the caller. Its
# @ISA is set by the deferredInsert group
package SQLBackendTests::SetId;

sub populate {
    my $self = shift;
    $self->SUPER::populate(@_);
    $self->{generate} = sub {
        $_[0]->{data}->{_session_id} = $_[0]->{args}->{setId};
    };
    return $self;
}

1;
