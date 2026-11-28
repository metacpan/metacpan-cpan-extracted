package Web::Session::PgJSON;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Web::Session::Store::Postgres;
use Web::Session::_common;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;
use JSON qw(to_json);

our $VERSION = '1.0.0';
our @ISA     = qw(Apache::Session);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Web::Session::Store::Postgres $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    my ( $dbh, $loan ) = $class->_borrowDbh($args);
    if ( $args->{GinIndex} and !$class->_jsonbColumn( $args, $dbh ) ) {
        $args = { %$args };
        delete $args->{GinIndex};
    }
    return $class->_queryDbh( $dbh, $args,
        $class->_searchOnQuery( $args, $selectField, $value ), @fields );
}

# With GinIndex, add jsonb containment conditions that can use a GIN index
# on a_session. "->>" also returns the text of numbers and booleans, so a
# value that looks like one of them is searched in both forms. The "->>"
# comparison is kept: results are exactly the same as without GinIndex.
sub _searchOnQuery {
    my ( $class, $args, $field, $value ) = @_;
    my $f = $class->_sqlField($field);

    # "->>" returns arrays and objects as JSON text; jsonb rejects NUL
    return { query => "$f =?", values => [$value] }
      unless ( $args->{GinIndex}
        and defined($value)
        and $value !~ /^[\[{]/
        and "$field$value" !~ /\0/ );

    # A caller may pass the UTF-8 bytes of a non-ASCII field or value without
    # the UTF-8 flag: to_json() would then read them as Latin-1 and the JSON
    # document wouldn't match the stored data. Decode copies, used only to
    # build the documents: the "->>" recheck keeps the arguments as given,
    # like the query used without GinIndex.
    my ( $dfield, $dvalue ) = ( $field, $value );
    for ( $dfield, $dvalue ) {
        if ( !utf8::is_utf8($_) and /[\x80-\xff]/ ) {
            my $decoded = $_;
            $_ = $decoded if ( utf8::decode($decoded) );
        }
    }

    # Numbers beyond PostgreSQL numeric limits can't be stored in jsonb
    my $literal = $value =~ /^(?:true|false)\z/
      || (  $value =~ /^-?(0|[1-9][0-9]*)(?:\.([0-9]+))?\z/
        and length($1) <= 131072
        and length( $2 // '' ) <= 16383 );
    my @docs = ( to_json( { $dfield => "$dvalue" } ) );
    push @docs, '{' . to_json( "$dfield", { allow_nonref => 1 } ) . ":$value}"
      if ($literal);

    # JSON::PP doesn't flag its result as UTF-8 when it holds only Latin-1
    # characters: DBD::Pg would then send Latin-1 bytes
    utf8::upgrade($_) foreach (@docs);
    return {
        query => '('
          . join( ' OR ', ('a_session @> ?::jsonb') x @docs )
          . ") AND $f =?",
        values => [ @docs, $value ],
    };
}

# The "a_session @> ..." conditions need a jsonb column: with a json column
# every searchOn() would fail. Look the type up once per handle and table,
# warn and fall back to the plain query when it is not jsonb. An unknown type
# (table not created yet) isn't cached. $dbh (required) is the handle of the
# caller's query, from _borrowDbh(): the caller keeps the loan until its query
# is done.
sub _jsonbColumn {
    my ( $class, $args, $dbh ) = @_;
    my $table = $args->{TableName} || $Apache::Session::Store::DBI::TableName;
    my $cache = $dbh->{private_asb_pgjson_type} ||= {};
    unless ( defined $cache->{$table} ) {
        ( $cache->{$table} ) = $dbh->selectrow_array(
            q{SELECT t.typname FROM pg_attribute a
                JOIN pg_type t ON t.oid = a.atttypid
               WHERE a.attrelid = to_regclass(?) AND a.attname = 'a_session'
                 AND NOT a.attisdropped},
            undef, $table
        );
        warn "GinIndex ignored: $table.a_session is not jsonb\n"
          unless ( $cache->{$table} || '' ) eq 'jsonb';
    }
    return ( $cache->{$table} || '' ) eq 'jsonb';
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    $value =~ s/\*/%/g;
    my $query = {
        query  => $class->_sqlField($selectField) . ' like ?',
        values => [$value]
    };
    return $class->_query( $args, $query, @fields );
}

sub searchLt {
    my $class = shift;
    return $class->_searchCompare( '<', @_ );
}

sub searchGt {
    my $class = shift;
    return $class->_searchCompare( '>', @_ );
}

# $value is checked, then inserted like deleteIfLowerThan() thresholds: bound,
# it would be typed bigint and decimal values would fail
sub _searchCompare {
    my ( $class, $op, $args, $selectField, $value, @fields ) = @_;
    $value =
      Web::Session::_common->_checkSearchValue( $op, $value );
    return {} unless ( defined $value );
    my $query = {
        query  => $class->_buildCompareExpression( $selectField, $op, $value ),
        values => []
    };
    return Web::Session::_common->_searchQuery(
        $op,
        sub { $class->_query( $args, $query, @fields ) },
        sub {
            Web::Session::_common::_searchByTest( $class, $args, $selectField,
                Web::Session::_common->_compareTest( $op, $value ), @fields );
        }
    );
}

sub _query {
    my ( $class, $args, $query, @fields ) = @_;
    my ( $dbh, $loan ) = $class->_borrowDbh($args);
    return $class->_queryDbh( $dbh, $args, $query, @fields );
}

# Same as _query() with an already connected handle
sub _queryDbh {
    my ( $class, $dbh, $args, $query, @fields ) = @_;
    my %res = ();

    my $table_name =
      Web::Session::_common->_tableName( $dbh, $args );

    my $sth;
    my $fields =
      @fields
      ? join( ',',
        'id',
        map { $class->_sqlField($_) . ' AS ' . $class->_sqlAlias($_) } @fields )
      : '*';
    $sth =
      $dbh->prepare("SELECT $fields from $table_name where $query->{query}");
    $sth->execute( @{ $query->{values} } );

    my $res = $sth->fetchall_hashref('id') or return {};
    unless (@fields) {
        my $sub = Web::Session::_common::_unserializer($class);
        foreach my $s ( keys %$res ) {
            eval {
                my $tmp = &$sub( { serialized => $res->{$s}->{a_session} } );
                $res->{$s} = $tmp;
            };
            if ($@) {
                print STDERR "Error in session $s: $@\n";
                delete $res->{$s};
            }
        }
    }
    return $res;
}

sub deleteIfLowerThan {
    my ( $class, $args, $rule ) = @_;
    return wantarray ? ( 0, 0 ) : 0
      unless ( Web::Session::_common->_checkRule($rule)
        and Web::Session::_common->_checkThresholds($rule) );
    my ( $query, @bind );
    if ( $rule->{or} ) {
        $query = join ' OR ', map {
            $class->_buildLowerThanExpression( $_, $rule->{or}->{$_} )
          }
          keys %{ $rule->{or} };
    }
    elsif ( $rule->{and} ) {
        $query = join ' AND ', map {
            $class->_buildLowerThanExpression( $_, $rule->{and}->{$_} )
          }
          keys %{ $rule->{and} };
    }
    return wantarray ? ( 0, 0 ) : 0 unless ($query);
    if ( $rule->{not} and keys %{ $rule->{not} } ) {
        $query = "($query) AND " . join(
            ' AND ',
            map {
                push @bind, $rule->{not}->{$_};
                my $f = $class->_sqlField($_);
                "($f IS NULL OR $f <> ?)"
              }
              keys %{ $rule->{not} }
        );
    }

    # Delete by batches: a single DELETE on hundreds of thousands of sessions
    # is one long transaction (WAL spike, locks held, replication lag). Each
    # batch is its own statement (class methods' connections are AutoCommit).
    # The WHERE expression is the same as before, so the expression indexes
    # are still usable by the sub-select. Rows deleted by a concurrent purge
    # are simply not counted.
    my $total = 0;
    my $ok    = eval {

        # Held for all the batches. A pooled connection is given back when
        # $loan goes out of scope, also when a batch dies (it is then closed:
        # see _flagError() in Store/Postgres.pm)
        my ( $dbh, $loan ) = $class->_borrowDbh($args);
        my $table_name =
          Web::Session::_common->_tableName( $dbh, $args );
        my $limit = Web::Session::_common->_batchSize;
        my $sql = $class->_deleteBatchStatement( $table_name, $query, $limit );
        while (1) {
            my $n = $dbh->do( $sql, undef, @bind );
            return 0 unless defined $n;

            # Count unknown to the driver: a short batch can't be detected,
            # go on while a session still matches
            if ( $n == -1 ) {
                last
                  unless $dbh->selectrow_array(
                    "SELECT 1 FROM $table_name WHERE $query LIMIT 1",
                    undef, @bind );
                next;
            }
            $total += $n;

            # A short batch means that nothing else matches (an exact
            # multiple of the batch size costs one more, empty, batch)
            last if $n < $limit;
        }
        1;
    };
    unless ($ok) {
        print STDERR "deleteIfLowerThan: $@\n" if ($@);
        return wantarray ? ( 0, $total ) : 0;
    }
    return wantarray ? ( 1, $total ) : 1;
}

# Statement of one batch of deleteIfLowerThan(), $where being the rule
sub _deleteBatchStatement {
    my ( $class, $table_name, $where, $limit ) = @_;
    return "DELETE FROM $table_name WHERE id IN "
      . "(SELECT id FROM $table_name WHERE $where LIMIT $limit)";
}

sub get_key_from_all_sessions {
    my ( $class, $args, $data ) = @_;

    # Held until the end of the call, callbacks included: a callback that
    # ties a session or calls a class method gets another connection of the
    # pool, never this one (lent, it is not idle). $loan gives it back when
    # this method returns or dies
    my ( $dbh, $loan ) = $class->_borrowDbh($args);
    my $table_name =
      Web::Session::_common->_tableName( $dbh, $args );
    my $sth;

    # Special case if all wanted fields are indexed
    if ( $data and ref($data) ne 'CODE' ) {
        $data = [$data] unless ( ref($data) );
        my $fields = join ',', 'id',
          map { $class->_sqlField($_) . ' AS ' . $class->_sqlAlias($_) } @$data;
        $sth = $dbh->prepare("SELECT $fields from $table_name");
        $sth->execute;
        return $sth->fetchall_hashref('id');
    }
    my %res;
    my $sub = Web::Session::_common::_unserializer($class);
    Web::Session::_common->_forEachSession(
        $dbh,
        $table_name,
        sub {
            my @row = @_;
            eval {
                my $tmp = &$sub( { serialized => $row[1] } );
                if ( ref($data) eq 'CODE' ) {
                    $tmp = &$data( $tmp, $row[0] );
                    $res{ $row[0] } = $tmp if ( defined($tmp) );
                }
                elsif ($data) {
                    $data = [$data] unless ( ref($data) );
                    $res{ $row[0] }->{$_} = $tmp->{$_} foreach (@$data);
                }
                else {
                    $res{ $row[0] } = $tmp;
                }
            };
            if ($@) {
                print STDERR "Error in session $row[0]: $@\n";
                delete $res{ $row[0] };
            }
        }
    );
    return \%res;
}

sub _buildLowerThanExpression {
    my ( $class, $field, $value ) = @_;
    return $class->_buildCompareExpression( $field, '<', $value );
}

# Must match the documented expression indexes (_utime, _lastSeen). $op is
# "<" or ">", $value a number checked by the caller
sub _buildCompareExpression {
    my ( $class, $field, $op, $value ) = @_;
    Web::Session::_common->_checkOp($op);
    my $f = $class->_sqlField($field);
    return "cast($f as bigint) $op $value";
}

# Build SQL expression to get a field from a_session
sub _sqlField {
    my ( $class, $field ) = @_;

    # With standard_conforming_strings=off, backslashes are escape characters
    # in plain literals: use an escape string literal in this case
    if ( $field =~ /\\/ ) {
        $field =~ s/(['\\])/$1$1/g;
        return "a_session ->> E'$field'";
    }
    $field =~ s/'/''/g;
    return "a_session ->> '$field'";
}

# Build a column alias that preserves field name case
sub _sqlAlias {
    my ( $class, $field ) = @_;
    $field =~ s/"/""/g;
    return qq{"$field"};
}

# Connection of a class method: returns ( $dbh, $loan ). Keep $loan until
# the handle is no longer needed: when the connection pool of
# Web::Session::Store::Postgres applies (see _classPool()), $dbh is lent by
# the pool and given back when $loan is freed, so at the end of the call,
# also when it dies. Otherwise $dbh is the handle of _classDbh() and $loan is
# undef.
sub _borrowDbh {
    my ( $class, $args ) = @_;
    return ( $class->_classDbh($args), undef )
      unless ( $class->_classPool($args) );
    $args->{DataSource} or die "No datasource given !";
    my $loan = Web::Session::Store::Postgres->_lend($args);
    return ( $loan->{dbh}, $loan );
}

# Whether class methods borrow their connection from the pool: with the
# arguments that make sessions use it (see _poolApplies() in
# Store/Postgres.pm). A subclass whose sessions don't use the pool overrides
# it (Web::Session::Patroni)
sub _classPool {
    my ( $class, $args ) = @_;
    return Web::Session::Store::Postgres::_poolApplies($args);
}

# Handle cached by DBI connect_cached(), used by class methods when the pool
# doesn't apply (see _borrowDbh())
sub _classDbh {
    my ( $class, $args ) = @_;

    my $datasource = $args->{DataSource} or die "No datasource given !";
    my $username   = $args->{UserName};
    my $password   = $args->{Password};
    my $dbh =
      DBI->connect_cached( $datasource, $username, $password,
        Web::Session::_common->_forkSafeAttr(
            { RaiseError => 1, AutoCommit => 1 }
        )
      )
      || die $DBI::errstr;
    $dbh->{pg_enable_utf8} = 1;
    return $dbh;
}

1;
__END__

=head1 NAME

Web::Session::PgJSON - Add index and search methods to
Apache::Session for PostgreSQL, using a JSON column

=head1 SYNOPSIS

Create table:

  CREATE UNLOGGED TABLE sessions (
      id varchar(64) not null primary key,
      a_session jsonb
  );

C<UNLOGGED> tables are lost on a crash and not replicated to standby servers:
see L</POSTGRESQL TUNING>.

Optionally, add indexes on some fields. Example for Lemonldap::NG:

  CREATE INDEX uid1 ON sessions USING BTREE
    ( (a_session ->> '_whatToTrace') text_pattern_ops );
  CREATE INDEX  s1  ON sessions ( (a_session ->> '_session_kind') );
  CREATE INDEX  u1  ON sessions ( ( cast(a_session ->> '_utime' AS bigint) ) );
  CREATE INDEX ls1  ON sessions
    ( ( cast(a_session ->> '_lastSeen' AS bigint) ) );
  CREATE INDEX rt1  ON sessions
    ( ( cast(a_session ->> '_oidcRtUpdate' AS bigint) ) );
  CREATE INDEX ip1  ON sessions USING BTREE
    ( (a_session ->> 'ipAddr') text_pattern_ops );

searchOnExpr() uses C<LIKE 'prefix%'> queries: unless the database uses the
"C" collation, PostgreSQL can't use a plain btree index for them. The
C<text_pattern_ops> operator class lets the same index serve both C<=> and
prefix C<LIKE> searches. Note that a search starting with a C<*> wildcard can
never use a btree index.

deleteIfLowerThan() can use C<u1> and C<ls1> indexes only if they are declared
exactly as above. C<ls1> is needed when Lemonldap::NG "timeoutActivity" is
used: sessions purge then deletes sessions whose C<_utime> B<or> C<_lastSeen>
is too old, and an C<OR> with a non indexed side forces a full table scan.

C<rt1> is useful when OpenID Connect relying parties have a refresh token
activity timeout: sessions purge then calls searchLt() on C<_oidcRtUpdate>,
which can use this index only if it is declared exactly as above.

Avoid a global C<GIN (a_session jsonb_path_ops)> index: queries of this module
don't use the C<@E<gt>> operator, so it is never used. Measured on 300,000
realistic Lemonldap::NG sessions, it took 167 MB (versus 15 MB for the C<uid1>,
C<s1>, C<u1> and C<ip1> btree indexes above) and made updates about 3 times
slower.

A single GIN index can replace the btree indexes used only for equality
searches (like C<s1>), but it is much bigger and slows down updates: see
L</GIN INDEX>.

Don't set C<Index>: any field can be searched. Use it like the other backends
of L<Web::Session>. L<Web::Session::Postgres> is
an alias of this module.

=head1 DESCRIPTION

Web::Session provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

Web::Session::PgJSON implements it for PosqtgreSQL databases
using "json" or "jsonb" type to be able to browse sessions. The C<GinIndex>
option requires "jsonb".

=head1 GIN INDEX

Instead of one btree index per searched field, one GIN index can serve
searchOn() on B<any> field:

  CREATE INDEX gin1 ON sessions USING GIN (a_session jsonb_path_ops);

It is used only if C<GinIndex> is set in the arguments (for Lemonldap::NG, in
sessions storage options):

  GinIndex => 1,

searchOn() then adds a C<a_session @E<gt> '{"field":"value"}'> condition, the
only kind of query this index can serve. The C<@E<gt>> operator and the
C<jsonb_path_ops> operator class exist only for "jsonb": with a "json"
column, the index can't be created: C<GinIndex> is then ignored, with a
warning, and searchOn() falls back to the query used without the option. The
warning is emitted once per database handle (so once per process and
connection, also for each connection of the pool) and table. To use the
index, convert the column first:

  ALTER TABLE sessions ALTER COLUMN a_session TYPE jsonb
    USING a_session::jsonb;

This rewrites the whole table under an C<ACCESS EXCLUSIVE> lock: sessions are
blocked during the conversion. It fails if a session contains C<\u0000>
(accepted by "json", refused by "jsonb"). The column type is cached per
database handle and table: processes already connected must be restarted (or
reconnect) after the conversion, else they keep ignoring C<GinIndex> (pooled
connections are renewed after C<MaxLifetime>, see below).

Results are the same as without C<GinIndex>:

=over

=item * Containment is type sensitive while the C<-E<gt>E<gt>> operator used
without C<GinIndex> is not: searching C<123> finds both the string C<"123">
and the number C<123> (like C<_utime>). So a value that looks like a JSON
number or boolean is searched in both forms, with two index scans combined by
a C<BitmapOr>.

=item * The C<-E<gt>E<gt>> comparison is kept to filter the rows found by the
index: for example, C<{"k":1.50}> contains C<{"k":1.5}> but searching C<1.5>
must not find C<1.50>.

=item * Numbers beyond PostgreSQL numeric limits (more than 131072 digits
before the decimal point or 16383 after) can't be stored in "jsonb": such
values are searched as strings only.

=item * Values starting with C<[> or C<{> (possible text of JSON arrays and
objects) and values or field names containing a NUL character are searched
without the GIN index.

=back

Measured on PostgreSQL 17 with 300,000 realistic Lemonldap::NG sessions
(391 MB table):

=over

=item * the GIN index takes 167 MB, versus 15 MB for the C<uid1>, C<s1>,
C<u1> and C<ip1> btree indexes above;

=item * searchOn() lookups through the GIN index or through a btree index are
comparable, well under 1 ms. The gain is on fields without btree index:
0.04 ms instead of a 30 ms full table scan;

=item * updating 30,000 sessions takes 6.3 s with the GIN index, versus 1.9 s
without it (about 3 times slower). The 4 btree indexes above were present in
both runs.

=back

Sessions are updated often (C<_utime>, C<_lastSeen>), so this write cost
usually outweighs the lookup gain. The GIN index is interesting when searchOn()
is used on many fields that have no btree index. Enabling C<GinIndex> without
the index only adds useless conditions.

The GIN index doesn't help searchOnExpr() (C<LIKE>), deleteIfLowerThan()
(C<E<lt>> comparisons, and C<not> rules that must also match sessions without
the field) nor get_key_from_all_sessions(). Keep the C<uid1>, C<u1>, C<ls1>
and C<ip1> btree indexes above alongside it; C<s1> is not needed anymore.
PostgreSQL may still prefer a btree index on the searched field, or a full
scan for a frequent value like C<_session_kind = 'SSO'>.

=head2 deleteIfLowerThan()

Sessions are deleted by batches, each batch being its own statement
(autocommit), to avoid one huge transaction when a purge removes hundreds of
thousands of sessions (WAL spike, long locks, replication lag):

  DELETE FROM sessions WHERE id IN
    (SELECT id FROM sessions WHERE <rule> LIMIT n)

until a batch deletes less than C<n> rows. The C<WHERE> expression is the same
as for a single statement, so the indexes described above are still used by the
sub-select. C<n> is C<$Web::Session::_common::BatchSize> (1000 by default,
accepted values: 1 to 1000000), the same variable that sets the size of the
batches of get_key_from_all_sessions().

The return value is unchanged: C<(1, $deleted)> in list context, C<1> in
scalar context. If a batch fails, the error is printed on STDERR and
C<(0, $deleted)> is returned in list context (C<0> in scalar context),
C<$deleted> being the number of sessions removed by the batches already
executed, which stay committed (as L<Web::Session::LDAP> does). The first
value stays false, so a caller such as the Lemonldap::NG purge still sees the
failure and falls back to its slower purge. This also applies to
L<Web::Session::Postgres> aliases and L<Web::Session::Patroni>.

=head2 searchLt() and searchGt()

  # Sessions whose _utime is lower than $time
  my $hash = Web::Session::PgJSON->searchLt( $args,
      '_utime', $time, 'uid' );

searchLt() and searchGt() take the same arguments and return the same data as
searchOn(): sessions whose field is lower (or greater) than the given value,
which is excluded. The value must be a number (C<12>, C<-12> or C<12.5>):
otherwise nothing is returned and an error is printed on STDERR. Spaces
around the value are ignored.

Fields are compared in SQL as deleteIfLowerThan() does
(C<cast(a_session -E<gt>E<gt> 'field' AS bigint)>): an expression index
declared exactly as C<u1> or C<rt1> above is used with an integer value. As
for deleteIfLowerThan(), the query fails if it reads a session where this
field is not an integer (such an index refuses to store it): searchLt() and
searchGt() then print the error on STDERR and compare all sessions in Perl,
see "ERRORS" in L<Web::Session>.

Sessions without the field are never returned. This differs from the Perl
fallback of Lemonldap::NG, where a missing field is compared as 0: searchLt()
would then return nearly all sessions. Lemonldap::NG doesn't need them: its
sessions purge ignores sessions without C<_oidcRtUpdate>.

=head2 Persistent connection

Database connections are kept open between sessions, managed by the
connection pool described below. With C<Commit =E<gt> 0> or
C<KeepConnections =E<gt> 0>, sessions use the handle shared by the sessions
of the process, like the other SQL backends, see
L<Web::Session/"PERSISTENT DATABASE CONNECTIONS">. Set C<noreuse =E<gt> 1> to
open and close one connection for each session instead.

=head2 Connection pool (KeepConnections)

By default, sessions use a pool of connections: each process keeps up to
C<MaxIdle> idle connections per data source (C<DataSource> and C<UserName>),
and lends each one to a single tied session at a time. The pool is not used
with C<Commit =E<gt> 0>, with C<noreuse> or with a C<Handle>.

Class methods (searchOn(), searchOnExpr(), searchLt(), searchGt(),
get_key_from_all_sessions() and deleteIfLowerThan()) called with the same
arguments use the same pool: each call borrows a connection and gives it back
when it returns. A process that uses both sessions and class methods (for
example a Lemonldap::NG portal, whose C<SingleSession> feature calls
searchOn(), or the sessions purge, which calls deleteIfLowerThan()) thus
doesn't keep one more connection for the class methods. The rules of the
pool apply to these connections too: a connection that met an error is
closed, expired ones are renewed, a child process doesn't use those of its
parent.

A callback given to get_key_from_all_sessions() runs while the call holds its
connection: if it ties a session or calls a class method, they get another
connection of the pool (or open one), never the one of the running call. The
connection is given back even if the query or the callback dies. Each
nesting level holds one more connection while it runs, and the pool sets no
limit: a callback that calls get_key_from_all_sessions() again, or keeps
several sessions tied, needs as many connections at once. Keep callbacks
flat (collect the ids, then work on them after the call) when the server has
a low C<max_connections>.

Without the pool (C<Commit =E<gt> 0>, C<KeepConnections =E<gt> 0> or
C<noreuse>), class methods use the handle cached by DBI C<connect_cached()>,
as before. They never use the C<Handle> argument.

Why a pool rather than the DBI C<connect_cached()> handle used by the other
SQL backends:

=over

=item * Two sessions tied at the same time in a process (for example a
Lemonldap::NG session and its persistent session) never share a connection,
and so never a transaction. With a shared handle, they share its transaction
(C<AutoCommit> off): untying one of them also commits (or rolls back) the
changes already done in the other.

=item * Error handling: a connection that met an error is closed, never lent
again. For example, after a failover behind a virtual IP, a connection to the
former primary still answers C<ping()> but every write fails.

=item * Timeouts: a connection idle for too long is closed without a
C<ping()>, which could wait for a TCP timeout on a connection dropped by a
NAT or a load balancer; a connection is renewed after a maximum lifetime.

=item * Fork safety: connections are opened with C<AutoInactiveDestroy> and
belong to the process that opened them. A child created by C<fork()> neither
uses nor closes the connections of its parent, even one that was lent when it
forked.

=back

Options:

=over

=item KeepConnections

Set C<KeepConnections =E<gt> 0> to disable the pool and get back the previous
behaviour: the handle cached by DBI C<connect_cached()>, shared by the
sessions of the process, with C<AutoCommit> off and a transaction committed at
untie. Accepted values: C<0> (or C<'0'>) disables the pool; a missing,
C<undef> or empty value keeps the default (enabled); any other value enables
it. Strings such as C<'0.0'>, C<'off'> or C<'false'> are not C<0> and so
enable the pool: use C<0>.

=item MaxIdle

Idle connections kept per process and data source, 4 by default. C<0> closes
each connection at untie. Size the C<max_connections> of the server for all
the processes: each one keeps up to C<MaxIdle> idle connections, plus one per
session tied at the moment. For example, 3 servers with 50 Apache or FastCGI
workers each and the default C<MaxIdle> may keep C<3 * 50 * 4 = 600>
connections open, more during peaks. Lower C<MaxIdle> (1 is enough when a
worker handles one request at a time), or put a pooler in front of the
server (see L</Connection poolers (PgBouncer)>).

=item IdleTimeout

Seconds: a connection idle for longer is closed instead of being lent
(without a C<ping()>), 120 by default. Adding C<keepalives_idle> to the DSN
also helps detect dead connections.

=item MaxLifetime

Seconds: an older connection is closed when it is given back, 3600 by
default.

=back

On these connections each statement is its own transaction (C<AutoCommit>
on): no session is locked, so a transaction around a tie protected nothing.
Expired idle connections are closed when another connection is given back. A
connection given back recently is lent without a round trip; an older one is
checked with C<ping()>.

C<Commit> is on by default (as with L<Web::Session::Patroni>): a missing or
empty C<Commit> commits the writes, a session isn't rolled back at untie for
lack of this option. With C<Commit =E<gt> 0>, changes are rolled back at
untie, which the pool can't do: the store then keeps C<AutoCommit> off on the
shared handle. With a C<Handle>, the caller owns the transaction: C<Commit>
is used as given (not set means not committed), as with
L<Apache::Session::Postgres>.

A new session is written once. Without the pool, as with L<Apache::Session>,
the tie of a new session inserts it with its empty data, and its untie updates
it with its data: two writes, the second one a new row version and an entry in
each index. With the pool, the INSERT waits for the untie and writes the data
then; a session untied unmodified is inserted at untie (one still tied when
the program ends is inserted by an C<END> block, before the global
destruction; a child process created by C<fork()> leaves those of its parent
to it), and a session deleted in its own tie is never written. The connection
is still taken when the session is tied, so an unreachable database still
makes the tie fail. When the id of the new session is given by the caller
(C<setId>, as Lemonldap::NG does), the tie checks that no session has it, and
dies if one does, as the INSERT at tie does without the pool. If another
process inserts this id between the tie and the untie, the INSERT fails: it is
reported as a failed update (an explicit save() dies; at untie,
L<Apache::Session> doesn't propagate the error, DBI warns and the INSERT is
tried again when the store is freed, with a warning if it fails again), and
the other session is left untouched, also when the new one is deleted in its
tie. Until its untie, a new session can't be read nor found by another
process.
L<Web::Session::Patroni> doesn't defer the INSERT: it inserts a new session
when it is tied, then updates it at untie.

Example with Lemonldap::NG (the pool is used, no option needed):

  globalStorage        => 'Web::Session::PgJSON',
  globalStorageOptions => {
      DataSource => 'dbi:Pg:dbname=sessions;host=db;keepalives_idle=30',
      UserName   => 'lemonldap',
      Password   => 'secret',
      TableName  => 'sessions',
      Commit     => 1,
  },

Add C<KeepConnections =E<gt> 0> to these options to get back the shared
C<connect_cached()> handle, or C<noreuse =E<gt> 1> to open and close a
connection for each session.

L<Web::Session::Patroni> sessions use this pool too, keyed by the DSN of the
primary node found through the Patroni API, see "Connection pool" in
L<Web::Session::Patroni>. Its class methods don't: they keep the
C<connect_cached()> handle, see "Class methods" in L<Web::Session::Patroni>.

=head1 POSTGRESQL TUNING

=head2 Use "jsonb"

Prefer C<jsonb> to C<json>. A C<json> column stores the text as received, so
each C<-E<gt>E<gt>> is evaluated by parsing the document again, for each row
read: searches on a field without index, sessions purge,
get_key_from_all_sessions() and so on. C<jsonb> is stored in a decomposed
binary form and doesn't need this parsing. Expression indexes (C<u1>, C<s1>...
above) work with both types, but C<GinIndex> requires C<jsonb>. C<jsonb>
refuses the C<\u0000> character that C<json> accepts: to convert an existing
table, see the C<ALTER TABLE> command (and its lock and failure cases) in
L</GIN INDEX>.

=head2 Updates and autovacuum

Sessions are updated often (C<_utime>, C<_lastSeen>). In PostgreSQL, each
C<UPDATE> creates a new version of the row and leaves the old one as a dead
tuple until (auto)vacuum removes it. Purge also leaves dead tuples. Moreover
PostgreSQL can make an update HOT (heap-only tuple, the indexes are not
touched) only if the B<columns> used by the indexes keep the same stored
value: it compares the column values, it doesn't evaluate the indexed
expressions. The expression indexes above all use C<a_session>, so an update
that changes the session (C<_utime>, C<_lastSeen>...) is never HOT: it adds an
entry to each index, including the primary key. This is also why the number
of indexes directly drives the update cost (see the measures in
L</GIN INDEX>): keep only the indexes you really use.

For the same reason, lowering C<fillfactor> (which leaves free room in pages
for HOT updates) brings little here as soon as the table has expression
indexes on C<a_session>: only updates that write the session back unchanged
can be HOT. It may help for a table that has only its primary key.

A busy sessions table is better vacuumed more often than the default
(20% of dead rows) allows. Per-table settings can be used without changing the
configuration of the other tables:

  ALTER TABLE sessions SET (
      autovacuum_vacuum_scale_factor  = 0.02,
      autovacuum_analyze_scale_factor = 0.05,
      autovacuum_vacuum_cost_limit    = 1000
  );

The scale factors make autovacuum start after 2% of dead rows (5% of changes
for statistics) instead of 20% (10% for statistics). A higher
C<autovacuum_vacuum_cost_limit> (by default the global C<vacuum_cost_limit>,
200) lets each run work faster, at the price of more I/O. These values are a
starting point: check C<n_dead_tup>, C<last_autovacuum> and the table size in
C<pg_stat_user_tables> and adjust.

=head2 UNLOGGED table

An C<UNLOGGED> table isn't written to the write-ahead log: writes are faster,
but

=over

=item * the table is emptied after a crash or an unclean shutdown (a clean
restart keeps it): all users have to authenticate again;

=item * it isn't replicated to standby servers (and can't be read on a
standby). After a failover (for example with L<Web::Session::Patroni>), the
new primary has an empty sessions table.

=back

If sessions must survive a crash or a failover, create a normal table (or
convert it with C<ALTER TABLE sessions SET LOGGED>, which rewrites the table).
You then pay the WAL volume of the frequent updates, on the primary and on
each replica.

=head2 Connection poolers (PgBouncer)

L<DBD::Pg> uses server-side prepared statements by default
(C<pg_server_prepare>). With PgBouncer in C<transaction> pooling mode, the
server connection may change between two statements, so a statement prepared
earlier can be missing (C<prepared statement "dbdpg_p..." does not exist>).
PgBouncer 1.21 and later can track them if C<max_prepared_statements> is set to
a non-zero value; with older versions, or without it, disable server-side
prepared statements. The module gives C<DataSource> to C<DBI-E<gt>connect()>
as is, so the attribute can be set in the DSN, using the DBI syntax for
attributes:

  DataSource => 'dbi:Pg(pg_server_prepare=>0):dbname=sessions;host=pgbouncer',

Without a pooler in transaction mode, keep the default (prepared statements
save parsing time). Note that the connection pool described in
L</Connection pool (KeepConnections)> already avoids reconnecting for each
session: a pooler is mostly useful to limit the total number of connections
when many processes (each with up to C<MaxIdle> connections) use the same
server.

=head2 Detecting dead connections

A connection broken without being closed (firewall or NAT timeout, host
down, failover) is detected by the kernel only after a long time by default
(on Linux, 2 hours before the first keepalive probe). libpq parameters can be
set in the DSN to detect it sooner on TCP connections:

  DataSource => 'dbi:Pg:dbname=sessions;host=db;'
              . 'keepalives_idle=30;keepalives_interval=10;keepalives_count=3',

With these values, a dead peer is detected after about
C<30 + 10 * 3 = 60> seconds. Where supported, C<tcp_user_timeout> (in
milliseconds) also bounds the time to wait for unacknowledged data. This
doesn't apply to Unix socket connections.

=head2 Purge

Lemonldap::NG removes expired sessions with a periodic purge that uses
deleteIfLowerThan() and searchLt(). Indexes must be declared exactly as
explained in L</SYNOPSIS> (C<u1>, C<ls1>, C<rt1>), else each run reads the
whole table. A purge run after a long delay deletes many rows at once and
leaves as many dead tuples for autovacuum: run it regularly, with the
autovacuum settings above.

=head1 SEE ALSO

L<http://lemonldap-ng.org>, L<Apache::Session::Postgres>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2026 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
