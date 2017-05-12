package Win32::Girder::IEvent::Server;

#==============================================================================#

=head1 NAME

Win32::Girder::IEvent::Server - Perl API to the Win32 Girder Internet Events Server

=head1 SYNOPSIS

	use Win32::Girder::IEvent::Server;
	my $gs = Win32::Girder::IEvent::Server->new();
	my $event = $gs->wait_for_event();

=head1 DESCRIPTION

Girder is a Windows automation tool, originally designed to receive commands
from IR remote controls. The server is used for receiving 'Event Strings' from
a Girder instance or a compatible client.

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
);

use base qw(IO::Socket::INET);

our $VERSION = 0.01;

use constant BUFSIZ => 1024;

#==============================================================================#

=item Win32::Girder::IEvent::Server->new([ARGS]);

Create a new server object. The server object inherits the IO::Socket::INET 
object and so the constructor can take all the IO::Socket::INET methods.
However the only relavent ones are:

B<( LocalPort =E<gt> $port )>

The port on which to run the server. Defaults to 1024 if not specified.

Girder specific parameters are:

B<( PassWord =E<gt> $mypass )>

The password needed for access to the server. Defaults to 'NewDefPWD'. Note 
that passwords are NOT sent plain text accross the wire.

=cut

sub new {
	my ($pack,%opts) = @_;

	$opts{'LocalPort'} ||= $def_port;
	$opts{'Listen'} ||= SOMAXCONN;
	$opts{'Protot'} ||= 'udp';

	my $obj = $pack->SUPER::new(%opts) || do {
		warnings::warn "Could not create server socket: $!";
		return 0;
	};

	if (defined(my $pass = $opts{PassWord})) {
		$$obj->{_girder_pass} = $pass;
	} else {
		$$obj->{_girder_pass} = $def_pass;
	}

	# Register with global server list


	$$obj->{_girder_rin} = '';
	$$obj->{_girder_clients} = [];
	$$obj->{_girder_authenticated} = {};

	vec($$obj->{_girder_rin},$obj->fileno,1) = 1;

	return $obj;
}


#==============================================================================#

=item my $event = $gs->wait_for_event([timeout]);

Wait for a client to send an event, or until the optional timeout. Returns 
the event_sting received. Waiting is implemented using select() and will only
work on platforms supporting select(). Timeout is in seconds with the same
resolution as select().

=cut

sub wait_for_event {
	my ($obj,@opts) = @_;
	
	my $timeout = undef;
	$timeout = $opts[0] if @opts;
	
	my $event_string = 0;

	LOOP: {
		if (select(my $rout = $$obj->{_girder_rin}, undef, undef, $timeout)) {
			if (defined(my $event = $obj->handle_events())) {
				return $event;
			} else {
				redo LOOP;
			}
		} else {
			return undef;
		}
	}
}


#==============================================================================#

=item $gs->handle_events();

This function is usefull if you do not want to block on a wait_for_events()
call. You can select() (for read) on the server object, and when there is 
something to read, you call handle_events(). It returns the $event_sting if 
there was one, or undef if there was some other activity (usually a client
connect or disconnect).

=cut

sub handle_events {
	my ($obj) = @_;

	# Repeat select to find out who was talking to us.
	if (select(my $rout = $$obj->{_girder_rin}, undef, undef, 0)) {

		# Is it the server 
		if (vec($rout,$obj->fileno,1) == 1) {
			$obj->accept();
			return undef;
		} else {
			$obj->handle_client_input($rout);
		}

	} else {
		warnings::warn "Uh - no events to handle although handle_events called";
		return undef;
	}
}

#==============================================================================#
# IUO
#

sub accept {
	my ($obj) = @_;
	accept(my $cli = IO::Socket::INET->new, $obj);
	if ($obj->valid_client($cli)) {
		vec($$obj->{_girder_rin},$cli->fileno,1) = 1;
		$$obj->{_girder_authenticated}->{$cli->fileno} = undef;
		push @{$$obj->{_girder_clients}}, $cli;
		return $cli;
	} else {
		$cli->close;
		return undef;
	}
}

sub valid_client {
	#warn "Client connect";
	return 1;
}


sub drop_client {
	my ($obj,$cli) = @_;
	vec($$obj->{_girder_rin},$cli->fileno,1) = 0;
	delete $$obj->{_girder_authenticated}->{$cli->fileno};

	my $n = 0;
	foreach my $gcli (@{$$obj->{_girder_clients}}) {
		if ($cli == $gcli) {
			splice(@{$$obj->{_girder_clients}}, $n, 1);
			last;
		}
		$n++;
	}


	$cli->close;
}

sub handle_client_input {
	my ($obj,$rout) = @_;
	foreach my $cli (@{$$obj->{_girder_clients}}) {
		if (vec($rout,$cli->fileno,1) == 1) {
			if (defined(my $event = $cli->getline())) {
				$event =~ s/\r?\n$//;
				return $obj->parse_event($cli,$event);
			} else {
				$obj->drop_client($cli);
				return undef;
			}
		}
			
	}
	warnings::warn "Internal error - can't find file handle to read from";
}

sub parse_event {
	my ($obj,$cli,$event) = @_;

	if (!defined $$obj->{_girder_authenticated}->{$cli->fileno}) {

		# New client - must say 'quintessence' to get a cookie
		if ($event eq 'quintessence') {
			my $cookie = 'abcd';
			$$obj->{_girder_authenticated}->{$cli->fileno}=$cookie;
			$cli->print($cookie."\n");
		} else {
			# Bad dog - no buscuit
			$obj->drop_client($cli);
		}

	} elsif ($$obj->{_girder_authenticated}->{$cli->fileno} eq 'AUTH') {

		# Fully authenticated - this is an event string or close
		if ($event eq "close") {
			$obj->drop_client($cli);
		} else {
			return $event;
		}

	} else {

		# Sent cookie - waiting for reply
		my $cookie = $$obj->{_girder_authenticated}->{$cli->fileno};
		if ($event eq hash_password($cookie,$$obj->{_girder_pass})) {
			# Correctly authenticted
			$cli->print("accept\n");
			$$obj->{_girder_authenticated}->{$cli->fileno}='AUTH';
		} else {
			# Bad password
			$obj->drop_client($cli);
		}
	}
	return undef;
}

#==============================================================================#

=item $gs->close();

Politly shut down the server, dropping all active clients first.

=cut

sub close {
die "oh shit";
	my ($obj,@opts) = @_;

	# Shutdown all the servers clients
	foreach my $cli (@{$$obj->{_girder_clients}}) {
		$cli->close();
	}

	$$obj->{_girder_clients} = [];
	$$obj->{_girder_rin} = '';

	# Shutdown the server
	$obj->SUPER::close(@opts);
}
	

#==============================================================================#

sub DESTROY {
	my ($obj) = @_;
	$$obj->{_girder_pass} = undef;
	$$obj->{_girder_rin} = undef;
	$$obj->{_girder_clients} = undef;
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

L<Win32::Girder::IEvent::Client>.

L<IO::Socket::INET>.

=cut

# That's all folks..
#==============================================================================#
