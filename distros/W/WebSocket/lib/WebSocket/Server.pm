##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Server.pm
## Version v0.2.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/13
## Modified 2023/04/29
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Server;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use vars qw( $VERSION );
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
    our $VERSION = 'v0.2.0';
    $SIG{PIPE} = 'IGNORE';
};

sub init
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    # We are careful not to override object default value set by child class inheriting from our class
    $self->{connection_class} = 'WebSocket::Connection' unless( defined( $self->{connection_class} ) );
    # If true, connections will return a list, otherwise it will return an array object
    $self->{legacy}         = 0 unless( defined( $self->{legacy} ) );
    $self->{listen}         = undef() unless( defined( $self->{listen} ) );
    $self->{on_accept}      = sub{} unless( defined( $self->{on_accept} ) );
    $self->{on_connect}     = sub{} unless( defined( $self->{on_connect} ) );
    $self->{on_shutdown}    = sub{} unless( defined( $self->{on_shutdown} ) );
    $self->{on_tick}        = sub{} unless( defined( $self->{on_tick} ) );
    $self->{port}           = 8080 unless( defined( $self->{port} ) );
    $self->{silence_max}    = 20 unless( defined( $self->{silence_max} ) );
    $self->{subprotocol}    = [] unless( defined( $self->{subprotocol} ) );
    $self->{tick_period}    = 0 unless( defined( $self->{tick_period} ) );
    # Used by WebSocket::Connection when comparing the version of the client handshake with the one we support here
    $self->{version}        = WebSocket::Version->new( WEBSOCKET_DRAFT_VERSION_DEFAULT ) unless( defined( $self->{version} ) );
    $self->{watch_readable} = {};
    $self->{watch_writable} = {};
    $self->{select_readable}= undef();
    $self->{select_writable}= undef();
    $self->{_exception_class}     = 'WebSocket::Exception' unless( defined( $self->{_exception_class} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{silence_checkinterval} = $self->{silence_max} / 2;
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

sub connection_class { return( shift->_set_get_scalar( 'connection_class', @_ ) ); }

sub connections
{
    my $self = shift( @_ );
    my @conns = grep{ $_->is_ready } map{ $_->{conn} } values( %{$self->{conns}} );
    if( want( 'LIST' ) || $self->legacy )
    {
        return( @conns );
    }
    return( $self->new_array( \@conns ) );
}

sub disconnect
{
    my( $self, $fh ) = @_;
    $self->{select_readable}->remove( $fh );
    # We should shutdown to tell the other side of the TCP that we are done, 
    # then remove the filehandle
    # <https://www.perlmonks.org/?node_id=108244>
    $fh->shutdown(SHUT_RDWR) || do
    {
        warn( "Error shutting down the client socket: $!" ) if( $self->_warnings_is_enabled() );
    };
    $fh->close();
    CORE::delete( $self->{conns}->{ $fh } );
}

sub extensions { return( shift->_set_get_object_array_object( 'extensions', 'WebSocket::Extension', @_ ) ); }

sub ip { return( shift->_set_get_scalar_as_object( 'ip', @_ ) ); }

sub is_ssl { return( shift->_set_get_boolean( 'is_ssl', @_ ) ); }

sub legacy { return( shift->_set_get_boolean( 'legacy', @_ ) ); }

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

sub on_accept { return( shift->_set_get_code( 'on_accept', @_ ) ); }

sub on_connect { return( shift->_set_get_code( 'on_connect', @_ ) ); }

sub on_shutdown { return( shift->_set_get_code( 'on_shutdown', @_ ) ); }

sub on_tick { return( shift->_set_get_code( 'on_tick', @_ ) ); }

sub port { return( shift->_set_get_number( 'port', @_ ) ); }

sub shutdown
{
    my $self = shift( @_ );
    my $shutdown_cb = $self->on_shutdown || sub{};
    
    try
    {
        $shutdown_cb->( $self );
    }
    catch( $e )
    {
        warn( "Error calling the shutdown callback: $e" ) if( $self->_warnings_is_enabled() );
        return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
    }
    
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
        $sock->clearerr;
        return( $self->error( "Failed to start websocket server; the TCP server provided via 'listen' is invalid. (is the listening socket is closed? are you trying to reuse a server that has already shut down?)" ) ) if( $sock->error );
        $use_ssl = ( $sock->isa( 'IO::Socket::SSL' ) || $sock->can( 'accept_SSL' ) ) ? 1 : 0;
    }
    else
    {
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
            $self->port( $sock->sockport );
        }
    }
    $self->is_ssl( $use_ssl );
    $self->ip( $sock->sockhost );

    $self->{select_readable}->add( $sock );

    $self->{conns} = {};
    my $silence_nextcheck = $self->silence_max ? ( time() + $self->silence_checkinterval ) : 0;
    my $tick_next = $self->tick_period ? ( time() + $self->tick_period ) : 0;
    my $conn_class = $self->connection_class || 'WebSocket::Connection';
    $self->_load_class( $conn_class ) || return( $self->pass_error );

    my $accept_cb  = $self->on_accept || sub{};
    my $connect_cb = $self->on_connect || sub{};
    my $tick_cb    = $self->on_tick || sub{};
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
                unless( $client )
                {
                    warn( "Error accepting connection from client: $!" ) if( $self->_warnings_is_enabled() );
                    next;
                }
                # NOTE: Connection
                
                my $conn;
                if( defined( $accept_cb ) && ref( $accept_cb ) eq 'CODE' )
                {
                    try
                    {
                        $conn = $accept_cb->({
                            socket      => $client,
                            server      => $self,
                            subprotocol => $self->subprotocol,
                        });
                    }
                    catch( $e )
                    {
                        return( $self->error( "Error calling the accept callback: $e" ) );
                    }
                }
                
                unless( $self->_is_object( $conn ) && $self->_can( $conn => [qw( error is_ready new recv send )] ) )
                {
                    $conn = $conn_class->new(
                        socket      => $client,
                        server      => $self,
                        subprotocol => $self->subprotocol,
                        debug       => $self->debug,
                    );
                }
                $self->{conns}->{ $client } = { conn => $conn, lastrecv => time() };
                $self->{select_readable}->add( $client );
                
                try
                {
                    my $rv = $connect_cb->( $self, $conn );
                    # The callback returned a defined, but false value, so we terminate the connection
                    if( defined( $rv ) && !$rv )
                    {
                        $self->{select_readable}->remove( $fh );
                        CORE::delete( $self->{conns}->{ $client } );
                        $client->shutdown(SHUT_RDWR) || do
                        {
                            warn( "Error closing client socket after being refused by connect callback: $!" ) if( $self->_warnings_is_enabled() );
                        };
                        close( $fh );
                    }
                }
                catch( $e )
                {
                    return( $self->error( "Error calling the connect callback: $e" ) );
                }
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
                    $self->{select_readable}->remove( $fh );
                    CORE::delete( $self->{conns}->{ $fh } );
                    $fh->shutdown(SHUT_RDWR) || do
                    {
                        warn( "Error closing client socket after being refused by connect callback: $!" ) if( $self->_warnings_is_enabled() );
                    };
                    close( $fh );
                }
            }
            else
            {
                warn( "Filehandle $fh became readable, but no handler took responsibility for it; removing it\n" ) if( $self->_warnings_is_enabled() );
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
                warn( "Filehandle $fh became writable, but no handler took responsibility for it; removing it\n" ) if( $self->_warnings_is_enabled() );
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
            try
            {
                $tick_cb->( $self );
            }
            catch( $e )
            {
                return( $self->error( "Error calling the tick callback: $e" ) );
            }
            
            $tick_next += $self->tick_period;
        }
    }
    return( $self );
}

sub stop { return( shift->shutdown( @_ ) ); }

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
    my $args = $self->_get_args_as_array( @_ );
    return( $self->error( "watch_${type} expects an even number of arguments after the type" ) ) if( @$args % 2 );
    for( my $i = 0; $i < @$args; $i += 2 )
    {
        my( $fh, $cb ) = ( $args->[ $i ], $args->[ $i + 1 ] );
        return( $self->error( "watch_${type} expects the second value of each pair to be a code reference, but element $i was not" ) ) if( ref( $cb ) ne 'CODE' );
        if( $self->{ "watch_${type}" }->{ $fh } )
        {
            warn( "watch_${type} was given a filehandle at index $i which is already being watched; ignoring!" ) if( $self->_warnings_is_enabled() );
            next;
        }
        $self->{ "select_${type}" }->add( $fh );
        $self->{ "watch_${type}" } = {} unless( ref( $self->{ "watch_${type}" } ) eq 'HASH' );
        $self->{ "watch_${type}" }->{ $fh } = { fh => $fh, cb => $cb };
    }
    return( $self );
}

1;
# NOTE: POD
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
        connection_class => 'My::Connection',
        port => 8080,
        on_connect => sub
        {
            my( $serv, $conn ) = @_;
            # Set the code that will issue pong reply to ping queries from the client
            $conn->do_pong(sub
            {
                # WebSocket::Connection and a scalar of bytes received
                my( $c, $bytes ) = @_;
                # This is the default behaviour
                return( $c->pong( $bytes ) );
            });
            
            # See WebSocket::Connection for more information on the followings:
            $conn->on(
                handshake => sub
                {
                    my( $conn, $handshake ) = @_;
                    print( "Connection from ip '", $conn->ip, "' on port '", $conn->port, "'\n" );
                    print( "Query string: '", $handshake->request->uri->query, "'\n" );
                    print( "Origin is: '", $handshake->request->origin, "', ", ( $handshake->request->origin eq $origin ? '' : 'not ' ), "ok\n" );
                    # $conn->disconnect() unless( $handshake->request->origin eq $origin );
                },
                ping => \&on_ping,
                pong => \&on_pong,
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

    v0.2.0

=head1 DESCRIPTION

This is a server class for the WebSocket protocol.

=head1 CONSTRUCTOR

=head2 new

Instantiate a new L<WebSocket> server object. This takes the following options:

=over 4

=item C<extensions>

Optional. One or more extension enabled for this server. For example C<permessage-deflate> to enable message compression.

You can set this to either a string or a L<WebSocket::Extension> object if you want, for example to set the extension parameters.

See L<rfc6455 section 9.1|https://datatracker.ietf.org/doc/html/rfc6455#section-9.1> for more information on extension.

Seel also L</compression_threshold>.

=item C<connection_class>

This is optional and defaults to C<WebSocket::Connection>. You can use this to set an alternative class to be used to handle incoming connections.

See L</connection_class> for more details.

=item C<listen>

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

=item C<on_connect>

A code reference that will be triggered upon connection from client.

It will be passed the the server object and the connection object (by default L<WebSocket::Connection>, but this can be configured with C<connection_class>).

See L</on_connect> for more information.

=item C<on_shutdown>

A code reference that will be triggered upon termination of the connection.

See L</on_shutdown> for more information.

=item C<on_tick>

A code reference that will be triggered for every tick.

See L</on_tick> for more information.

=item C<port>

The port number on which to connect.

=item C<silence_max>

The maximum value for ping frequency.

=item C<tick_period>

Frequency for the tick.

=item C<version>

The version supported. Defaults to C<draft-ietf-hybi-17> which means version C<13> (the latest as of 2021-09-24)

See also L</version> to change this afterward.

=item C<watch_readable>

An array reference of filehandle and subroutine callback as code reference. Each callback will be passed the L<WebSocket::Server> object and the socket filehandle.

The callback is called when the filehandle provided becomes readable.

=item C<watch_writable>

An array reference of filehandle and subroutine callback as code reference. Each callback will be passed the L<WebSocket::Server> object and the socket filehandle.

The callback is called when the filehandle provided becomes writable.

=back

If there are any issue with the instantiation, it will return C<undef> and set an error L<WebSocket::Exception> that can be retrieved with the L<error|Module::Generic/error> method inherited from L<Module::Generic>

=head1 METHODS

=head2 compression_threshold

Inherited from L<WebSocket>

Set or get the threshold in bytes above which the ut8 or binary messages will be compressed if the client and the server support compression and it is activated as an extension.

=head2 connection_class

Sets or gets a class name to be used to handle incoming connections. This defaults to C<WebSocket::Connection>

This class name will be loaded in L</start> and if any error occurs upon loading, L</start> will set an L<error|Module::Generic/error> and return C<undef>

The class specified will be instantiated with the following parameters:

=over 4

=item * C<debug>

An integer representing the debug level enabled for this object.

=item * C<server>

The current server object.

=item * C<socket>

The client socket accepted. This is an L<IO::Socket> object.

=item * C<subprotocol>

An array of protocols as set with L</subprotocol>

=back

=head2 connections

Returns the client connections currently active.

In list context, or if the C<legacy> is turned on, this returns a regular array:

    for( $server->connections )
    {
        print( "Connection from ip '", $_->ip, "' on port '", $_->port, "'\n" );
    }

In any other context, including object context, this returns a L<Module::Generic::Array>, such as:

    $server->connections->for(sub
    {
        my $conn = shift( @_ );
        print( "Connection from ip '", $conn->ip, "' on port '", $conn->port, "'\n" );
    });

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

=head2 legacy

Set or get the boolean value whether the method L</connections> use the legacy pattern and returns a list of current connection objects, or if false, it returns an L<array object|Module::Generic::Array> instead. This defaults to false.

=head2 listen

Get the L<IO::Socket> (or any of its inheriting classes such as L<IO::Socket::INET> or L<IO::Socket::SSL>) server socket object.

This value is set automatically upon calling L</start>, or it can also be provided upon server object instantiation. See L</new> option parameters.

=head2 on

Provided with an hash or hash reference of event name and code reference pairs and this will set those event handlers.

Possible event names are: C<accept>, C<connect>, C<shutdown>, C<tick>.

See below their corresponding method for more details.

See also L<WebSocket::Connection> for event handlers that can be set when a connection has been established.

It returns the current object.

=head2 on_accept

Set or get the code reference for the event handler that is triggered afer a new client connection has been accepted. 

The handler will be passed an hash reference containing the following properties:

=over 4

=item * C<server>

The current server object.

=item * C<socket>

The client socket accepted. This is an L<IO::Socket> object.

=item * C<subprotocol>

An array of protocols as set with L</subprotocol>

=back

It expects a class object in returns that supports the same methods as in L<WebSocket::Connection>, and at the very least C<error>, C<is_ready>, C<new>, C<recv> and C<send>. If the object returned does not, then you should expect some errors occurring.

If nothing is returned, it will use the class specified with L</connection_class> instead.

=head2 on_connect

Set or get the code reference for the event handler that is triggered when there is a new client connection, and after the connection has been established.

At this stage, no handshake has happened yet. This is just the server receiving a connection,

The handler is passed the server object and the connection object.

    use curry;
    $server->on_connect(sub
    {
        my( $s, $conn ) = @_;
        print( "Connection received from ip '", $conn->ip, "'\n" );
        $conn->do_pong( \&pong );
        $conn->max_recv_size(65536);
        $conn->max_send_size(65536);
        $conn->nodelay(1);
        # set handler for each event
        # See WebSocket::Connection for details on the arguments provided
        # You can also check out the example given in the symopsis
        $conn->on(
            handshake   => $self->curry::onconnect,
            ready       => $self->curry::onready,
            origin      => $self->curry::onorigin,
            utf8        => $self->curry::onmessage,
            binary      => $self->curry::onbinary,
            ping        => $self->curry::onping,
            pong        => $self->curry::onpong,
            disconnect  => $self->curry::onclose,
        );
    });

If the connect handler returns a defined, but false value, such as an empty string or C<0>, this will have L<WebSocket::Server> close the client connection that was just L<accepted|IO::Socket/accept>

The same could also be achieved by the handler like so:

    use Net::IP;
    my $banned = [qw( 192.168.2.0/24 )];
    $server->on_connect(sub
    {
        my( $s, $conn ) = @_;
        my $ip = Net::IP->new( $conn->ip );
        my $is_banned = grep( $ip->overlaps( Net::IP->new( $_ ) ) == $Net::IP::IP_A_IN_B_OVERLAP, @$banned );
        return(0) if( $is_banned );
        # or, alternatively:
        # if( $is_banned )
        # {
        #     # This will shutdown the TCP connection and close the filehandle of the socket
        #     $conn->disconnect;
        #     return;
        # }
        # Then, set the handlers
        $conn->on(
            handshake   => $self->curry::onconnect,
            ready       => $self->curry::onready,
            origin      => $self->curry::onorigin,
            utf8        => $self->curry::onmessage,
            binary      => $self->curry::onbinary,
            ping        => $self->curry::onping,
            disconnect  => $self->curry::onclose,
        );
    });

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will raise a warning if warnings are enabled, and this will set an L<error|Module::Generic/error> and returns C<undef> or an empty list depending on the context.

=head2 on_shutdown

Set or get the code reference for the event handler that is triggered B<before> calling L</disconnect> on every connected client and before the server is shutting down.

The callback is provided this server object as its sole argument.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will raise a warning if warnings are enabled.

=head2 on_tick

Set or get the code reference for the event handler that is triggered for every tick, if enabled by setting L</tick_period> to a true value.

The handler is passed this server object.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will raise a warning if warnings are enabled.

=head2 port

Sets or gets the port on which this server is listening to.

=head2 shutdown

Shuts down the server connection, calls the event handler L</on_shutdown>, and calls disconnect on each active client connection passing them the code L<1001|WebSocket/WS_GONE>

It returns the current server object.

=head2 silence_checkinterval

Sets or gets the interval in seconds. This is used to set the frequency of pings and also contribute to set the timeout.

=head2 silence_max

=head2 socket

This is an alias for L</listen>. It returns the L<server socket|IO::Socket> object.

=head2 start

Starts the server.

If a socket object has already been initiated and provided with the L</new> option I<listen>, then it will be used, otherwise, it will instantiate a new L<IO::Socket::INET> connection. If a I<port> option was provided in L</new>, it will be used, otherwise it will be auto allocated and the port assigned can then be retrieved using the L</port> method.

For every client connection received, it will call the accept callback, if specified, providing it the C<server>, C<socket>, C<subprotocol> values and expect an object back.

If the accept callback dies, this will be caught and this method C<start> will set an L<error|Module::Generic/error> accordingly and return C<undef>

If no connection object has been provided by the accept callback, it will instantiate a new connection object, using a class name specified with L</connection_class> or by default L<WebSocket::Connection> and call the L</on_connect> event handler, passing it the server object and the connection object.

This connection class name will be loaded and if any error occurs upon loading, this will set an L<error|Module::Generic/error> and return C<undef>

The class specified will be instantiated with the following parameters:

=over 4

=item * C<debug>

An integer representing the debug level enabled for this object.

=item * C<server>

The current server object.

=item * C<socket>

The client socket accepted. This is an L<IO::Socket> object.

=item * C<subprotocol>

An array of protocols as set with L</subprotocol>

=back

If I<tick_period> option in L</new> has been set, this will trigger the L</on_tick> event handler at the I<tick_period> interval.

=head2 stop

This just an alias for L</shutdown>

=head2 subprotocol

Set or get an array object of WebSocket protocols. This array object will be passed to each new L<WebSocket::Connection> object upon each connection received.

Returns a L<Module::Generic::Array> object.

See L<rfc6455 for more information|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

=head2 tick_period

Set or get the tick interval period.

=head2 unwatch_readable

This takes one or more filehandle, and removes them from being watched.

It returns the current server object.

=head2 unwatch_writable

This takes one or more filehandle, and removes them from being watched.

It returns the current server object.

=head2 version

The version supported. Defaults to C<draft-ietf-hybi-17> which means version C<13> (the latest as of 2021-09-24)

See L<rfc6455 section 4.4 for more information|https://datatracker.ietf.org/doc/html/rfc6455#section-4.4>

Returns an array of L<WebSocket::Version> objects, each stringifies to its numeric value.

=head2 versions

Set or get the list of supported protocol versions.

It can take inteer sucha s C<13>, which is the latest WebSocket rfc6455 protocol version, or one or more L<WebSocket::Version> objects.

=head2 watch_readable

This takes a list or an array reference of filehandle and subroutine callback as code reference. Each callback will be passed the L<WebSocket::Server> object and the socket filehandle.

The callback is called when the filehandle provided becomes readable.

It returns the current server object.

=head2 watch_writable

This takes a list or an array reference of filehandle and subroutine callback as code reference. Each callback will be passed the L<WebSocket::Server> object and the socket filehandle.

The callback is called when the filehandle provided becomes writable.

It returns the current server object.

=head2 watched_readable

    my $code = $ws->watched_readable( $fh );
    my( $fh1, $code1, $fh2, $code2 ) = $ws->watched_readable;
    my @all = $ws->watched_readable;

If a file handle is provided as a unique argument, it returns the corresponding callback, if any.

Otherwise, if no argument is provided, it returns a list of file handle and their calback.

=head2 watched_writable

    my $code = $ws->watched_writable( $fh );
    my( $fh1, $code1, $fh2, $code2 ) = $ws->watched_writable;
    my @all = $ws->watched_writable;

If a file handle is provided as a unique argument, it returns the corresponding callback, if any.

Otherwise, if no argument is provided, it returns a list of file handle and their calback.

=head1 CREDITS

Graham Ollis for L<AnyEvent::WebSocket::Client>, Eric Wastl for L<Net::WebSocket::Server>, Vyacheslav Tikhanovsky aka VTI for L<Protocol::WebSocket>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Client>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
