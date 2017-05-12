#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Connection::Ext;

use strict;
use Carp;
use IPC::Open2;

=head1 NAME

VCS::LibCVS::Client::Connection::Ext - a connection to a remote cvs server

=head1 SYNOPSIS

  my $conn = VCS::LibCVS::Client::Connection->new($root);

=head1 DESCRIPTION

A connection to an invocation of "cvs server" on a remote machine.  See
VCS::LibCVS::Client::Connection for an explanation of the API.

The connection to the remove machine is established through an external
program.  The default is "ssh", but it can be overridden by setting the
environment variable CVS_RSH.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Connection

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Connection/Ext.pm,v 1.7 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Client::Connection");

###############################################################################
# Initializer
###############################################################################

# register which protocols this subclass supports.
sub BEGIN {
  my $class = "VCS::LibCVS::Client::Connection::Ext";
  $VCS::LibCVS::Client::Connection::Protocol_map{"ext"} = $class;
}

###############################################################################
# Private variables
###############################################################################

# $self->{Root}  VCS::LibCVS::Datum::Root object for my repository.

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

  my $user = $self->{Root}->{UserName};
  my $user_arg = (defined $user) ? ('-l ' . $user) : "";

  my $command = ('${CVS_RSH:-ssh} ' .
                 $user_arg .
                 ' ' . $self->{Root}->{HostName} .
                 ' ${CVS_SERVER:-cvs} server');
  $self->{SubFromServer} = IO::Handle->new();
  $self->{SubToServer} = IO::Handle->new();
  IPC::Open2::open2($self->{SubFromServer}, $self->{SubToServer}, $command);
  $self->connect_fin();
}

sub disconnect {
  my $self = shift;

  return if ! $self->connected();

  $self->SUPER::disconnect();
  $self->{SubFromServer}->close();
  $self->{SubToServer}->close();
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Connection

=cut

1;
