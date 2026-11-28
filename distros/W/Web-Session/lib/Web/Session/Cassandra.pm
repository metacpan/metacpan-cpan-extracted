package Web::Session::Cassandra;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Web::Session::Store::Cassandra;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;
use Web::Session::DBI;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::DBI Apache::Session);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Web::Session::Store::Cassandra $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

# CQL can't run the SQL comparisons of DBI.pm: read all sessions and compare
# in Perl. As with other backends, sessions without the field are skipped
sub searchLt {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    $value = $class->_checkSearchValue( '<', $value );
    return {} unless ( defined $value );
    return $class->_searchByTest( $args, $selectField,
        sub { defined( $_[0] ) and $_[0] < $value }, @fields );
}

sub searchGt {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    $value = $class->_checkSearchValue( '>', $value );
    return {} unless ( defined $value );
    return $class->_searchByTest( $args, $selectField,
        sub { defined( $_[0] ) and $_[0] > $value }, @fields );
}

1;

=pod

=head1 NAME

Web::Session::Cassandra - Apache::Session backend to store
sessions in a Cassadra database.

=head1 SYNOPSIS

  use Web::Session::Cassandra;
  
  my $args = {
       DataSource => 'dbi:Cassandra:host=localhost;keyspace=llng',
       UserName   => $db_user,
       Password   => $db_pass,
  
       # Choose your browseable fileds
       Index      => '_whatToTrace _session_kind _utime iAddr',
  };
  
  # Use it like Apache::Session
  my %session;
  tie %session, 'Web::Session::Cassandra', $id, $args;
  $session{uid} = 'me';
  $session{mail} = 'me@me.com';
  $session{unindexedField} = 'zz';
  untie %session;

=head1 DESCRIPTION

Web::Session::Cassandra is an implementation of Apache::Session
for Cassandra database.

=head1 SCHEMA

To use this module, you will need at least these columns in a table
called 'sessions':

  id text
  a_session text

To create this schema, you can execute this command using cqlsh:

  CREATE TABLE sessions (
     id text PRIMARY KEY,
     a_session text
  );

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database.  These values can be set using the options hash
(see Apache::Session documentation).  The options are DataSource, UserName,
and Password.

Example:

 tie %hash, 'Apache::Session::Cassandra', $id, {
     DataSource => 'dbi:Cassandra:host=localhost;keyspace=llng',
     UserName   => 'database_user',
     Password   => 'K00l'
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Apache::Session::Cassandra', $id, {
     Handle => $dbh
 };

=head1 searchLt() AND searchGt()

They take the same arguments and return the same data as searchOn(): sessions
whose field is lower (or greater) than the given value, which is excluded. The
value must be a number (C<12>, C<-12> or C<12.5>): otherwise nothing is
returned and an error is printed on STDERR. Spaces around the value are
ignored.

They read all sessions and compare fields in Perl: a non-numeric field value
is compared as 0, or as its numeric prefix.

Sessions without the field are never returned, as with the other backends of
this distribution. This differs from the Perl fallback of Lemonldap::NG,
where a missing field is compared as 0.

The connection is kept open between sessions. Set C<noreuse =E<gt> 1> to open
and close one for each session, see L<Web::Session/"PERSISTENT DATABASE CONNECTIONS">.

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::DBI>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

Copyright (C):

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
