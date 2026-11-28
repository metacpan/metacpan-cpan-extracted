package Web::Session::Store::DBI;

use strict;
use Apache::Session::Store::DBI;
use Web::Session::_common;
our @ISA     = qw(Apache::Session::Store::DBI);
our $VERSION = '1.0.0';

# Connection reuse (default): returns a handle cached by DBI->connect_cached()
# (which pings it and reconnects if needed), opened with the attributes $attr
# that the store uses without reuse. Returns undef if the store is already
# connected, if "noreuse" is set or if a Handle is given. Unless Commit is
# 0, the Postgres and Patroni stores use the connection pool of the Postgres
# store instead, unless KeepConnections is 0 (see Store/Postgres.pm).
#
# Why AutoCommit differs between stores: each store opens its connection
# with the attributes of the Apache::Session store it derives from.
# Apache::Session::Store::Postgres uses AutoCommit off and commits in DESTROY
# when Commit is set. Its materialize() locks the row with
# "SELECT ... FOR UPDATE": the Patroni store uses it (through _try()), so a
# Patroni session stays locked from the tie to the commit at untie, also with
# the connection pool (one transaction per tie, see Store/Patroni.pm). The
# Postgres store doesn't lock: its materialize() comes first from
# Apache::Session::Store::DBI. The SQLite store copies the AutoCommit off
# model. Apache::Session::Store::MySQL (MySQLJSON derives from it) was
# written for MyISAM, which has no transaction: AutoCommit on. The lock
# manager of all SQL backends is Apache::Session::Lock::Null: with AutoCommit
# off, the transaction only spans the reads and the write of one tie.
# Keeping each store's own attributes keeps its behaviour unchanged.
#
# Stores don't disconnect a handle they didn't open, so a transaction that
# the store doesn't commit (AutoCommit off, Commit not set or commit failure)
# would stay open, with its locks, on the shared handle: it is rolled back
# when the store is destroyed, after its own DESTROY (as disconnect did)
sub _reusedHandle {
    my ( $self, $args, $datasource, $username, $password, $attr ) = @_;
    return undef
      if ( defined $self->{dbh} or $args->{noreuse} or exists $args->{Handle} );

    # Fork safe, as the handles of the class methods (see _forkSafeAttr() in
    # _common.pm): a child forked after the parent tied a session must not
    # reuse the parent's handle, nor close its connection
    my $dbh = DBI->connect_cached( $datasource, $username, $password,
        Web::Session::_common->_forkSafeAttr($attr) )
      || die $DBI::errstr;
    $self->{reuse_rollback} =
      bless \$dbh, 'Web::Session::Store::DBI::Rollback'
      unless ( $dbh->{AutoCommit} );
    return $dbh;
}

# In a child created by fork(), a store connected by the parent still holds
# the parent's handle: connection() would return early and the child would
# use the parent's socket. Handles of the connection cache and of the
# PostgreSQL pool carry the pid of the process that opened them (see
# _forkSafeAttr() in _common.pm): such a handle is forgotten with its
# statements, neither closed (AutoInactiveDestroy) nor rolled back (see the
# Rollback guard below), so that connection() opens one for this process.
# Other handles (noreuse, Handle argument) are kept as is. Called by the
# connection() of every store, also by those not inheriting from this class,
# and by the DESTROY of the stores that commit there (the commit would go to
# the parent's transaction). Returns true if the handle was forgotten
sub _forgetInheritedHandle {
    my ($self) = @_;
    my $dbh = $self->{dbh} or return 0;
    my $pid = $dbh->{private_ws_pid};
    return 0 unless ( defined $pid and $pid != $$ );
    delete @$self{ 'dbh', 'reuse_rollback', grep { /_sth\z/ } keys %$self };
    return 1;
}

# connection() of stores whose parent class $class (an Apache::Session::Store
# class) opens a connection with the attributes $attr and uses the Handle
# argument as is
sub _connection {
    my ( $self, $session, $class, $attr ) = @_;
    _forgetInheritedHandle($self);
    my $args    = $session->{args};
    my $connect = $class->can('connection');
    my @credentials;
    {
        no strict 'refs';
        @credentials = map { $args->{$_} || ${"${class}::$_"} }
          qw(DataSource UserName Password);
    }
    if ( my $dbh = $self->_reusedHandle( $args, @credentials, $attr ) ) {
        local $args->{Handle} = $dbh;
        return $self->$connect($session);
    }
    return $self->$connect($session);
}

sub insert {
    my ( $self, $session ) = @_;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    $self->{insert_sth} //= $self->{dbh}->prepare_cached(
            'INSERT INTO '
          . $self->_quoteTable( $self->{table_name} ) . ' ('
          . join( ',',
            'id', 'a_session', map { $self->_quoteColumn($_) } @$index )
          . ') VALUES ('
          . join( ',', ('?') x ( 2 + @$index ) ) . ')'
    );

    $self->{insert_sth}->bind_param( 1, $session->{data}->{_session_id} );
    $self->{insert_sth}->bind_param( 2, $session->{serialized} );
    my $i = 3;
    foreach my $f (@$index) {
        $self->{insert_sth}->bind_param( $i, $session->{data}->{$f} );
        $i++;
    }

    $self->{insert_sth}->execute;

    $self->{insert_sth}->finish;
}

sub update {
    my $self    = shift;
    my $session = shift;

    # Indexed columns are computed from the session data only: same data,
    # same columns (unless Index lists a column added since the row was
    # written: see RewriteUnchanged)
    return if ( _unchanged( $self, $session ) );

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    if ( !defined $self->{update_sth} ) {
        $self->{update_sth} = $self->{dbh}->prepare_cached(
                'UPDATE '
              . $self->_quoteTable( $self->{table_name} ) . ' SET '
              . join( ' = ?, ',
                'a_session', map { $self->_quoteColumn($_) } @$index )
              . ' = ? WHERE id = ?'
        );
    }

    $self->{update_sth}->bind_param( 1, $session->{serialized} );
    my $i = 2;
    foreach my $f (@$index) {
        $self->{update_sth}->bind_param( $i, $session->{data}->{$f} );
        $i++;
    }
    $self->{update_sth}->bind_param( $i, $session->{data}->{_session_id} );

    $self->{update_sth}->execute;

    $self->{update_sth}->finish;
    _remember( $self, $session );
}

# Unchanged sessions are not rewritten
#
# Apache::Session saves a session at untie as soon as a key was stored, even
# with the value it already had (Lemonldap::NG does that). An UPDATE that
# writes the same data is not free: PostgreSQL writes a new row version (and
# its WAL) that must be cleaned up later, plus a new entry in every index when
# the stored value of a_session changes (the indexes are expressions on it, so
# the update can't be HOT), for example when the keys of a json column come
# in another order; other databases lock and log the row. So the store keeps
# the serialized data it read (or last updated) and update() returns without
# writing when the new one is the same. insert() is unchanged: it doesn't
# keep what it wrote, so the first update() after it always writes.
#
# The functions below take the store as first argument, not as invocant:
# Web::Session::Store::MariaDBJSON and Web::Session::Store::Patroni don't
# inherit from this class and call them too.

sub materialize {
    my ( $self, $session ) = @_;

    # Apache::Session::Store::DBI's one, as before this override (it comes
    # first in the method resolution of the stores inheriting from this class)
    $self->SUPER::materialize($session);
    _remember( $self, $session );
}

# Keep the serialized data that the database holds (after a read or an update)
sub _remember {
    my ( $self, $session ) = @_;
    $self->{stored_serialized} = $session->{serialized};
}

# Whether the serialized data to write ($session->{serialized}) is the one the
# database already holds
sub _unchanged {
    my ( $self, $session ) = @_;
    my $old = $self->{stored_serialized};
    my $new = $session->{serialized};
    return 0
      if ( !defined $old
        or !defined $new
        or $session->{args}->{RewriteUnchanged} );

    # Same bytes. Strings are compared as the bytes exchanged with the
    # database: the serializer produces characters (UTF-8 flag on), which DBD
    # drivers send UTF-8 encoded, but a driver may return the stored value as
    # undecoded bytes (MySQL json columns, a handle without the utf8 option).
    # A plain "eq" would compare characters: it would wrongly find a Latin-1
    # byte equal to the same character sent UTF-8 encoded, and wrongly find
    # UTF-8 bytes different from the same characters
    return 1 if ( _bytes($old) eq _bytes($new) );

    # Same data. Columns of type jsonb (PostgreSQL) or json (MySQL) don't
    # return the text written but a normalized one (keys sorted by length,
    # spaces added), and sessions written by older versions have their keys in
    # random order: the bytes never match. The data read is then serialized
    # again, the way the session read it, and compared. When it matches,
    # readers already get the data that would be written, so the write
    # changes nothing they see. Only JSON objects: the session data is a
    # hash, so a row holding another JSON value can't hold the same data, and
    # a row in another format (Storable, written by old versions) is still
    # rewritten as JSON.
    # Costs one decode and one encode when the bytes differ (at each update
    # with jsonb or MySQL json columns), much less than a write.
    return 0 unless ( $old =~ /\A\s*\{/ );
    local $@;
    my $again = eval {
        my $tmp = { serialized => $old };
        $session->{unserialize}->($tmp);
        $session->{serialize}->($tmp);
        $tmp->{serialized};
    };
    return ( defined $again and _bytes($again) eq _bytes($new) ) ? 1 : 0;
}

# The bytes a DBD driver exchanges for string $s: UTF-8 encoded when it holds
# characters (UTF-8 flag on), as is otherwise
sub _bytes {
    my $s = shift;
    utf8::encode($s) if ( utf8::is_utf8($s) );
    return $s;
}

# Table name and columns of indexed fields in SQL queries, see
# Web::Session::_common::_quoteIdentifier(). Stores that need
# another quoting override them
sub _quoteTable {
    my ( $self, $name ) = @_;
    return Web::Session::_common->_quoteIdentifier( $self->{dbh},
        $name );
}

sub _quoteColumn {
    my ( $self, $field ) = @_;
    return Web::Session::_common->_quoteIdentifier( $self->{dbh},
        $field );
}

package Web::Session::Store::DBI::Rollback;

# Ends the transaction left by a store using a reused handle (no-op if the
# store committed it). Not in a child created by fork(): the transaction is
# the parent's, on the parent's socket
sub DESTROY {
    my $dbh = ${ $_[0] };
    return if ( ( $dbh->{private_ws_pid} // $$ ) != $$ );
    local $@;
    eval { $dbh->rollback } if ( $dbh->{Active} and !$dbh->{AutoCommit} );
}

1;
