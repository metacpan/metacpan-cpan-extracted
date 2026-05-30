package Zuzu::Module::Socks;

use utf8;

our $VERSION = '0.001002';

use IO::Socket::INET ();
use IO::Socket::UNIX ();
use Socket qw(
	SOCK_DGRAM
	SOCK_STREAM
);
use Scalar::Util qw( blessed );

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	zuzu_bool
);
use Zuzu::Value::Function;

sub _sock_from_object {
	my ( $obj ) = @_;

	return undef if not blessed($obj);
	return undef if not $obj->isa( 'Zuzu::Value::Object' );
	return undef if not exists $obj->slots->{_sock};

	return $obj->slots->{_sock};
}

sub _peer_from_argument {
	my ( $value ) = @_;

	return undef if not defined $value;
	return undef if not blessed($value);
	return undef if not $value->isa( 'Zuzu::Value::Object' );
	return undef if not exists $value->slots->{_sock};

	my $peer = $value->slots->{_sock};
	return undef if not defined $peer;

	return $peer->peername;
}

sub _raw_mode {
	my ( $value ) = @_;

	return zuzu_bool( $value, 0 ) ? 1 : 0;
}

sub _call_callback {
	my ( $runtime, $callback, $args ) = @_;

	return if not blessed($callback)
		or not $callback->isa( 'Zuzu::Value::Function' );

	$runtime->_call_function( $callback, $args, '<std/io/socks>', 0 );

	return;
}

sub _assert_net {
	my ( $runtime, $method ) = @_;

	$runtime->assert_capability(
		'net',
		"Socks.$method is denied by runtime policy",
		'<runtime>',
		0,
	);

	return;
}

sub _new_socket_object {
	my ( $class_obj, $socket, $is_raw ) = @_;

	return native_object(
		class => $class_obj,
		slots => {
			_sock => $socket,
			_raw => $is_raw ? 1 : 0,
		},
		const => {
			_sock => 1,
			_raw => 0,
		},
	);
}

sub _apply_read_mode {
	my ( $socket, $raw ) = @_;

	return if not defined $socket;
	return if $raw;

	binmode $socket, ':encoding(UTF-8)';

	return;
}

sub _recv_max_bytes {
	my ( $value ) = @_;

	my $max = defined $value ? int( $value ) : 65536;
	$max = 1 if $max < 1;

	return $max;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $socket_class = native_class(
		name => 'Socket',
	);
	my $tcp_socket_class = native_class(
		name => 'TCPSocket',
	);
	my $tcp_server_class = native_class(
		name => 'TCPServer',
	);
	my $udp_socket_class = native_class(
		name => 'UDPSocket',
	);
	my $unix_socket_class = native_class(
		name => 'UnixSocket',
	);
	my $unix_server_class = native_class(
		name => 'UnixServer',
	);

	for my $klass ( $socket_class, $tcp_socket_class, $udp_socket_class, $unix_socket_class ) {
		$klass->methods->{read} = native_function(
			name => 'read',
			native => sub {
				my ( $self, $length ) = @_;
				_assert_net( $runtime, 'read' );
				my $sock = _sock_from_object( $self );
				return undef if not defined $sock;
				my $bytes = defined $length ? int( $length ) : 4096;
				$bytes = 1 if $bytes < 1;
				my $buffer = '';
				my $count = read( $sock, $buffer, $bytes );
				return undef if not defined $count;
				return undef if $count == 0;
				return $buffer;
			},
		);

		$klass->methods->{write} = native_function(
			name => 'write',
			native => sub {
				my ( $self, @args ) = @_;
				_assert_net( $runtime, 'write' );
				my $sock = _sock_from_object( $self );
				return 0 if not defined $sock;
				my $data = join '', map { defined $_ ? "$_" : '' } @args;
				my $ok = print { $sock } $data;
				return $ok ? length( $data ) : 0;
			},
		);

		$klass->methods->{print} = native_function(
			name => 'print',
			native => sub {
				my ( $self, @args ) = @_;
				_assert_net( $runtime, 'print' );
				my $sock = _sock_from_object( $self );
				return undef if not defined $sock;
				my $data = join '', map { defined $_ ? "$_" : '' } @args;
				print { $sock } $data;
				return undef;
			},
		);

		$klass->methods->{say} = native_function(
			name => 'say',
			native => sub {
				my ( $self, @args ) = @_;
				_assert_net( $runtime, 'say' );
				my $sock = _sock_from_object( $self );
				return undef if not defined $sock;
				my $data = join '', map { defined $_ ? "$_" : '' } @args;
				print { $sock } $data . "\n";
				return undef;
			},
		);

		$klass->methods->{next_line} = native_function(
			name => 'next_line',
			native => sub {
				my ( $self, $raw_opt ) = @_;
				_assert_net( $runtime, 'next_line' );
				my $sock = _sock_from_object( $self );
				return undef if not defined $sock;
				my $raw = _raw_mode( $raw_opt );
				_apply_read_mode( $sock, $raw );
				my $line = <$sock>;
				return defined $line ? $line : undef;
			},
		);

		$klass->methods->{each_line} = native_function(
			name => 'each_line',
			native => sub {
				my ( $self, $callback, $raw_opt ) = @_;
				_assert_net( $runtime, 'each_line' );
				my $sock = _sock_from_object( $self );
				return $self if not defined $sock;
				my $raw = _raw_mode( $raw_opt );
				_apply_read_mode( $sock, $raw );
				while ( my $line = <$sock> ) {
					_call_callback( $runtime, $callback, [ $line ] );
				}
				return $self;
			},
		);

		$klass->methods->{close} = native_function(
			name => 'close',
			native => sub {
				my ( $self ) = @_;
				_assert_net( $runtime, 'close' );
				my $sock = _sock_from_object( $self );
				return 0 if not defined $sock;
				my $ok = close $sock;
				return $ok ? 1 : 0;
			},
		);
	}

	$socket_class->methods->{is_open} = native_function(
		name => 'is_open',
		native => sub {
			my ( $self ) = @_;
			_assert_net( $runtime, 'is_open' );
			my $sock = _sock_from_object( $self );
			return 0 if not defined $sock;
			return fileno( $sock ) ? 1 : 0;
		},
	);

	$tcp_socket_class->methods->{peer_host} = native_function(
		name => 'peer_host',
		native => sub {
			my ( $self ) = @_;
			my $sock = _sock_from_object( $self );
			return undef if not defined $sock;
			return $sock->peerhost;
		},
	);

	$tcp_socket_class->methods->{peer_port} = native_function(
		name => 'peer_port',
		native => sub {
			my ( $self ) = @_;
			my $sock = _sock_from_object( $self );
			return undef if not defined $sock;
			return $sock->peerport;
		},
	);


	for my $klass ( $tcp_server_class, $unix_server_class ) {
		$klass->methods->{close} = native_function(
			name => 'close',
			native => sub {
				my ( $self ) = @_;
				my $sock = _sock_from_object( $self );
				return 0 if not defined $sock;
				my $ok = close $sock;
				return $ok ? 1 : 0;
			},
		);
	}

	$tcp_server_class->methods->{accept} = native_function(
		name => 'accept',
		native => sub {
			my ( $self, $raw_opt ) = @_;
			_assert_net( $runtime, 'accept' );
			my $server = _sock_from_object( $self );
			return undef if not defined $server;
			my $client = $server->accept();
			return undef if not defined $client;
			my $raw = _raw_mode( $raw_opt );
			_apply_read_mode( $client, $raw );
			return _new_socket_object( $tcp_socket_class, $client, $raw );
		},
	);

	$tcp_server_class->methods->{port} = native_function(
		name => 'port',
		native => sub {
			my ( $self ) = @_;
			my $server = _sock_from_object( $self );
			return undef if not defined $server;
			return $server->sockport;
		},
	);

	$tcp_server_class->methods->{host} = native_function(
		name => 'host',
		native => sub {
			my ( $self ) = @_;
			my $server = _sock_from_object( $self );
			return undef if not defined $server;
			return $server->sockhost;
		},
	);


	$udp_socket_class->methods->{port} = native_function(
		name => 'port',
		native => sub {
			my ( $self ) = @_;
			my $sock = _sock_from_object( $self );
			return undef if not defined $sock;
			return $sock->sockport;
		},
	);

	$udp_socket_class->methods->{host} = native_function(
		name => 'host',
		native => sub {
			my ( $self ) = @_;
			my $sock = _sock_from_object( $self );
			return undef if not defined $sock;
			return $sock->sockhost;
		},
	);

	$udp_socket_class->methods->{recv} = native_function(
		name => 'recv',
		native => sub {
			my ( $self, $max_bytes, $flags ) = @_;
			_assert_net( $runtime, 'recv' );
			my $sock = _sock_from_object( $self );
			return undef if not defined $sock;
			my $max = _recv_max_bytes( $max_bytes );
			my $buffer = '';
			my $ok = recv( $sock, $buffer, $max, int( $flags // 0 ) );
			return undef if not defined $ok;
			return $buffer;
		},
	);

	$udp_socket_class->methods->{send} = native_function(
		name => 'send',
		native => sub {
			my ( $self, $data, $peer_or_flags, $maybe_flags ) = @_;
			_assert_net( $runtime, 'send' );
			my $sock = _sock_from_object( $self );
			return 0 if not defined $sock;
			my $payload = defined $data ? "$data" : '';
			my $peer = _peer_from_argument( $peer_or_flags );
			my $flags = 0;
			if ( defined $peer ) {
				$flags = int( $maybe_flags // 0 );
			}
			else {
				$flags = int( $peer_or_flags // 0 );
			}
			my $written;
			if ( defined $peer ) {
				$written = send( $sock, $payload, $flags, $peer );
			}
			else {
				$written = send( $sock, $payload, $flags );
			}
			return defined $written ? $written : 0;
		},
	);

	$unix_server_class->methods->{accept} = native_function(
		name => 'accept',
		native => sub {
			my ( $self, $raw_opt ) = @_;
			_assert_net( $runtime, 'accept' );
			my $server = _sock_from_object( $self );
			return undef if not defined $server;
			my $client = $server->accept();
			return undef if not defined $client;
			my $raw = _raw_mode( $raw_opt );
			_apply_read_mode( $client, $raw );
			return _new_socket_object( $unix_socket_class, $client, $raw );
		},
	);

	$unix_server_class->methods->{path} = native_function(
		name => 'path',
		native => sub {
			my ( $self ) = @_;
			my $server = _sock_from_object( $self );
			return undef if not defined $server;
			return $server->hostpath;
		},
	);

	my $connect_tcp = native_function(
		name => 'connect_tcp',
		native => sub {
			my ( $host, $port, $raw_opt ) = @_;
			_assert_net( $runtime, 'connect_tcp' );
			my $raw = _raw_mode( $raw_opt );
			my $sock = IO::Socket::INET->new(
				Proto => 'tcp',
				PeerHost => defined $host ? "$host" : '127.0.0.1',
				PeerPort => int( $port // 0 ),
			);
			return undef if not defined $sock;
			_apply_read_mode( $sock, $raw );
			return _new_socket_object( $tcp_socket_class, $sock, $raw );
		},
	);

	my $listen_tcp = native_function(
		name => 'listen_tcp',
		native => sub {
			my ( $host, $port, $backlog ) = @_;
			_assert_net( $runtime, 'listen_tcp' );
			my $sock = IO::Socket::INET->new(
				Proto => 'tcp',
				LocalHost => defined $host ? "$host" : '127.0.0.1',
				LocalPort => int( $port // 0 ),
				Listen => int( $backlog // 5 ),
				ReuseAddr => 1,
			);
			return undef if not defined $sock;
			return _new_socket_object( $tcp_server_class, $sock, 1 );
		},
	);

	my $bind_udp = native_function(
		name => 'bind_udp',
		native => sub {
			my ( $host, $port, $raw_opt ) = @_;
			_assert_net( $runtime, 'bind_udp' );
			my $raw = _raw_mode( $raw_opt );
			my $sock = IO::Socket::INET->new(
				Proto => 'udp',
				LocalHost => defined $host ? "$host" : '127.0.0.1',
				LocalPort => int( $port // 0 ),
				Type => SOCK_DGRAM,
				ReuseAddr => 1,
			);
			return undef if not defined $sock;
			_apply_read_mode( $sock, $raw );
			return _new_socket_object( $udp_socket_class, $sock, $raw );
		},
	);

	my $connect_udp = native_function(
		name => 'connect_udp',
		native => sub {
			my ( $host, $port, $raw_opt ) = @_;
			_assert_net( $runtime, 'connect_udp' );
			my $raw = _raw_mode( $raw_opt );
			my $sock = IO::Socket::INET->new(
				Proto => 'udp',
				PeerHost => defined $host ? "$host" : '127.0.0.1',
				PeerPort => int( $port // 0 ),
				Type => SOCK_DGRAM,
			);
			return undef if not defined $sock;
			_apply_read_mode( $sock, $raw );
			return _new_socket_object( $udp_socket_class, $sock, $raw );
		},
	);

	my $listen_unix = native_function(
		name => 'listen_unix',
		native => sub {
			my ( $path, $backlog ) = @_;
			_assert_net( $runtime, 'listen_unix' );
			return undef if not defined $path;
			unlink "$path";
			my $sock = IO::Socket::UNIX->new(
				Type => SOCK_STREAM,
				Local => "$path",
				Listen => int( $backlog // 5 ),
			);
			return undef if not defined $sock;
			return _new_socket_object( $unix_server_class, $sock, 1 );
		},
	);

	my $connect_unix = native_function(
		name => 'connect_unix',
		native => sub {
			my ( $path, $raw_opt ) = @_;
			_assert_net( $runtime, 'connect_unix' );
			return undef if not defined $path;
			my $raw = _raw_mode( $raw_opt );
			my $sock = IO::Socket::UNIX->new(
				Type => SOCK_STREAM,
				Peer => "$path",
			);
			return undef if not defined $sock;
			_apply_read_mode( $sock, $raw );
			return _new_socket_object( $unix_socket_class, $sock, $raw );
		},
	);

	return {
		Socket => $socket_class,
		TCPSocket => $tcp_socket_class,
		TCPServer => $tcp_server_class,
		UDPSocket => $udp_socket_class,
		UnixSocket => $unix_socket_class,
		UnixServer => $unix_server_class,
		connect_tcp => $connect_tcp,
		listen_tcp => $listen_tcp,
		bind_udp => $bind_udp,
		connect_udp => $connect_udp,
		listen_unix => $listen_unix,
		connect_unix => $connect_unix,
	};
}

=pod

=head1 NAME

Zuzu::Module::Socks - builtin std/io/socks module.

=head1 SYNOPSIS

  from std/io/socks import *;

  let srv := listen_tcp( "127.0.0.1", 0 );
  let cli := connect_tcp( "127.0.0.1", srv.port() );
  let peer := srv.accept();

  cli.say( "hello" );
  let line := peer.next_line();

=head1 DESCRIPTION

This module exposes practical networking helpers for:

=over

=item *

TCP client/server sockets.

=item *

UDP sockets using datagram send/recv.

=item *

Unix-domain stream sockets.

=back

Where possible, socket methods are aligned with stream/file
interfaces, including C<read>, C<write>, C<print>, C<say>,
C<next_line>, C<each_line>, and C<close>.

=head1 EXPORTED SYMBOLS

=over

=item C<Socket>

Common stream-like methods across socket objects.

=item C<TCPSocket>, C<TCPServer>

TCP client/server classes.

=item C<UDPSocket>

UDP socket class with C<send> and C<recv>.

=item C<UnixSocket>, C<UnixServer>

Unix-domain stream client/server classes.

=item C<connect_tcp>, C<listen_tcp>

Create TCP client/server sockets.

=item C<bind_udp>, C<connect_udp>

Create UDP sockets.

=item C<listen_unix>, C<connect_unix>

Create Unix-domain stream sockets.

=back

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Socks >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
