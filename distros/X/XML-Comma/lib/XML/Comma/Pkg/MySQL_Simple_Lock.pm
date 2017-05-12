##
#
#    Copyright 2002, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org/, or read the tutorial included with the
#    XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Pkg::MySQL_Simple_Lock;

use XML::Comma;
use XML::Comma::Util qw( dbg );

@ISA = ( 'XML::Comma::SQL::DBH_User' );

use strict;

#
# _MySQL_Simple_Lock_quoted_key
# _MySQL_Simple_Lock_locked
#

sub new {
  my ( $class, $key_string, $timeout ) = @_;
  $timeout = 86400  unless  $timeout;
  my $self = {}; bless ( $self, $class );
  my $dbh = $self->get_dbh();
  my $key = $dbh->quote ( $key_string );
  $self->{_MySQL_Simple_Lock_quoted_key} = $key;
  my $sth = $dbh->prepare ( "SELECT GET_LOCK($key,$timeout)" );
  $sth->execute();
  my $result = $sth->fetchrow_arrayref()->[0];
  $sth->finish();
  if ( $result ) {
    return $self;
  } else {
    return undef;
  }
}

sub DESTROY {
  my $self = shift();
  my $key = $self->{_MySQL_Simple_Lock_quoted_key};
  my $dbh = $self->get_dbh();
  $dbh->do ( "SELECT RELEASE_LOCK($key)" );
  $self->disconnect();
}


1;

__END__


=head1 NAME

XML::Comma::Pkg::MySQL_Simple_Lock - A simple one-time-use lock coordinated by db

=head1 SYNOPSIS

  use XML::Comma::Pkg::MySQL_Simple_Lock;
  
  my $lock = XML::Comma::Pkg::MySQL_Simple_Lock->new ( "foo", 10 );
  die "couldn't get lock\n"  unless  $lock;
  undef $lock

=head1 DESCRIPTION

Comma applications can be spread across multiple machines in a
cluster, as long as core database operations are all pointed at a
centralized server. This module provides advisory locking capabilities
to Comma programmers working in such an environment.

MySQL exposes a very simple advisory locking API, the functions
GET_LOCK() and RELEASE_LOCK(). This module provides a very simple,
object-oriented abstraction on top of these functions. Here is a
simple test script:

  #!/usr/bin/perl -w

  use strict; $|++;
  use XML::Comma::Pkg::MySQL_Simple_Lock;

  &do_lock;
  print "waiting outside scope... "; my $junk = <>;

  sub do_lock {
    my $lock = XML::Comma::Pkg::MySQL_Simple_Lock->new ( "foo", 1 );
    die "couldn't get lock\n"  unless  $lock;

    print "$lock\n";
    print "waiting inside scope... "; my $junk = <>;
  }

The C<new()> method expects a C<key_string> argument, which is used to
"name" the lock, and an optional C<timeout> argument. C<timeout>
should be given in seconds, and defaults to 86400, or one day.

C<new()> returns a lock object on success, or undef on failure.

The lock is held as long as a reference to the MySQL_Simple_Lock
object is being held. When all references to the object go out of
scope, the object is destroyed and the lock is automatically
released. It is a good idea to explicitly C<undef> any lock objects,
to make life easier for maintenance programmers.

Each MySQL_Simple_Lock object is a one-time-use construct. To request
a new lock, make a new object.

Each MySQL_Simple_Lock object occupies a database connection as long
as it is held.

=head1 AUTHOR

  comma@xml-comma.org

=head1 SEE ALSO

  http://xml-comma.org

=cut
