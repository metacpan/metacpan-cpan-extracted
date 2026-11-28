#############################################################################
#
# Web::Session::SQLite
# Apache persistent user sessions in a SQLite database
# Copyright(c) 2013 Xavier Guimard <x.guimard@free.fr>
# Inspired by Apache::Session::Store::Postgres
# (copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org))
# Distribute under the Perl License
#
############################################################################

package Web::Session::Store::SQLite;

use strict;

use DBI;
use Apache::Session::Store::DBI;
use Web::Session::Store::DBI;

our @ISA     = qw(Web::Session::Store::DBI Apache::Session::Store::DBI);
our $VERSION = '1.0.0';

$Web::Session::Store::SQLite::DataSource = undef;

sub connection {
    my $self    = shift;
    my $session = shift;

    $self->_forgetInheritedHandle;
    return if ( defined $self->{dbh} );
    $session->{args}->{Commit} =
      exists( $session->{args}->{Commit} ) ? $session->{args}->{Commit} : 1;

    $self->{'table_name'} = $session->{args}->{TableName}
      || $Apache::Session::Store::DBI::TableName;

    if ( exists $session->{args}->{Handle} ) {
        $self->{dbh}    = $session->{args}->{Handle};
        $self->{commit} = $session->{args}->{Commit};
        return;
    }

    my $datasource = $session->{args}->{DataSource}
      || $Web::Session::Store::SQLite::DataSource;

    # AutoCommit off: see "Why AutoCommit differs" in Store/DBI.pm
    if (
        my $dbh = $self->_reusedHandle(
            $session->{args}, $datasource, '', '',
            { RaiseError => 1, AutoCommit => 0 }
        )
      )
    {
        $self->{dbh} = $dbh;
    }
    else {
        $self->{dbh} =
          DBI->connect( $datasource, '', '',
            { RaiseError => 1, AutoCommit => 0 } )
          || die $DBI::errstr;

        #If we open the connection, we close the connection
        $self->{disconnect} = 1;
    }
    $self->{dbh}->{sqlite_unicode} = 1;

    #the programmer has to tell us what commit policy to use
    $self->{commit} = $session->{args}->{Commit};
}

sub materialize {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    if ( !defined $self->{materialize_sth} ) {
        my $table = $self->_quoteTable( $self->{'table_name'} );
        $self->{materialize_sth} = $self->{dbh}->prepare_cached(
            qq{
                SELECT a_session FROM $table WHERE id = ?}
        );
    }

    $self->{materialize_sth}->bind_param( 1, $session->{data}->{_session_id} );

    $self->{materialize_sth}->execute;

    my $results = $self->{materialize_sth}->fetchrow_arrayref;

    if ( !( defined $results ) ) {
        $self->{materialize_sth}->finish;
        die "Object does not exist in the data store";
    }

    $self->{materialize_sth}->finish;

    $session->{serialized} = $results->[0];

    # Overrides Web::Session::Store::DBI's materialize(): keep what was read,
    # see "Unchanged sessions are not rewritten" there
    $self->_remember($session);
}

sub DESTROY {
    my $self = shift;
    return if ( $self->_forgetInheritedHandle );

    if ( $self->{commit} ) {
        $self->{dbh}->commit;
    }

    if ( $self->{disconnect} ) {
        $self->{dbh}->disconnect;
    }
}

1;

=pod

=head1 NAME

Web::Session::Store::SQLite - Store persistent data in a SQLite
database

=head1 SYNOPSIS

 use Web::Session::Store::SQLite;

 my $store = new Web::Session::Store::SQLite;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

Web::Session::Store::SQLite fulfills the storage interface of
Apache::Session. Session data is stored in a SQLite database.

=head1 SCHEMA

To use this module, you will need at least these columns in a table
called 'sessions', or another name if you supply the TableName parameter.

 id char(32)     # or however long your session IDs are.
 a_session text  # This has an ~8 KB limit :(

To create this schema, you can execute this command using the sqlite program:

 CREATE TABLE sessions (
    id char(32) not null primary key,
    a_session text
 );

If you use some other command, ensure that there is a unique index on the
table's id column.

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database.  These values can be set using the options hash
(see Apache::Session documentation).  The options are:

=over 4

=item DataSource

=item UserName

=item Password

=item Handle

=item TableName

=item noreuse

Open and close a connection for each session instead of keeping it open, see
L<Web::Session/"PERSISTENT DATABASE CONNECTIONS">.

=back

Example:

 tie %hash, 'Web::Session::SQLite', $id, {
     DataSource => 'dbi:Pg:dbname=database',
     UserName   => 'database_user',
     Password   => 'K00l'
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Web::Session::SQLite', $id, {
     Handle => $dbh
 };

=head1 AUTHOR

This modules was written by Jeffrey William Baker <jwbaker@acm.org>

A fix for the commit policy was contributed by Michael Schout <mschout@gkg.net>

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::Store::DBI>
