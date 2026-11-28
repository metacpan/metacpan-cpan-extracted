package Web::Session::_common;

use strict;
use AutoLoader 'AUTOLOAD';

our $VERSION = '1.0.0';

# Number of sessions read per query by _forEachSession(). Values outside
# 1..1_000_000 fall back to the default (a huge value would break LIMIT)
our $BatchSize = 1000;

# Attributes of the handles used by class methods (searchOn(), ...), made fork
# safe. These handles are shared through DBI->connect_cached(): in a pre-fork
# server, if the parent called a class method before forking, every child
# would get the parent's handle, so its socket: concurrent use corrupts the
# protocol and a child exiting closes the parent's server connection.
# - private_ws_pid: connect_cached() uses the attributes as part of its cache
#   key, so each process gets (and caches) its own handle
# - AutoInactiveDestroy: a handle inherited from the parent is not closed on
#   the server when the child destroys it
# Threads (ithreads) share the pid, but each one has its own interpreter, so
# its own connect_cached() cache: a handle is never shared between threads.
# A store connected before a fork is handled by _forgetInheritedHandle() in
# Store/DBI.pm
sub _forkSafeAttr {
    my ( $class, $attr ) = @_;
    return { %$attr, AutoInactiveDestroy => 1, private_ws_pid => $$ };
}

sub _tabInTab {
    my ( $class, $t1, $t2 ) = @_;

    # if no fields are required, return 0
    return 0 unless ( @$t1 and @$t2 );
    foreach my $f (@$t1) {
        unless ( grep { $_ eq $f } @$t2 ) {
            return 0;
        }
    }
    return 1;
}

sub _fieldIsIndexed {
    my ( $class, $args, $field ) = @_;
    my $index =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    return ( grep { $_ eq $field } @$index );
}

# Check the structure of a deleteIfLowerThan() rule
sub _checkRule {
    my ( $class, $rule ) = @_;
    unless ( ref($rule) eq 'HASH' ) {
        print STDERR "deleteIfLowerThan: rule must be a hash reference\n";
        return 0;
    }
    foreach my $type (qw(or and not)) {
        next unless defined $rule->{$type};
        unless ( ref( $rule->{$type} ) eq 'HASH' ) {
            print STDERR "deleteIfLowerThan: $type must be a hash reference\n";
            return 0;
        }
    }
    return 1;
}

# deleteIfLowerThan() thresholds are inserted into SQL queries, so they must
# be numbers
sub _checkThresholds {
    my ( $class, $rule ) = @_;
    return 1 unless ( ref($rule) eq 'HASH' );
    my $thresholds = $rule->{or} || $rule->{and};
    return 1 unless ( ref($thresholds) eq 'HASH' );
    foreach ( values %$thresholds ) {
        unless ( $class->_isNumber($_) ) {
            print STDERR "deleteIfLowerThan: threshold must be a number\n";
            return 0;
        }
    }
    return 1;
}

# Identifier (table or column name) inserted into an SQL query. It is quoted
# with the driver's quote_identifier() when the driver supports it the
# standard way. PostgreSQL folds unquoted names to lower case, so tables and
# columns created without quotes have lower case names: the name is
# lowercased before being quoted, which keeps the previous behaviour for
# names in mixed case (TableName => 'Sessions' still finds "sessions"). A
# "schema.table" name is quoted part by part, and a name that already
# contains quotes is left unchanged. Other drivers get the name as before:
# quoting could change its case or meaning there
sub _quoteIdentifier {
    my ( $class, $dbh, $name ) = @_;
    my $driver = $dbh->{Driver}->{Name};
    unless ( $driver =~ /^(?:Pg|mysql|MariaDB|SQLite)\z/ ) {
        $name =~ s/'/''/g;
        return $name;
    }
    return $name      if ( $name =~ /["`]/ );
    $name = lc($name) if ( $driver eq 'Pg' );
    return join '.', map { $dbh->quote_identifier($_) } split /\./, $name, -1;
}

# Column of an indexed field in SQL queries. Callers check Index with the
# field name, then insert the result of this method: backends that need
# another quoting override it
sub _quoteColumn {
    my ( $class, $dbh, $field ) = @_;
    return $class->_quoteIdentifier( $dbh, $field );
}

# Quoted table name, see _quoteIdentifier()
sub _tableName {
    my ( $class, $dbh, $args ) = @_;
    return $class->_quoteIdentifier( $dbh,
        $args->{TableName} || $Apache::Session::Store::DBI::TableName );
}

# Digits are bounded: MySQL rejects out-of-range literals
sub _isNumber {
    my ( $class, $value ) = @_;
    return ( defined($value)
          and $value =~ /^-?[0-9]{1,20}(?:\.[0-9]{1,20})?\z/ );
}

# The operator of a comparison is inserted into SQL queries
sub _checkOp {
    my ( $class, $op ) = @_;
    die "_buildCompareExpression: invalid operator '"
      . ( defined $op ? $op : 'undef' ) . "'\n"
      unless ( defined $op and ( $op eq '<' or $op eq '>' ) );
    return $op;
}

# searchLt() and searchGt() values are also inserted into SQL queries. Return
# the value without surrounding spaces (kept by the Lemonldap::NG CLI), or
# undef if it isn't a number
sub _checkSearchValue {
    my ( $class, $op, $value ) = @_;
    $value =~ s/^\s+|\s+\z//g if ( defined $value );
    unless ( $class->_isNumber($value) ) {
        print STDERR 'search'
          . ( $op eq '<' ? 'Lt' : 'Gt' )
          . ": value must be a number\n";
        return undef;
    }
    return $value;
}

# Run the SQL query $sub of searchLt() and searchGt(). The database may
# reject the comparison: a cast fails as soon as one session has a value that
# isn't an integer. The error is printed, then $scan compares the sessions in
# Perl, as the generic search of Lemonldap::NG does. {} if the scan fails
# too: these methods don't die (see "ERRORS" in Web::Session)
sub _searchQuery {
    my ( $class, $op, $sub, $scan ) = @_;
    my $name = 'search' . ( $op eq '<' ? 'Lt' : 'Gt' );
    my $res  = eval { $sub->() };
    return $res unless ($@);
    my $err = $@;
    chomp $err;
    print STDERR "$name: $err\n";
    return {} unless ($scan);
    print STDERR "$name: comparing all sessions in Perl instead\n";
    $res = eval { $scan->() };
    return $res unless ($@);
    $err = $@;
    chomp $err;
    print STDERR "$name: $err\n";
    return {};
}

# Perl test of searchLt() and searchGt(), for _searchByTest(). Sessions
# without the field are skipped, as by the SQL comparison
sub _compareTest {
    my ( $class, $op, $value ) = @_;
    return $op eq '<'
      ? sub { defined( $_[0] ) and $_[0] < $value }
      : sub { defined( $_[0] ) and $_[0] > $value };
}

# Perl version of searchLt() and searchGt(): read all sessions and keep those
# for which $test->( value of $selectField ) is true. As in SQL, a value that
# doesn't start with a number is 0: Perl would read "inf" or "nan" as
# Infinity and NaN
sub _searchByTest {
    my ( $class, $args, $selectField, $test, @fields ) = @_;
    my %res;
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my ( $entry, $id ) = @_;
            my $v = $entry->{$selectField};
            $v = 0 if ( defined $v and $v !~ /^\s*-?[0-9]/ );
            return undef unless ( $test->($v) );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

# Get the unserialize sub of a class (populate() may be inherited)
sub _unserializer {
    my ($class) = @_;
    my $p = $class->can('populate') or die "$class has no populate()\n";
    return $p->()->{unserialize};
}

# Batch size (LIMIT) used by _forEachSession() and by the batched purge of
# PgJSON: $BatchSize if it is an integer in 1..1_000_000, else 1000
sub _batchSize {
    my ($limit) = ( $BatchSize // '' ) =~ /^\s*([1-9][0-9]*)\s*\z/;
    return ( !$limit or $limit > 1_000_000 ) ? 1000 : $limit;
}

# Call $sub->( $id, $serialized ) for each session. If the driver supports
# LIMIT, sessions are read by batches to avoid loading the whole table in
# memory. No server-side cursor here: $sub may reuse the database handle.
sub _forEachSession {
    my ( $class, $dbh, $table_name, $sub ) = @_;
    my $limit = $class->_batchSize;
    my $sql   = "SELECT id,a_session FROM $table_name";
    unless ( $dbh->{Driver}->{Name} =~ /^(?:Pg|mysql|MariaDB|SQLite)\z/ ) {
        my $sth = $dbh->prepare_cached($sql);
        $sth->execute;
        while ( my @row = $sth->fetchrow_array ) {
            $sub->(@row);
        }
        return;
    }

    # Not a single snapshot: rows inserted during the iteration with an id
    # lower than the current position are not visited (harmless for purge
    # and sessions explorer)
    my ( $last, $rows );
    do {
        my $sth =
          $dbh->prepare_cached( $sql
              . ( defined($last) ? ' WHERE id > ?' : '' )
              . " ORDER BY id LIMIT $limit" );
        $sth->execute( defined($last) ? ($last) : () );
        $rows = $sth->fetchall_arrayref;
        $sub->(@$_) foreach (@$rows);
        $last = $rows->[-1]->[0] if (@$rows);
    } while ( @$rows >= $limit );
    return;
}

1;
__END__

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = splice @_;
    my %res = ();
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my $entry = shift;
            my $id    = shift;
            return undef unless ( $entry->{$selectField} eq $value );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = splice @_;
    $value = quotemeta($value);
    $value =~ s/\\\*/\.\*/g;
    $value = qr/^$value$/;
    my %res = ();
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my $entry = shift;
            my $id    = shift;
            return undef unless ( $entry->{$selectField} =~ $value );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

1;

