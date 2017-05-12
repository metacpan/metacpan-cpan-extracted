#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# A very simple TCP client used in the tests of SimpleServer.

use strict;

package Triceps::X::DumbClient;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;
use IO::Socket::INET;
use Triceps::X::SimpleServer;
use Triceps::X::TestFeed qw(:all);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	run
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#########################
# The common client that connects to the port, sends and receives data,
# and waits for the server to exit.
#
# This means that at least one of the sent or received data must be small
# enough to fit in the TCP buffer

sub run # ($labels)
{
	my $labels = shift;

	my ($port, $pid) = Triceps::X::SimpleServer::startServer(0, $labels);
	my $sock = IO::Socket::INET->new(
		Proto => "tcp",
		PeerAddr => "localhost",
		PeerPort => $port,
	) or confess "socket failed: $!";
	while(& readLine) {
		$sock->print($_);
		$sock->flush();
	}
	$sock->print("exit,OP_INSERT\n");
	$sock->flush();
	$sock->shutdown(1); # SHUT_WR
	while(<$sock>) {
		& send($_);
	}
	waitpid($pid, 0);
}

1;
