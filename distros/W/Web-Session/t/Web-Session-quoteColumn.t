use strict;
use Test::More;

# Column names of indexed fields in the SQL queries, without database: index
# columns are quoted with _quoteIdentifier()
plan skip_all => 'DBI is needed for this test' unless eval { require DBI };

{

    # Records statements
    package FakeDbh;
    our @log;
    sub new { bless { Driver => { Name => $_[1] } }, $_[0] }

    # Quote characters of the real drivers
    my %quote = ( Pg => '"', SQLite => '"', mysql => '`' );

    sub quote_identifier {
        my ( $self, $name ) = @_;
        my $q = $quote{ $self->{Driver}->{Name} } or die 'not supported';
        $name =~ s/$q/$q$q/g;
        return "$q$name$q";
    }

    sub prepare {
        my ( $self, $sql ) = @_;
        push @log, $sql;
        return bless { dbh => $self, sql => $sql }, 'FakeSth';
    }
    *prepare_cached = \&prepare;

    sub do {
        my ( $self, $sql, $attr, @bind ) = @_;
        push @log, [ $sql, @bind ];
        return 0;
    }
    sub commit     { 1 }
    sub disconnect { 1 }

    package FakeSth;
    our @rows;

    sub execute {
        my ( $self, @bind ) = @_;
        push @{ $self->{bind} }, @bind;
        $self->{LongReadLen} = $self->{dbh}->{LongReadLen};
        return 1;
    }

    sub bind_param {
        my ( $self, $i, $v ) = @_;
        $self->{bind}->[ $i - 1 ] = $v;
        return 1;
    }

    # Column names as returned by the driver
    sub names {
        my ($self) = @_;
        my ($cols) = $self->{sql} =~ /^SELECT (.*?) from /i or return [];
        my @names;
        while (
            $cols =~ /\G(?:"((?:[^"]|"")*)"|`((?:[^`]|``)*)`|([^,"`]+)),?/gc )
        {
            if ( defined $1 ) {
                ( my $n = $1 ) =~ s/""/"/g;
                push @names, $n;
            }
            elsif ( defined $2 ) {
                ( my $n = $2 ) =~ s/``/`/g;
                push @names, $n;
            }
            else {
                push @names, $3;
            }
        }
        my $key = $self->{dbh}->{FetchHashKeyName} || 'NAME';
        return $key eq 'NAME_lc' ? [ map { lc } @names ] : \@names;
    }

    # @rows: values of the selected columns
    sub fetchall_hashref {
        my ( $self, $key ) = @_;
        my $names = $self->names;
        my ($i) = grep { $names->[$_] eq $key } 0 .. $#$names;
        die "Field '$key' does not exist (not one of @$names)\n"
          unless defined $i;
        my %res;
        foreach my $row (@rows) {
            my %h;
            @h{@$names} = @$row;
            $res{ $row->[$i] } = \%h;
        }
        return \%res;
    }
    sub fetchrow_array    { () }
    sub fetchrow_arrayref { ['{}'] }
    sub fetchall_arrayref { [] }
    sub finish            { 1 }
}

my $index =
  [ '_whatToTrace', '_session_kind', '_utime', '_lastSeen', 'ipAddr', 'a"b' ];
my $args = { Index => $index };

# SQL of each backend: $q quotes a column, $cmp compares it
my %backends = (
    SQLite => {
        driver => 'SQLite',
        table  => '"sessions"',
        q      => sub { $_[0] =~ /"/ ? $_[0] : qq{"$_[0]"} },
        cmp    => sub { "cast($_[0] as integer) $_[1] $_[2]" },
    },
);

foreach my $backend ( sort keys %backends ) {
    my $class = "Web::Session::$backend";
    my ( $driver, $t, $q, $cmp ) =
      @{ $backends{$backend} }{qw(driver table q cmp)};
  SKIP: {
        skip "$class can't be loaded", 1 unless ( eval "require $class" );
        no strict 'refs';
        no warnings 'redefine';

        local *{'Web::Session::DBI::_classDbh'} =
          sub { FakeDbh->new($driver) };
        my $run = sub {
            my ( $m, @a ) = @_;
            @FakeDbh::log = ();
            my @res = eval {
                local *STDERR;
                open STDERR, '>', \my $err;
                $class->$m( $args, @a );
            };
            fail("$backend: $m dies: $@") if $@;
            return wantarray ? @res : $res[0];
        };
        my $wt = $q->('_whatToTrace');

        $run->( searchOn => '_whatToTrace', 'dwho', '_whatToTrace', 'ipAddr' );
        is_deeply(
            \@FakeDbh::log,
            [
                    'SELECT id,'
                  . join( ',', $wt, $q->('ipAddr') )
                  . " from $t where $wt=?"
            ],
            "$backend: searchOn with indexed fields"
        );
        $run->( searchOn => '_whatToTrace', 'dwho' );
        is_deeply(
            \@FakeDbh::log,
            ["SELECT id,a_session from $t where $wt=?"],
            "$backend: searchOn without fields"
        );
        $run->( searchOnExpr => '_whatToTrace', 'dw*', '_utime' );
        is_deeply(
            \@FakeDbh::log,
            [ 'SELECT id,' . $q->('_utime') . " from $t where $wt like ?" ],
            "$backend: searchOnExpr"
        );
        $run->( searchOn => 'a"b', 'x', 'a"b' );
        is_deeply(
            \@FakeDbh::log,
            [
                    'SELECT id,'
                  . $q->('a"b')
                  . " from $t where "
                  . $q->('a"b') . '=?'
            ],
            "$backend: searchOn on a field containing a double quote"
        );

        $run->( get_key_from_all_sessions => [ '_whatToTrace', '_utime' ] );
        is_deeply(
            \@FakeDbh::log,
            [ "SELECT id,$wt," . $q->('_utime') . " from $t" ],
            "$backend: get_key_from_all_sessions with fields"
        );
        $run->( get_key_from_all_sessions => 'ipAddr' );
        is_deeply(
            \@FakeDbh::log,
            [ 'SELECT id,' . $q->('ipAddr') . " from $t" ],
            "$backend: get_key_from_all_sessions with a field name"
        );

        my $ut = $cmp->( $q->('_utime'),    '<', 200 );
        my $ls = $cmp->( $q->('_lastSeen'), '<', 200 );
        my $sk = $q->('_session_kind');
        $run->( deleteIfLowerThan => { or => { _utime => 200 } } );
        is_deeply(
            \@FakeDbh::log,
            [ ["DELETE FROM $t WHERE $ut"] ],
            "$backend: deleteIfLowerThan \"or\""
        );
        $run->( deleteIfLowerThan => { and => { _utime => 200 } } );
        is_deeply(
            \@FakeDbh::log,
            [ ["DELETE FROM $t WHERE $ut"] ],
            "$backend: deleteIfLowerThan \"and\""
        );
        $run->(
            deleteIfLowerThan => { or => { _utime => 200, _lastSeen => 200 } }
        );
        ok(
            (
                grep { $FakeDbh::log[0]->[0] eq "DELETE FROM $t WHERE $_" }
                  "$ut OR $ls",
                "$ls OR $ut"
            ),
            "$backend: deleteIfLowerThan \"or\" with 2 fields"
        ) or diag $FakeDbh::log[0]->[0];
        $run->(
            deleteIfLowerThan => {
                and => { _utime        => 200 },
                not => { _session_kind => 'Persistent' }
            }
        );
        is_deeply(
            \@FakeDbh::log,
            [
                [
                    "DELETE FROM $t WHERE ($ut) AND ($sk IS NULL OR $sk <> ?)",
                    'Persistent'
                ]
            ],
            "$backend: deleteIfLowerThan with \"not\""
        );

        # Store
        my $store   = $class->can('populate')->()->{object_store};
        my $dbh     = FakeDbh->new($driver);
        my $session = {
            args => { Index => $index, Handle => $dbh },
            data => {
                _session_id  => 'id1',
                _whatToTrace => 'dwho',
                _utime       => 100,
                'a"b'        => 'x'
            },
            serialized => '{}',
        };
        my $cols = join ',', map { $q->($_) } @$index;
        @FakeDbh::log = ();
        $store->insert($session);
        is_deeply(
            \@FakeDbh::log,
            [
                "INSERT INTO $t (id,a_session,$cols) VALUES ("
                  . join( ',', ('?') x 8 ) . ')'
            ],
            "$backend: store insert"
        );
        is_deeply(
            $store->{insert_sth}->{bind},
            [ 'id1', '{}', 'dwho', undef, 100, undef, undef, 'x' ],
            "$backend: store insert values"
        );
        @FakeDbh::log = ();
        $store->update($session);
        is_deeply(
            \@FakeDbh::log,
            [
                    "UPDATE $t SET a_session = ?, "
                  . join( ', ', map { $q->($_) . ' = ?' } @$index )
                  . ' WHERE id = ?'
            ],
            "$backend: store update"
        );
        is_deeply(
            $store->{update_sth}->{bind},
            [ '{}', 'dwho', undef, 100, undef, undef, 'x', 'id1' ],
            "$backend: store update values"
        );
    }
}

done_testing();
