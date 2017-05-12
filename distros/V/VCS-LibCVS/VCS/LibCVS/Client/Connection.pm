#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Connection;

use strict;
use Carp;

# If protocol debugging is enabled, use a subclass of IO::Handle which logs
# traffic.
use VCS::LibCVS::Client::LoggingIOHandle;

=head1 NAME

VCS::LibCVS::Client::Connection - a connection to a CVS server

=head1 SYNOPSIS

  my $conn = VCS::LibCVS::Client::Connection->new($root);
  my $client = VCS::LibCVS::Client->new($conn, "/home/cvs");

=head1 DESCRIPTION

A connection to a CVS server.  Its only real use is to construct a CVS client.
It represents a generic connection, but has a constructor, which will
instantiate the appropriate subclass.

Once the connection is established, communication with the server takes place
through a pair of IO::Handles.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Connection.pm,v 1.20 2005/10/10 12:52:11 dissent Exp $ ';

# Protocol_map is a map from protocol strings to subclasses of connection.
# It's filled in by the subclasses, and accessed by the new_for_proto()
# constructor
use vars ('%Protocol_map');

###############################################################################
# Private variables
###############################################################################

# Connection is a hash, and uses the following private entries.  The first
# group can be accesed by the subclasses, the second group should not be.
#
# Used by subclasses:
#
# SubFromServer => An IO::Handle to read information from the server
# SubToServer   => An IO::Handle to write information to the server
#                  These both must be set by subclasses upon connect().  They
#                  may be destroyed by them on disconnect()
#
# Root => VCS::LibCVS::Datum::Root object
#
# Not Used by subclasses:
#
# These file handles may be the same as the ones set by the subclass, or may be
# derived from them in order to do something else, like logging.
#
# FromServer => An IO::Handle to read information from the server
# ToServer   => An IO::Handle to write information to the server
#
# Connected  => boolean, true if the Connection is connected
#               managed in connect() and disconnect()

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$connection = VCS::LibCVS::Client::Connection->new($root);

=over 4

=item argument 1 type: VCS::LibCVS::Datum::Root

=item return type: VCS::LibCVS::Client::Connection

=back

If the protocol is not supported, an exception will be thrown.

=cut

sub new {
  my $class = shift;
  my $root = shift;

  # Instances of this class are never created, an instance of a subclass is
  # created instead.
  if ($class eq "VCS::LibCVS::Client::Connection") {
    $class = $Protocol_map{$root->{Protocol}};
    confess "Protocol $root->{Protocol} not supported" unless defined $class;
    return $class->new($root);
  }

  # But there is a default constructor that subclasses can inherit.
  my $that = bless {}, $class;
  $that->{Root} = $root;
  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<connect()>

$connection->connect()

=over 4

=item return type: undef

=back

Connect to the server.  After this, get_ioh_to_server and get_ioh_from_server
may be called.  When the connection is no longer necessary, disconnect will get
rid of it.

Subclasses must override this method, and use it to set the SubFromServer and
SubToServer private variables.  They must call this method at the beginning of
their implementation, and connect_fin() at the end of it.

=cut

sub connect {
  my $self = shift;
  return;
}

=pod

=head2 B<connect_fin()>

$connection->connect_fin()

=over 4

=item return type: undef

=back

Called by subclasses, once they have established the connection, and created
the SubFromServer and SubToServer private variables.

=cut

sub connect_fin {
  my $self = shift;

  return if $self->{Connected};
  $self->{Connected} = 1;

  # If requested, derive a logging IO from the provided one.
  if ($VCS::LibCVS::Client::DebugLevel & VCS::LibCVS::Client::DEBUG_PROTOCOL) {
    $self->{ToServer} =
      VCS::LibCVS::Client::LoggingIOHandle->new($self->{SubToServer});
    $self->{ToServer}->prefix("C: ");
    $self->{ToServer}->logfile($VCS::LibCVS::Client::DebugOut);
    $self->{FromServer} =
      VCS::LibCVS::Client::LoggingIOHandle->new($self->{SubFromServer});
    $self->{FromServer}->prefix("S: ");
    $self->{FromServer}->logfile($VCS::LibCVS::Client::DebugOut);
  } else {
    $self->{ToServer} = $self->{SubToServer};
    $self->{FromServer} = $self->{SubFromServer};
  }
}

=pod

=head2 B<disconnect()>

$connection->disconnect()

=over 4

=item return type: undef

=back

Closes this connection to the server.  IO::Handles for communicating with the
server will no longer work.

=cut

sub disconnect {
  my $self = shift;
  return if (!$self->{Connected});

  $self->{Connected} = 0;

  delete $self->{ToServer};
  delete $self->{FromServer};
}

=pod

=head2 B<get_ioh_to_server()>

$out_ioh = $connection->get_ioh_to_server();

=over 4

=item return type: IO::Handle

=back

Returns an open writeable IO::Handle.  Stuff written to it is sent to the
server.

The connection must be open to call this routine.

=cut

sub get_ioh_to_server {
  my $self = shift;

  confess "Not connected" unless $self->connected();
  confess "Stream to server not found" unless defined ($self->{ToServer});
  return $self->{ToServer};
}

=pod

=head2 B<get_ioh_from_server()>

$in_ioh = $connection->get_ioh_from_server();

=over 4

=item return type: IO::Handle

=back

Returns an open readable IO::Handle.  Responses generated by the server are
read from this IO::Handle.

The connection must be open to call this routine.

=cut

sub get_ioh_from_server {
  my $self = shift;

  confess "Not connected" unless $self->connected();
  confess "Stream from server not found" unless defined ($self->{FromServer});
  return $self->{FromServer};
}

=pod

=head2 B<connected()>

$is_connected = $connection->connected();

=over 4

=item return type: boolean scalar

=back

Returns a scalar with a true value if the connection is open, false otherwise.

=cut

sub connected {
  my $self = shift;
  return $self->{Connected};
}


=pod

=head2 B<get_root()>

$cvsroot = $connection->get_root();

=over 4

=item return type: VCS::LibCVS::Datum::Root

=back

The root of the server that this is a connection to.

=cut

sub get_root {
  my $self = shift;
  return $self->{Root};
}


###############################################################################
# Private routines
###############################################################################

#
# DESTROY
#
# Clean up any connection
#

sub DESTROY {
  my $self = shift;

  $self->{SubToServer}->close() if defined $self->{SubToServer};
  $self->{SubFromServer}->close() if defined $self->{SubFromServer};
}

=pod

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Connection::Local

=cut

1;
