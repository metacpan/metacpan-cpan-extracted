package Watchdog::Mysql;

use strict;
use Alias;
use base qw(Watchdog::Base);
use DBI;
use vars qw($VERSION $DB $HOST $PORT $NAME);

$VERSION = '0.01';

=head1 NAME

Watchdog::Mysql - Test status of Mysql service

=head1 SYNOPSIS

  use Watchdog::Mysql;
  $h = new Watchdog::Mysql($name,$host,$port,$db);
  ($alive,$error) = $h->is_alive;
  print $h->id, $alive ? ' is alive' : " is dead: $error", "\n";

=head1 DESCRIPTION

B<Watchdog::Mysql> is an extension for monitoring a Mysql server.

=cut

## CLASS DATA

my %fields = ( DB => 'test', );

=head1 CLASS METHODS

=head2 new($name,$host,$port,$db)

Returns a new B<Watchdog::Mysql> object.  I<$name> is a string which
will identify the service to a human (default is 'mysql').  I<$host>
is the hostname which is running the service (default is 'localhost').
I<$port> is the port on which the service listens (default is 3306).
I<$db> is a database with no access control (default is 'test').

=cut

sub new($$$$) {
  my $DEBUG = 0;
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my($name,$host,$port) = ('mysqld','localhost',3306);
  my $arg;
  for ( \$name,\$host,\$port ) {
    $$_ = $arg if $arg = shift;
  }
  print STDERR "Watchdog::Mysql::new() $name $host $port\n" if $DEBUG;
  my $self = bless($class->SUPER::new($name,$host,$port),$class);

  print STDERR "Watchdog::Mysql::new() $NAME $HOST $PORT\n" if $DEBUG;
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->{DB} = $_[0] if defined($_[0]);
  print STDERR "Watchdog::Mysql::new() $NAME $HOST $PORT $DB\n" if $DEBUG;
  return $self;
}

#------------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 id()

Return a string describing the Mysql service.

=cut

sub id() {
  my $self = attr shift;
  return $self->SUPER::id . ":$DB";
}

#------------------------------------------------------------------------------

=head2 is_alive()

Returns (1,undef) if the mysql server can be 'pinged' or (0,I<$error>)
where I<$error> is a DBI error string if it can't.

=cut

sub is_alive() {
  my $DEBUG = 0;
  my $self = attr shift;
  print STDERR "Mysql::is_alive()\n" if $DEBUG;
  print STDERR "\$DB = $DB\n" if $DEBUG;

  # driver should use the Unix domain socket if $PORT is undef
  my $dsn = "DBI:mysql:database=$DB;host=$HOST";
  $dsn .= ";port=$PORT" if defined($PORT);
  print STDERR "\$dsn = $dsn\n" if $DEBUG;
  my $dbh = DBI->connect($dsn,undef,undef,{ PrintError => 0 } );
  
  my($alive,$error);
  if ( defined($dbh) ) {
    ($alive,$error) = ($dbh->ping,$dbh->errstr);
    $dbh->disconnect;
  } else {
    ($alive,$error) = (0,$DBI::errstr);
  }

  return($alive,$error);
}

#------------------------------------------------------------------------------

=head1 SEE ALSO

L<Watchdog::Base>

L<DBI>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
