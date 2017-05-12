package Win32::Girder::IEvent::Client;

#==============================================================================#

=head1 NAME

Win32::Girder::IEvent::Client - Perl API to the Win32 Girder Internet Events Client

=head1 SYNOPSIS

	use Win32::Girder::IEvent::Client;
	my $gc = Win32::Girder::IEvent::Client->new(
		PeerHost => 'htpc.my.domain:1024'
	);
	$gc->send(42) || die "Can't send event";

=head1 DESCRIPTION

Girder is a Windows automation tool, originally designed to receive commands
from IR remote controls. The client is used for sending 'Event Strings' to a
Girder instance or a compatible server.

=head2 METHODS

=over 4

=cut

#==============================================================================#

require 5.6.0;

use strict;
use warnings::register;
use IO::Socket;

use Win32::Girder::IEvent::Common qw(
	hash_password
	$def_pass
	$def_port
	$def_host
);

use base qw(IO::Socket::INET);

our $VERSION = 0.01;


#==============================================================================#

=item my $gc = Win32::Girder::IEvent::Client->new([ARGS]);

Create a new client object. The client object inherits the IO::Socket::INET 
object and so the constructor can take all the IO::Socket::INET methods.
However the only relavent ones are:

B<( PeerAddr =E<gt> $addr )> or B<( PeerHost =E<gt> $addr )>

The servername (and possibly port) of the server to connect to. Defaults to 
"localhost:1024" if not specified.

B<( PeerPort =E<gt> $port )>

The port on which the server is running. Defaults to 1024 if not specified
or not part of the server name.

Girder specific parameters are:

B<( PassWord =E<gt> $mypass )>

The password needed for access to the server. Defaults to 'NewDefPWD'. Note 
that passwords are NOT sent plain text accross the wire.

=cut

sub new {
	my ($pack,%opts) = @_;

	my $addr;
	if (
		(defined($addr = $opts{PeerAddr})) ||
		(defined($addr = $opts{PeerHost}))
	) {
		if ($addr !~ /:/) {
			if (!defined(my $addr = $opts{PeerPort})) {
				$opts{PeerPort} = $def_port;
			}
		}
	} else {
		$opts{PeerAddr} = "$def_host:$def_port";
	}

	my $obj = $pack->SUPER::new(%opts) || do {
		warnings::warn "Could not create socket: $!";
		return 0;
	};

	if (defined(my $pass = $opts{PassWord})) {
		$$obj->{_girder_pass} = $pass;
	} else {
		$$obj->{_girder_pass} = $def_pass;
	}


	$obj->print("quintessence\n");
	my $cookie = $obj->getline;
	if ($cookie) {
		chomp($cookie);

		$obj->print(hash_password($cookie,$$obj->{_girder_pass})."\n");
		unless ((local $_ = $obj->getline) && (/accept/)) {
			warnings::warn "Server rejected connection - is the password correct";
			$obj = 0;
		}
	} else {
		warnings::warn "Server did not send back a cookie";
		$obj = 0;
	}

	return $obj;
}


#==============================================================================#

=item $gc->send("event1" [,"event2" ...]);

Send an event, or several events to the server. Returns the number of events
sent.

=cut

sub send {
	my ($obj,@events) = @_;

	foreach my $event (@events) {
		$obj->print("$event\n") || return;
	}

	return scalar @events;
}


#==============================================================================#

=item $gc->close();

Politly shut down the connection.

=cut

sub close {
	my ($obj,@opts) = @_;
	$obj->print("close\n");
	$obj->SUPER::close(@opts);
}
	

#==============================================================================#

sub DESTROY {
	my ($obj) = @_;
	$$obj->{_girder_pass} = undef;
	$obj->SUPER::DESTROY();
}


#==============================================================================#

=back

=head1 AUTHOR

This module is Copyright (c) 2002 Gavin Brock gbrock@cpan.org. All rights 
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The Girder application is Copyright (c) Ron Bessems. Please see the 
'copying.txt' that came with your copy of Girder or visit http://www.girder.nl 
for contact information.

=head1 SEE ALSO

The Girder home page http://www.girder.nl

L<Win32::Girder::IEvent::Server>.

L<IO::Socket::INET>.

=cut

# That's all folks..
#==============================================================================#
