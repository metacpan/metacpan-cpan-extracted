##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Server.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/13
## Modified 2021/09/13
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Server;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    # Import constants
    use WebSocket qw( :ws );
    use parent qw( WebSocket );
    use IO::Socket::INET;
    use IO::Select;
    use List::Util qw( min );
    use Nice::Try;
    use Want;
    use WebSocket::Connection;
    use WebSocket::Version;
    our $VERSION = 'v0.1.0';
    $SIG{PIPE} = 'IGNORE';
};

sub init
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    $self->{listen}         = undef();
    $self->{on_connect}     = sub{},
    $self->{on_shutdown}    = sub{},
    $self->{on_tick}        = sub{},
    $self->{port}           = 8080,
    $self->{silence_max}    = 20,
    $self->{subprotocol}    = [];
    $self->{tick_period}    = 0,
    # Used by WebSocket::Connection when comparing the version of the client handshake with the one we support here
    $self->{version}        = WebSocket::Version->new( WEBSOCKET_DRAFT_VERSION_DEFAULT );
    $self->{watch_readable} = {},
    $self->{watch_writable} = {},
    $self->{select_readable}= undef();
    $self->{select_writable}= undef();
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{silence_checkinterval} = $self->{silence_max} / 2;
    $self->message( 3, "Initiating watch_readable and watch_writable." );
    foreach my $watchtype ( qw( readable writable ) )
    {
        # Already setup because watch_readable or watch_writable was already passed as init parameters
        next if( $self->{ "select_${watchtype}" } );
        $self->{ "select_${watchtype}" } = IO::Select->new;
        my $key = "watch_${watchtype}";
        # return( $self->error( "$class parameter '$key' expects an array reference containing an even number of elements" ) ) if( scalar( @{$self->{ $key }} ) );
        # my @watch = @{$self->{ $key }};
        $self->{ $key } = {};
        # We watch_readable and watch_writable with default parameter
        $self->_watch( $watchtype, [] );
    }
    # Connections
    $self->{conns} = {};
    $self->{socket} = undef;
    return( $self );
}

sub connections
{
    my $self = shift( @_ );
    my @conns = grep{ $_->is_ready } map{ $_->{conn} } values( %{$self->{conns}} );
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->new_array( \@conns ) );
    }
    else
    {
        return( @conns );
    }
}

sub disconnect
{
    my( $self, $fh ) = @_;
    $self->{select_readable}->remove( $fh );
    $fh->close();
    CORE::delete( $self->{conns}->{ $fh } );
}

sub extensions { return( $self->_set_get_object_array_object( 'extensions', 'WebSocket::Extension', @_ ) ); }

sub ip { return( shift->_set_get_scalar_as_object( 'ip', @_ ) ); }

sub is_ssl { return( shift->_set_get_boolean( 'is_ssl', @_ ) ); }

sub listen { return( shift->_set_get_object_without_init( 'listen', 'IO::Socket', @_ ) ); }
 
sub on
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    while( my( $key, $value ) = each( %$opts ) )
    {
        return( $self->error( "Invalid event '$key'" ) ) if( !$self->can( "on_${key}" ) );
        return( $self->error( "Expected a code reference for event '$key', but got '", overload::StrVal( $value ), "'." ) ) if( ref( $value ) ne 'CODE' );
        $self->$key( $value ) || return( $self->pass_error );
    }
    return( $self );
}

sub on_connect { return( shift->_set_get_code( 'on_connect', @_ ) ); }

sub on_shutdown { return( shift->_set_get_code( 'on_shutdown', @_ ) ); }

sub on_tick { return( shift->_set_get_code( 'on_tick', @_ ) ); }

sub port { return( shift->_set_get_number( 'port', @_ ) ); }

sub shutdown
{
    my $self = shift( @_ );
    $self->message( 3, "Server shutdown called. Terminating ", $self->connections->length, " active connections." );
    my $shutdown_cb = $self->on_shutdown || sub{};
    $shutdown_cb->( $self );
    my $socket = $self->listen || return( $self->error( "Cannot find the socket object!" ) );
    $self->connections->for(sub
    {
        $_->disconnect( 1001 );
    });
    $self->{select_readable}->remove( $socket );
    $socket->shutdown(2);
    $socket->close();
    return( $self );
}

sub silence_checkinterval { return( shift->_set_get_number( 'silence_checkinterval', @_ ) ); }

sub silence_max { return( shift->_set_get_number( 'silence_max', @_ ) ); }

sub socket { return( shift->_set_get_object_without_init( 'listen', 'IO::Socket', @_ ) ); }

sub start
{
    my $self = shift( @_ );
    my $sock;
    my $use_ssl = 0;
    if( $self->_is_a( $self->listen, 'IO::Socket' ) )
    {
        # if we got a server, make sure it's valid by clearing errors and checking errors anyway; if there's still an error, it's closed
        $sock = $self->listen;
        $self->message( 3, "Starting WebSocket server using socket '$self->{listen}' provided with port '", $sock->sockport, "'." );
        $sock->clearerr;
        return( $self->error( "Failed to start websocket server; the TCP server provided via 'listen' is invalid. (is the listening socket is closed? are you trying to reuse a server that has already shut down?)" ) ) if( $sock->error );
        $use_ssl = ( $sock->isa( 'IO::Socket::SSL' ) || $sock->can( 'accept_SSL' ) ) ? 1 : 0;
    }
    else
    {
        $self->message( 3, "Starting WebSocket server by initiating our own IO::Socket::INET object on port '$self->{port}'." );
        # if we merely got a port, set up a reasonable default tcp server
        my $params =
        {
            Listen    => 5,
            Proto     => 'tcp',
            ReuseAddr => 1,
        };
        $params->{LocalPort} = $self->port->scalar if( $self->port );
        $sock = IO::Socket::INET->new( %$params ) ||
            return( $self->error( "Failed to listen on port $self->{port}: $!" ) );
        $self->listen( $sock );
        if( !$self->port )
        {
            $self->message( 3, "Using auto allocated port '", $sock->sockport, "'." );
            $self->port( $sock->sockport );
        }
    }
    $self->is_ssl( $use_ssl );
    $self->ip( $sock->sockhost );

    $self->{select_readable}->add( $sock );

    $self->{conns} = {};
    my $silence_nextcheck = $self->silence_max ? ( time() + $self->silence_checkinterval ) : 0;
    my $tick_next = $self->tick_period ? ( time() + $self->tick_period ) : 0;

    my $connect_cb = $self->on_connect || sub{};
    my $tick_cb    = $self->on_tick || sub{};
    $self->message( 3, "Starting the loop until the socket is not opened anymore." );
    while( $sock->opened )
    {
        my $silence_checktimeout = $self->silence_max ? ( $silence_nextcheck - time() ) : undef();
        my $tick_timeout = $self->tick_period ? ( $tick_next - time() ) : undef();
        my $timeout = List::Util::min( grep{ defined( $_ ) } ( $silence_checktimeout, $tick_timeout ) );

        my( $ready_read, $ready_write, undef() ) = IO::Select->select(
            $self->{select_readable},
            $self->{select_writable},
            undef(),
            $timeout
        );
        foreach my $fh ( $ready_read ? @$ready_read : () )
        {
            if( $fh == $sock )
            {
                my $client = $sock->accept;
                next unless $client;
                # XXX Connection
                $self->message( 3, "Handling client connection from host '", $client->peerhost, "' on port '", $client->peerport, "'." );
                my $conn = WebSocket::Connection->new(
                    socket      => $client,
                    server      => $self,
                    subprotocol => $self->subprotocol,
                    debug       => $self->debug,
                );
                $self->{conns}->{ $client } = { conn => $conn, lastrecv => time() };
                $self->{select_readable}->add( $client );
                $connect_cb->( $self, $conn );
            }
            elsif( $self->{watch_readable}->{ $fh } )
            {
                $self->{watch_readable}->{ $fh }->{cb}->( $self, $fh );
            }
            elsif( $self->{conns}->{ $fh } )
            {
                my $def = $self->{conns}->{ $fh };
                $def->{lastrecv} = time;
                my $rv = $def->{conn}->recv();
                if( !defined( $rv ) )
                {
                    $self->message( 3, "Connection ended with an error code '", $def->{conn}->error->code, "' and message '", $def->{conn}->error->message, "'." );
                }
            }
            else
            {
                $self->message( 3, "*** Filehandle $fh became readable, but no handler took responsibility for it; removing it." );
                warning::warn( "Filehandle $fh became readable, but no handler took responsibility for it; removing it\n" ) if( warnings::enabled() );
                $self->{select_readable}->remove( $fh );
            }
        }

        foreach my $fh ( $ready_write ? @$ready_write : () )
        {
            if( $self->{watch_writable}->{ $fh } )
            {
                $self->{watch_writable}->{ $fh }->{cb}->( $self, $fh );
            }
            else
            {
                $self->message( 3, "Filehandle $fh became writable, but no handler took responsibility for it; removing it." );
                warnings::warn( "Filehandle $fh became writable, but no handler took responsibility for it; removing it\n" ) if( warnings::enabled() );
                $self->{select_writable}->remove( $fh );
            }
        }

        if( $self->silence_max )
        {
            my $now = time();
            if( $silence_nextcheck < $now )
            {
                my $lastcheck = $silence_nextcheck - $self->silence_checkinterval;
                $_->{conn}->send( 'ping' ) for grep { $_->{conn}->is_ready && $_->{lastrecv} < $lastcheck } values %{$self->{conns}};
                $silence_nextcheck = $now + $self->silence_checkinterval;
            }
        }

        if( $self->tick_period && $tick_next < time() )
        {
            $tick_cb->( $self );
            $tick_next += $self->tick_period;
        }
    }
    $self->message( 3, "Server done, connections closed." );
    return( $self );
}

sub subprotocol
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $ref = $self->_is_array( $_[0] ) 
            ? shift( @_ ) 
            : @_ == 1 
                ? ( $self->_is_object( $_[0] ) && overload::Method( $_[0], '""' ) )
                    ? [CORE::split( /[[:blank:]\h]+/, "$_[0]" )]
                    : ref( $_[0] )
                        ? shift( @_ )
                        : [CORE::split( /[[:blank:]\h]+/, $_[0] )]
                : [@_];
        $self->message( 3, "Called with -> ", sub{ $self->dump( $ref ) } );
        $self->_set_get_array_as_object( 'subprotocol', $ref ) || return( $self->pass_error );
    }
    return( $self->_set_get_array_as_object( 'subprotocol' ) );
}

sub tick_period { return( shift->_set_get_number( 'tick_period', @_ ) ); }

sub unwatch_readable
{
    my $self = shift( @_ );
    return( $self->_unwatch( readable => @_) );
}

sub unwatch_writable
{
    my $self = shift( @_ );
    return( $self->_unwatch( writable => @_ ) );
}

# Server response version header can contain one or more versions
sub version
{
    my $self = shift( @_ );
    # When setting value, we use an array object of WebSocket::Version objects
    if( @_ )
    {
        my $v = shift( @_ );
        if( !ref( $v ) || ( $self->_is_object( $v ) && overload::Method( $v, '""' ) ) )
        {
            $v = [split( /[[:blank:]\h]*\,[[:blank:]\h]*/, "$v" )];
        }
        $self->_set_get_object_array_object( 'version', 'WebSocket::Version', $v );
    }
    return( $self->_set_get_object_array_object( 'version', 'WebSocket::Version' )->first );
}

sub versions { return( shift->_set_get_object_array_object( 'version', 'WebSocket::Version', @_ ) ); }

sub watch_readable
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_array( @_ );
    return( $self->error( "watch_readable expects an even number of arguments" ) ) if( @$args % 2 );
    $self->{select_readable} ||= IO::Select->new;
    return( $self->_watch( readable => @$args ) );
}

sub watch_writable
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_array( @_ );
    return( $self->error( "watch_writable expects an even number of arguments" ) ) if( @$args % 2 );
    $self->{select_writable} ||= IO::Select->new;
    return( $self->_watch( writable => @$args ) );
}

sub watched_readable
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $fh = shift( @_ );
        return( $self->{watch_readable}->{ $fh }->{cb} );
    }
    return( map{ $_->{fh}, $_->{cb} } values( %{$self->{watch_readable}} ) );
}

sub watched_writable
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $fh = shift( @_ );
        return( $self->{watch_writable}->{ $fh }->{cb} );
    }
    return( map{ $_->{fh}, $_->{cb} } values( %{$self->{watch_writable}} ) );
}

sub _unwatch
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    foreach my $fh ( @_ )
    {
        $self->{ "select_${type}" }->remove( $fh );
        CORE::delete( $self->{ "watch_${type}" }->{ $fh } );
    }
    return( $self );
}

sub _watch
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    return( $self->error( "watch_${type} expects an even number of arguments after the type" ) ) if( @_ % 2 );
    for( my $i = 0; $i < @_; $i += 2 )
    {
        my( $fh, $cb ) = ( $_[ $i ], $_[ $i + 1 ] );
        return( $self->error( "watch_${type} expects the second value of each pair to be a code reference, but element $i was not" ) ) if( ref( $cb ) ne 'CODE' );
        if( $self->{ "watch_${type}" }->{ $fh } )
        {
            warnings::warn( "watch_${type} was given a filehandle at index $i which is already being watched; ignoring!" ) if( warnings::enabled() );
            next;
        }
        $self->{ "select_${type}" }->add( $fh );
        $self->{ "watch_${type}" } = {} unless( ref( $self->{ "watch_${type}" } ) eq 'HASH' );
        $self->{ "watch_${type}" }->{ $fh } = { fh => $fh, cb => $cb };
    }
    return( $self );
}

1;

__END__

=encoding utf-8

=head1 NAME

WebSocket::Server - WebSocket Server

=head1 SYNOPSIS

    use WebSocket::Server;
    use JSON;
    my $origin = 'http://localhost';
    my $j = JSON->new->relaxed->convert_blessed;
    my $ws = WebSocket::Server->new(
        debug => 3,
        port => 8080,
        on_connect => sub
        {
            my( $serv, $conn ) = @_;
            $conn->on(
                handshake => sub
                {
                    my( $conn, $handshake ) = @_;
                    print( "Connection from ip '", $conn->ip, "' on port '", $conn->port, "'\n" );
                    print( "Query string: '", $handshake->request->uri->query, "'\n" );
                    print( "Origin is: '", $handshake->request->origin, "', ", ( $handshake->request->origin eq $origin ? '' : 'not ' ), "ok\n" );
                    # $conn->disconnect() unless( $handshake->request->origin eq $origin );
                },
                ready => sub
                {
                    my $conn = shift( @_ );
                    my $hash = { code => 200, type => 'user', message => "Hello" };
                    my $json = $j->encode( $hash );
                    $conn->send_utf8( $json );
                },
                utf8 => sub
                {
                    my( $conn, $msg ) = @_;
                    # $conn->send_utf8( $msg );
                    print( "Received message: '$msg'\n" );
                },
                disconnect => sub
                {
                    my( $conn, $code, $reason ) = @_;
                    print( "Client diconnected from ip '", $conn->ip, "'\n" );
                },
            );
        },
    ) || die( WebSocket::Server->error );
    $ws->start || die( $ws->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a server class for the WebSocket protocol.

=head1 CONSTRUCTOR

=head2 new

Instantiate a new L<WebSocket> server object. This takes the following options:

=over 4

=item I<extensions>

Optional. One or more extension enabled for this server. For example C<permessage-deflate> to enable message compression.

You can set this to either a string or a L<WebSocket::Extension> object if you want, for example to set the extension parameters.

See L<rfc6455 section 9.1|https://datatracker.ietf.org/doc/html/rfc6455#section-9.1> for more information on extension.

Seel also L</compression_threshold>.

=item I<listen>

Optional. A L<IO::Socket> object, or one of its inheriting packages. This enables you to instantiate your own L<IO::Socket> object and pass it here to be used. For example:

    my $ssl_server = IO::Socket::SSL->new(
        Listen             => 5,
        LocalPort          => 8080,
        Proto              => 'tcp',
        SSL_startHandshake => 0,
        SSL_cert_file      => '/path/to/server.crt',
        SSL_key_file       => '/path/to/server.key',
    ) or die "failed to listen: $!";
    my $server = WebSocket::Server->new( listen => $ssl_server ) || die( WebSocket::Server->error );

=item I<on_connect>

A code reference that will be triggered upon connection from client.

It will be passed the the server object and the connection object (L<WebSocket::Connection>).

=item I<on_shutdown>

A code reference that will be triggered upon termination of the connection.

=item I<on_tick>

A code reference that will be triggered for every tick.

=item I<port>

The port number on which to connect.

=item I<silence_max>

=item I<tick_period>

Frequency for the tick.

=item I<version>

The version supported. Defaults to C<draft-ietf-hybi-17> which means version C<13> (the latest as of 2021-09-24)

See also L</version> to change this afterward.

=item I<watch_readable>

=item I<watch_writable>

=back

If there are any issue with the instantiation, it will return C<undef> and set an error L<WebSocket::Exception> that can be retrieved with the L<error|Module::Generic/error> method inherited from L<Module::Generic>

=head1 METHODS

=head2 compression_threshold

Inherited from L<WebSocket>

Set or get the threshold in bytes above which the ut8 or binary messages will be compressed if the client and the server support compression and it is activated as an extension.

=head2 connections

Returns the client connections currently active.

In object context, this returns a L<Module::Generic::Array>, such as:

    $server->connections->for(sub
    {
        my $conn = shift( @_ );
        print( "Connection from ip '", $conn->ip, "' on port '", $conn->port, "'\n" );
    });

In other context, this returns a regular array:

    for( $server->connections )
    {
        print( "Connection from ip '", $_->ip, "' on port '", $_->port, "'\n" );
    }

=head2 disconnect

Provided with the client socket filehandle and this will close the connection for that client.

=head2 extensions

Set or get the extension enabled for this server. For example C<permessage-deflate> to enable message compression.

You can set this to either a string or a L<WebSocket::Extension> object if you want, for example to set the extension parameters.

See L<rfc6455 section 9.1|https://datatracker.ietf.org/doc/html/rfc6455#section-9.1> for more information on extension.

=head2 ip

Set or get the ip address to which the server is connected to.

=head2 is_ssl

Returns true if the server is using a ssl connection, false otherwise.

This value is set automatically upon calling L</start>.

=head2 listen

Get the L<IO::Socket> (or any of its inheriting classes such as L<IO::Socket::INET> or L<IO::Socket::SSL>) server socket object.

This value is set automatically upon calling L</start>, or it can also be provided upon server object instantiation. See L</new> option parameters.

=head2 on

Provided with an array or array reference of event name and core reference pairs and this will set those event handlers.

It returns the current object.

=head2 on_connect

Set or get the code reference for the event handler that is triggered when there is a new client connection.

The handler is passed the server object and the connection object.

    $server->on_connect(sub
    {
        my( $s, $conn ) = @_;
        print( "Connection received from ip '", $conn->ip, "'\n" );
    });

=head2 on_shutdown

Set or get the code reference for the event handler that is triggered when the server is shutting down and before calling L</disconnect> on every connected client.

=head2 on_tick

Set or get the code reference for the event handler that is triggered for every tick, if enabled.

The handler is passed the server object.

=head2 port

Returns the port to which this server is listening to.

=head2 shutdown

Shuts down the server connection, calls the event handler L</on_shutdown>, and calls disconnect on each active client connection passing them the code L<1001|WebSocket/WS_GONE>

It returns the current server object.

=head2 silence_checkinterval

=head2 silence_max

=head2 socket

This is an alias for L</listen>. It returns the server socket object.

=head2 start

Starts the server.

If a socket object has already been initiated and provided with the L</new> option I<listen>, then it will be used, otherwise, it will instantiate a new L<IO::Socket::INET> connection. If a I<port> option was provided in L</new>, it will be used, otherwise it will be auto allocated and the port assigned can then be retrieved using the L</port> method.

For every client connection received, it will instantiate a new L<WebSocket::Connection> object and call the L</on_connect> event handler, passing it the server object and the connection object.

If I<tick_period> option in L</new> has been set, this will trigger the L</on_tick> event handler at the I<tick_period> interval.

=head2 subprotocol

Set or get an array object of WebSocket protocols. This array object will be passed to each new L<WebSocket::Connection> object upon each connection received.

Returns a L<Module::Generic::Array> object.

See L<rfc6455 for more information|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

=head2 tick_period

Set or get the tick interval period.

=head2 unwatch_readable

=head2 unwatch_writable

=head2 version

The version supported. Defaults to C<draft-ietf-hybi-17> which means version C<13> (the latest as of 2021-09-24)

See L<rfc6455 section 4.4 for more information|https://datatracker.ietf.org/doc/html/rfc6455#section-4.4>

Returns an array of L<WebSocket::Version> objects, each stringifies to its numeric value.

=head2 versions

Set or get the list of supported protocol versions.

It can take inteer sucha s C<13>, which is the latest WebSocket rfc6455 protocol version, or one or more L<WebSocket::Version> objects.

=head2 watch_readable

=head2 watch_writable

=head2 watched_readable

=head2 watched_writable

=head1 CREDITS

Graham Ollis for L<AnyEvent::WebSocket::Client>, Eric Wastl for L<Net::WebSocket::Server>, Vyacheslav Tikhanovsky aka VTI for L<Protocol::WebSocket>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Client>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut

