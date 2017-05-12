#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Connection::Local;

use strict;
use Carp;
use IPC::Open2;

=head1 NAME

VCS::LibCVS::Client::Connection::Local - a connection to a local cvs server

=head1 SYNOPSIS

  my $conn = VCS::LibCVS::Client::Connection->new($root);

=head1 DESCRIPTION

A connection to an invocation of "cvs server" on the localhost.  See
VCS::LibCVS::Client::Connection for an explanation of the API.

No authentication is required to establish this connection.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Connection

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Connection/Local.pm,v 1.16 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Client::Connection");

###############################################################################
# Initializer
###############################################################################

# register which protocols this subclass supports.
sub BEGIN {
  my $class = "VCS::LibCVS::Client::Connection::Local";
  $VCS::LibCVS::Client::Connection::Protocol_map{"local"} = $class;
  $VCS::LibCVS::Client::Connection::Protocol_map{"fork"} = $class;
}

###############################################################################
# Private variables
###############################################################################

# $self->{PID}  The process Id of the child process.

###############################################################################
# Class routines
###############################################################################

###############################################################################
# Instance routines
###############################################################################

sub connect {
  my $self = shift;

  return if $self->connected();

  $self->SUPER::connect();
  $self->{SubFromServer} = IO::Handle->new();
  $self->{SubToServer} = IO::Handle->new();
  $self->{PID} = IPC::Open2::open2($self->{SubFromServer},
                                   $self->{SubToServer},
                                   "cvs server");
  $self->connect_fin();
}

sub disconnect {
  my $self = shift;

  return if ! $self->connected();

  $self->SUPER::disconnect();
  $self->{SubFromServer}->close();
  $self->{SubToServer}->close();
  waitpid ($self->{PID}, 0);
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Connection

=cut

1;
