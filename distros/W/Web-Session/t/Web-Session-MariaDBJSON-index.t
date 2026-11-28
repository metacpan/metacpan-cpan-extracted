use strict;
use Test::More;

# _checkIndex() only needs a database handle to query information_schema: use a
# fake one, no server required
my $class = 'Web::Session::MariaDBJSON';
plan skip_all => "$class can't be loaded"
  unless ( eval "require $class" );

{
    package FakeDbh;
    sub new {
        my ( $class, %o ) = @_;
        return bless { rows => $o{rows} || [], prepares => 0, sql => [] },
          $class;
    }
    sub quote {
        my ( $self, $s ) = @_;
        $s =~ s/'/''/g;
        return "'$s'";
    }
    sub prepare {
        my ($self) = @_;
        $self->{prepares}++;
        push @{ $self->{sql} }, $_[1];
        return FakeSth->new($self);
    }

    package FakeSth;
    sub new {
        my ( $class, $dbh ) = @_;
        return bless { dbh => $dbh }, $class;
    }
    sub execute {
        my ( $self, @bind ) = @_;
        $self->{dbh}->{bind} = \@bind;
        return 1;
    }
    sub fetchall_arrayref {
        my ($self) = @_;
        return $self->{dbh}->{rows};
    }
    sub finish { return 1 }
}

# Column usage: $class->_useColumn() and _sqlField()
sub usage {
    my ( $dbh, $args, $field ) = @_;
    local $SIG{__WARN__} = sub { };
    return $class->_useColumn( $dbh, $field, $args );
}

# Returns the exception (if any) and the warnings
sub check {
    my @a = @_;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $ok = eval { $class->_checkIndex(@a); 1 };
    return ( $ok ? '' : $@, join( '', @warn ) );
}

my $args = { Index => 'uid', TableName => 'sessions' };

# A generated column based on a_session is accepted silently, and the check is
# done only once per handle, table and Index list
my $dbh =
  FakeDbh->new( rows => [ [ 'uid', "JSON_VALUE(a_session, '\$.uid')" ] ] );
my ( $err, $warn ) = check( $dbh, $args );
is( $err,  '', 'generated column accepted' );
is( $warn, '', 'no warning for a generated column' );
is( $dbh->{prepares}, 1, 'one information_schema query' );
check( $dbh, $args );
is( $dbh->{prepares}, 1, 'result is memoized' );
is_deeply( $class->_checkIndex( $dbh, $args ),
    { uid => 1 }, 'validated fields are returned' );
ok( $dbh->{private_asb_mariadbjson_index},
    'memoized on a DBI private attribute' );
check( $dbh, { %$args, Index => 'uid lastSeen' } );
is( $dbh->{prepares}, 2, 'checked again when Index changes' );

# A column that exists but is not generated (migration from the former column-based MySQL backend)
# is reported instead of silently returning nothing
my $plain = FakeDbh->new( rows => [ [ 'uid', undef ] ] );
( $err, $warn ) = check( $plain, $args );
is( $err, '', 'plain column does not abort' );
like( $warn, qr/"uid".*not generated from a_session/s, 'reason given' );

# A missing column is reported too
my $missing = FakeDbh->new( rows => [] );
( $err, $warn ) = check( $missing, $args );
is( $err, '', 'missing column does not abort' );
like( $warn, qr/"uid".*no column with this name/s, 'reason given' );

# A column generated from something else than a_session is reported
my $other = FakeDbh->new( rows => [ [ 'uid', 'id' ] ] );
( $err, $warn ) = check( $other, $args );
like( $warn, qr/not generated from a_session/, 'foreign expression reported' );

# Everything listed in Index is checked, in one query
my $multi = FakeDbh->new(
    rows => [
        [ 'uid',      "JSON_VALUE(a_session, '\$.uid')" ],
        [ 'lastSeen', undef ],
    ]
);
( $err, $warn ) =
  check( $multi, { Index => 'uid lastSeen', TableName => 's' } );
like( $warn, qr/"lastSeen"/, 'every Index field is checked' );

# Only validated fields are read from their column, the other ones (and
# fields that are not in Index) from the JSON document
my $col = q{`uid`};
my $json = q{JSON_VALUE(a_session, '$.uid')};
$dbh = FakeDbh->new(
    rows => [
        [ 'uid',      "JSON_VALUE(a_session, '\$.uid')" ],
        [ 'lastSeen', undef ],
    ]
);
$args = { Index => 'uid lastSeen', TableName => 's' };
ok( usage( $dbh, $args, 'uid' ), 'validated field uses its column' );
ok( !usage( $dbh, $args, 'lastSeen' ), 'stale column is not used' );
ok( !usage( $dbh, $args, 'other' ),    'field out of Index is not used' );
is( $class->_sqlField( $dbh, 'uid', $args ), $col, '_sqlField: column' );
like(
    $class->_sqlField( $dbh, 'lastSeen', $args ),
    qr/^JSON_VALUE\(a_session, '\$\.lastSeen'\)\z/,
    '_sqlField: stale column replaced by JSON_VALUE'
);
is( $class->_buildLowerThanExpression( 'uid', 200, $dbh, $args ),
    "$col < 200", 'lowerThan on a validated column: no cast' );
is(
    $class->_buildLowerThanExpression( 'lastSeen', 200, $dbh, $args ),
    q{cast(JSON_VALUE(a_session, '$.lastSeen') as UNSIGNED) < 200},
    'lowerThan on a stale column: JSON_VALUE with cast'
);

# Missing column
$dbh = FakeDbh->new( rows => [] );
ok( !usage( $dbh, { Index => 'uid', TableName => 's' }, 'uid' ),
    'missing column is not used' );
( $err, $warn ) = check( FakeDbh->new, { Index => 'uid', TableName => 's' } );
like( $warn, qr/read from the JSON document/, 'warning describes the fallback' );
unlike( $warn, qr/silently/, 'no misleading text' );

# TableName may contain the schema; empty names (leading spaces in Index) are
# ignored
my $row = [ 'uid', "JSON_VALUE(a_session, '\$.uid')" ];
$dbh = FakeDbh->new( rows => [$row] );
check( $dbh, { Index => ' uid', TableName => 'lldap.sessions' } );
is_deeply( $dbh->{bind}, [ 'lldap', 'sessions', 'uid' ],
    'schema.table is split, empty field ignored' );
unlike( $dbh->{sql}->[0], qr/DATABASE\(\)/,
    'given schema replaces DATABASE()' );
$dbh = FakeDbh->new( rows => [$row] );
check( $dbh, { Index => 'uid', TableName => '`lldap`.`sessions`' } );
is_deeply( $dbh->{bind}, [ 'lldap', 'sessions', 'uid' ],
    'backquotes are removed' );
$dbh = FakeDbh->new( rows => [$row] );
check( $dbh, { Index => 'uid', TableName => 'sessions' } );
is_deeply( $dbh->{bind}, [ 'sessions', 'uid' ], 'plain table name' );
like( $dbh->{sql}->[0], qr/DATABASE\(\)/, 'current database used' );
$dbh = FakeDbh->new( rows => [$row] );
is_deeply(
    $class->_checkIndex( $dbh, { Index => ' uid  ', TableName => 's' } ),
    { uid => 1 },
    'leading and trailing spaces in Index'
);

# Without handle nothing can be checked
is_deeply( $class->_checkIndex( undef, $args ), {}, 'no handle: nothing valid' );

done_testing();
