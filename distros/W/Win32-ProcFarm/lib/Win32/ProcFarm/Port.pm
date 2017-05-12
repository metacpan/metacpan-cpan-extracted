#############################################################################
#
# Win32::ProcFarm::Port - manages access to the TCP port for ProcFarm system
#
# Author: Toby Everett
# Revision: 2.15
# Last Change: Namespace change
#############################################################################
# Copyright 1999, 2000, 2001 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
#############################################################################

=head1 NAME

Win32::ProcFarm::Port - manages access to the TCP port for ProcFarm system

=head1 SYNOPSIS

	use Win32::ProcFarm::Port;

	$port_obj = Win32::ProcFarm::Port->new(9000, 1);

	print $port_obj->get_port_num;

	$socket = $port_obj->get_next_connection;

=head1 DESCRIPTION

=head2 Installation instructions

This installs with MakeMaker as part of Win32::ProcFarm.

To install via MakeMaker, it's the usual procedure - download from CPAN,
extract, type "perl Makefile.PL", "nmake" then "nmake install". Don't
do an "nmake test" because the I haven't written a test suite yet.

=head1 METHODS

=cut

use IO::Socket;

package Win32::ProcFarm::Port;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '2.15';

=head2 new

The C<new> method creates a new C<Win32::ProcFarm::Port> object (fancy that!).  It takes two
parameters - the first is the port number to listen on, and the second is the number of listeners
to create - this will specify the number of "hold lines" for the port object.

=cut

sub new {
	my $class = shift;
	my($port_num, $count) = @_;

	my $self = {
		'port_num' => $port_num,
		'port' => undef,
		'listeners' => $count,
	};

	$self->{port} = IO::Socket::INET->new(LocalPort => $self->{port_num}, Proto => 'tcp',
			Listen => $count, Reuse => 1) or die "Could not connect: $!";

	bless $self, $class;
	return $self;
}

=head2 get_port_num

This returns the port number passed in the C<new> method.

=cut

sub get_port_num {
	my $self = shift;
	return $self->{port_num};
}

=head2 get_listeners

This returns the number of listeners created in the C<new> method.

=cut

sub get_listeners {
	my $self = shift;
	return $self->{listeners};
}

=head2 get_next_connection

This accepts an inbound connection and returns the socket object.  If the inbound connection is
not from 127.0.0.1, the method calls C<die> as this indicates an attempt to hack the system by an
external host.

=cut

sub get_next_connection {
	my $self = shift;

	my $socket = $self->{port}->accept();
	$socket->peerhost eq "127.0.0.1" or
			die "Attempt to connect from illegal address: ".$socket->peerhost."\n";
	return $socket;
}

1;
