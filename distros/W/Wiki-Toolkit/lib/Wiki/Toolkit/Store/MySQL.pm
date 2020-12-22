package Wiki::Toolkit::Store::MySQL;

use strict;

use vars qw( @ISA $VERSION );

use Wiki::Toolkit::Store::Database;
use Carp qw/carp croak/;
use Digest::SHA1 qw/ sha1_hex /;

@ISA = qw( Wiki::Toolkit::Store::Database );
$VERSION = 0.06;

=head1 NAME

Wiki::Toolkit::Store::MySQL - MySQL storage backend for Wiki::Toolkit

=head1 REQUIRES

Subclasses Wiki::Toolkit::Store::Database.

=head1 SYNOPSIS

See Wiki::Toolkit::Store::Database

=cut

# Internal method to return the data source string required by DBI.
sub _dsn {
    my ($self, $dbname, $dbhost, $dbport) = @_;
    my $dsn = "dbi:mysql:$dbname";
    $dsn .= ";host=$dbhost" if $dbhost;
    $dsn .= ";port=$dbport" if $dbport;
    return $dsn;
}

=head1 METHODS

=over 4

=item B<check_and_write_node>

  $store->check_and_write_node( node     => $node,
                checksum => $checksum,
                                %other_args );

Locks the node, verifies the checksum, calls
C<write_node_post_locking> with all supplied arguments, unlocks the
node. Returns the version of the updated node on successful writing, 0 if
checksum doesn't match, -1 if the change was not applied, croaks on error.

Note:  Uses MySQL's user level locking, so any locks are released when
the database handle disconnects.  Doing it like this because I can't seem
to get it to work properly with transactions.

=back

=cut

sub check_and_write_node {
    my ($self, %args) = @_;
    my ($node, $checksum) = @args{qw( node checksum )};
    $self->_lock_node($node) or croak "Can't lock node";
    my $ok = $self->verify_checksum($node, $checksum);
    unless ($ok) {
        $self->_unlock_node($node) or carp "Can't unlock node";
        return 0;
    }
    $ok = $self->write_node_post_locking( %args );
    $self->_unlock_node($node) or carp "Can't unlock node";
    return $ok;
}

# Returns 1 if we can get a lock, 0 if we can't, croaks on error.
sub _lock_node {
    my ($self, $node) = @_;
    my $dbh = $self->{_dbh};
    # SHA1 the node name to make sure the lock name isn't >64 characters.
    my $lock_name = $dbh->quote( sha1_hex( $node ) );
    my $sql = "SELECT GET_LOCK( $lock_name, 10 )";
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my $locked = $sth->fetchrow_array;
    $sth->finish;
    return $locked;
}

# Returns 1 if we can unlock, 0 if we can't, croaks on error.
sub _unlock_node {
    my ($self, $node) = @_;
    my $dbh = $self->{_dbh};
    my $lock_name = $dbh->quote( sha1_hex( $node ) );
    my $sql = "SELECT RELEASE_LOCK( $lock_name )";
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my $unlocked = $sth->fetchrow_array;
    $sth->finish;
    return $unlocked;
}

sub _get_casesensitive_compare_sql {
    my ($self, $column) = @_;
    return "BINARY $column = ?";
}

1;
