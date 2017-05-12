package Test::Mojo::Pg;
use Mojo::Base -base;
use File::Basename;
use Mojo::Pg;
use Mojo::Pg::Migrations;

our $VERSION = '0.33';

has host     => undef;
has port     => undef;
has db       => 'testdb';
has username => undef;
has password => undef;
has migsql   => undef;
has verbose  => 0;

sub construct {
  my ($self) = @_;
  $self->drop_database;
  $self->create_database;
}

sub deconstruct {
  my ($self) = @_;
  $self->drop_database;
}

sub get_version {
  my ($self, $p) = @_;
  my $q_v   = 'SELECT version()';
  my $q_sv  = 'SHOW server_version';
  my $q_svn = 'SHOW server_version_num';

  my $full_version       = $p->db->query($q_v)->array->[0];
  my $server_version     = $p->db->query($q_sv)->array->[0];
  my $server_version_num = $p->db->query($q_svn)->array->[0];
  say '-> Pg full version is ' . $full_version
    if $self->verbose;
  say '-> Pg server_version is ' . $server_version
    if $self->verbose;
  say '-> Pg server_version_num is ' . $server_version_num
    if $self->verbose;
  return $server_version_num;
}

sub connstring {
  my ($self, $dbms) = @_;
  my $prefix = 'postgresql://';
  my $result = $prefix
             . $self->_connstring_user
             . $self->_connstring_server;
  return $result if defined $dbms;

  $result .= '/' . $self->db;

  return $result;
}

sub _connstring_server {
  my ($self) = @_;
  return $self->host . ':' . $self->port
    if defined $self->host and defined $self->port;
  return $self->host if defined $self->host;
  return '';
}

sub _connstring_user {
  my ($self) = @_;
  return $self->username . ':' . $self->password . '@'
    if defined $self->username and defined $self->password;
  return $self->username . '@' if defined $self->username;
  return '';
}

sub drop_database {
  my ($self) = @_;
  # Connect to the DBMS
  my $c = $self->connstring(1);
  say "Dropping database " . $self->db . " as $c" if $self->verbose;
  my $p = Mojo::Pg->new($c);
  $self->remove_connections($p);
  $p->db->query('drop database if exists ' . $self->db . ';');
  $p->db->disconnect;
}

sub create_database {
  my ($self) = @_;
  my $c = $self->connstring(1);
  say "Creating database defined as $c" if $self->verbose;
  my $p = Mojo::Pg->new($c);
  $p->db->query('create database '. $self->db .';');

  if (not defined $self->migsql) {
    warn 'No migration script - empty database created.';
    $p->db->disconnect;
    return 1;
  }

  my $db = Mojo::Pg->new($self->connstring);
  my $migrations = Mojo::Pg::Migrations->new(pg => $db);
  $migrations->from_file($self->migsql);
  $migrations->migrate(0)->migrate;
  $db->db->disconnect;
  return 1;
}

sub remove_connections {
  my ($self, $p) = @_;
  say 'Removing existing connections' if $self->verbose;
  my $pf = $self->get_version($p) < 90200 ? 'procpid' : 'pid';
  my $q = q|SELECT pg_terminate_backend(pg_stat_activity.| . $pf . q|) |
        . q|FROM   pg_stat_activity |
        . q|WHERE  pg_stat_activity.datname='| . $self->db . q|' |
        . q|AND    | . $pf . q| <> pg_backend_pid();|;
  $p->db->query($q);
}

=head1 NAME

Test::Mojo::Pg - a helper for dealing with Pg during tests

=head1 SYNOPSIS

 use Test::Mojo::Pg;
 my $db;

 # Bring up database to prepare for tests
 BEGIN {
   $db = Test::Mojo::Pg->new(host => 'ananke', db => 'mydb'), 'Test::Mojo::Pg';
   $db->construct;
 }

 # Tear down the database to clean the environment
 END {
   $db->deconstruct;
 }

=head1 DESCRIPTION

Test::Mojo::Pg makes the creation and removal of a transitory database during
testing when using Mojo::Pg.  This is useful when every test should work from a 'clean' database.

=head1 CONSTRUCTOR

You can either pass options in when calling the constructor or set the attributes later.

 my $p1 = Test::Mojo::Pg->new();
 my $p2 = Test::Mojo::Pg->new(host=>'myhost', db => 'db1');

Option keys match the attribute names.

=head1 ATTRIBUTES

The following are the attributes for this module.

=head2 host

Sets the Postgres server hostname. If omitted, no hostname (or port, if defined)
will be configured for the connection string (which effectively means use localhost).

=head2 port

Sets the Postgres server port.  If omitted, no port will be configured for the
connection string.

=head2 db

Sets the test database name.

default: testdb

=head2 username

Sets the login username.  If omitted, no username will be provided to the server.

=head2 password

Sets the login password.  If omitted, no password will be provided to the server.

=head2 migsql

Sets the file to use for Mojo::Pg::Migrations.  If no sql file is provided, a
warning will be emitted that only an empty database has been provided.

=head2 verbose

Enables verbose output of operations such as the server's version string.

 # get the verbose level - 0|1
 $p->verbose;

 # set the verbose level to 'on'
 $p->verbose(1);


=head1 METHODS

The following are the methods for this module.

=head2 connstring

Returns the connection string for the database.  Returns the connection string
for the dbms by passing in '1'.

  my $testdb_connstring = $testdb->connstring;

  my $testdb_dbms = $testdb->connstring(1);

=head2 construct

The construct method removes current connections to the database and
the database itself if it exists, creates a new database, and loads the
migrations file if it's defined. This normally gets called from the BEGIN block.

  $testdb->construct;

=head2 deconstruct

The deconstruct method removes current connections to the database and the
database itself if it exists.  This normally gets called from the END block.

  $testdb->desconstruct;

=head2 create_database

Creates the database as defined by the connection string.

  $testdb->create_database;

=head2 drop_database

Drops the database as defined by the connection string.

  $testdb->drop_database;

=head2 get_version

  my $version = $testdb->get_version;

Retrieve the database version.

=head2 remove_connections

Force removal of connection related data in the dbms.  Many times required in
order to drop the database.

  $testdb->remove_connections;

=head1 AUTHORS

Richard A. Elberger E<lt>riche@cpan.orgE<gt>.

=head1 MAINTAINERS

=over 4

=item Richard A. Elberger E<lt>riche@cpan.orgE<gt>

=back

=head1 CONTRIBUTORS

=over 4

=item Vladimir N. Indik (vovka667@github)

=back

=head1 BUGS

See F<http://rt.cpan.org> to report and view bugs.


=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/rpcme/Test-Mojo-Pg/>.

=head1 COPYRIGHT

Copyright 2015 by Richard A. Elberger E<lt>riche@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
