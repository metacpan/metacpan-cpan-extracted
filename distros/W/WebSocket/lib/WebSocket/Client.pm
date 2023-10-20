##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Client.pm
## Version v0.1.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/14
## Modified 2023/04/21
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Client;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use vars qw( $VERSION );
    # Import constants
    use WebSocket qw( :ws );
    use parent qw( WebSocket );
    use Encode ();
    use IO::Select;
    use IO::Socket qw( SHUT_RDWR );
    use IO::Socket::INET;
    use Nice::Try;
    use POSIX ();
    use Socket qw( SOL_SOCKET SO_REUSEPORT );
    use WebSocket::Handshake::Client;
    use WebSocket::Frame;
    use URI::ws;
    our $VERSION = 'v0.1.1';
};

sub init
{
    my $self = shift( @_ );
    my $uri;
    # Get the first argument as the uri to connect to if it is not an hash reference and the number of arguments is odd
    # e.g. $class->new( 'wss://localhost' );
    # e.g. $class->new( 'wss://localhost', { k1 => v1, k2 => v2 } );
    # e.g. $class->new( 'wss://localhost', k1 => v1, k2 => v2 );
    # e.g. $class->new( uri => 'wss://localhost', k1 => v1, k2 => v2 );
    # e.g. $class->new({ uri => 'wss://localhost', k1 => v1, k2 => v2 });
    if( @_ && 
        ref( $_[0] ) ne 'HASH' && 
        (
            ( @_ == 2 && ref( $_[1] ) eq 'HASH' ) ||
            ( @_ % 2 )
        ) )
    {
        $uri = shift( @_ );
    }
    $self->{cookie}         = undef unless( defined( $self->{cookie} ) );
    $self->{do_pong}        = \&pong unless( defined( $self->{do_pong} ) );
    $self->{ip}             = undef unless( defined( $self->{ip} ) );
    $self->{max_fragments_amount} = undef unless( defined( $self->{max_fragments_amount} ) );
    $self->{max_payload_size} = undef unless( defined( $self->{max_payload_size} ) );
    $self->{on_binary}      = sub{} unless( defined( $self->{on_binary} ) );
    $self->{on_connect}     = sub{} unless( defined( $self->{on_connect} ) );
    $self->{on_disconnect}  = sub{} unless( defined( $self->{on_disconnect} ) );
    $self->{on_error}       = sub{} unless( defined( $self->{on_error} ) );
    $self->{on_handshake}   = sub{1} unless( defined( $self->{on_handshake} ) );
    $self->{on_ping}        = sub{} unless( defined( $self->{on_ping} ) );
    $self->{on_pong}        = sub{} unless( defined( $self->{on_pong} ) );
    $self->{on_recv}        = sub{} unless( defined( $self->{on_recv} ) );
    $self->{on_send}        = sub{} unless( defined( $self->{on_send} ) );
    $self->{on_utf8}        = sub{} unless( defined( $self->{on_utf8} ) );
    $self->{origin}         = undef unless( defined( $self->{origin} ) );
    $self->{socket}         = undef unless( defined( $self->{socket} ) );
    $self->{subprotocol}    = [] unless( defined( $self->{subprotocol} ) );
    $self->{timeout}        = undef unless( defined( $self->{timeout} ) );
    $self->{uri}            = $uri unless( defined( $self->{uri} ) );
    # e.g. draft-ietf-hybi-17
    # Default to empty string prevent Module::Generic from setting this to the module version
    $self->{version}        = '' unless( length( $self->{version} // '' ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{disconnecting}  = 0;
    $self->{disconnected}   = 0;
    $uri = $self->uri || return( $self->error( "No websocket uri was provided to connect to." ) );
    try
    {
        my $ref = { uri => $uri, debug => $self->debug };
        $ref->{version} = $self->version if( $self->version );
        my $headers = [];
        # Only those 2 headers are recognised, on top of the ones dedicated for WebSocket
        push( @$headers, Cookie => $self->cookie->scalar ) if( $self->cookie->defined && $self->cookie->length );
        # push( @$headers, Origin => $self->{origin} ) if( defined( $self->{origin} ) && length( $self->{origin} ) );
        my $req_ref =
        {
        debug   => $self->debug,
        headers => $headers,
        uri     => $uri,
        };
        $req_ref->{origin} = $self->origin if( $self->origin->defined && $self->origin->length );
        $ref->{request} = WebSocket::Request->new( %$req_ref ) ||
            return( $self->pass_error( WebSocket::Request->error ) );
        if( $self->subprotocol->length )
        {
            $ref->{request}->subprotocol( $self->subprotocol );
        }
        $self->{handshake} = WebSocket::Handshake::Client->new( %$ref ) ||
            return( $self->pass_error( WebSocket::Handshake::Client->error ) );
    }
    catch( $e )
    {
        return( $self->error( "Unable to instantiate a WebSocket::Handshake::Client object: $e" ) );
    }
    
    my $params = { debug => $self->debug };
    $params->{max_fragments_amount} = $self->{frame_max_fragments} if( defined( $self->{frame_max_fragments} ) && length( $self->{frame_max_fragments} ) );
    $params->{max_payload_size} = $self->{max_payload_size} if( defined( $self->{max_payload_size} ) && length( $self->{max_payload_size} ) );
    $params->{version} = $self->version if( $self->version );
    $self->{frame_buffer} = WebSocket::Frame->new( %$params ) || 
        return( $self->pass_error( WebSocket::Frame->error ) );
    return( $self );
}

sub connect
{
    my $self = shift( @_ );
    my $uri  = $self->uri || return( $self->error( "No uri is set to connect to websocket server." ) );
    # $cv->begin;
    my $host = $uri->host;
    my $port = $uri->port
        ? $uri->port
        : $uri->scheme eq 'wss'
            ? 443 : 80;
    my $use_ssl = $uri->scheme eq 'wss' ? 1 : 0;
    my $sock;
    if( $use_ssl )
    {
        $self->_load_class( 'IO::Socket::SSL' ) ||
            return( $self->pass_error );
        $sock = IO::Socket::SSL->new(
            PeerHost => $host,
            PeerPort => $port,
            Proto => 'tcp',
        ) || return( $self->error( "Failed to connect using ssl to remote host '$host' on port '$port': $!" ) );
    }
    else
    {
        $sock = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            Proto => 'tcp',
        ) || return( $self->error( "Failed to connect to remote host '$host' on port '$port': $!" ) );
    }
    $self->socket( $sock );
    $self->ip( $sock->sockhost );
    $self->{select_readable} = IO::Select->new;
    $self->{select_writable} = IO::Select->new;

    $self->{select_readable}->add( $sock );

#     $self->{conns} = {};
#     my $silence_nextcheck = $self->silence_max ? ( time() + $self->silence_checkinterval ) : 0;
#     my $tick_next = $self->tick_period ? ( time() + $self->tick_period ) : 0;

    my $connect_cb = $self->on_connect || sub{};
    try
    {
        $connect_cb->( $self );
    }
    catch( $e )
    {
        return( $self->error( "Connect callback triggered an error: $e" ) );
    }
#     my $tick_cb    = $self->on_tick || sub{};
    my $hs = $self->handshake;
    my $handshake_data;
    $handshake_data = $hs->as_string || do
    {
        $self->disconnect( WS_INTERNAL_SERVER_ERROR );
        return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => $hs->error->message }) );
    };
    my $len = $sock->syswrite( $handshake_data );
    if( !defined( $len ) )
    {
        $self->shutdown;
        return( $self->error({ code => WS_GONE, message => "Connection closed before the handshake could be initiated: $!" }) );
    }
    elsif( !$len )
    {
        $self->shutdown;
        return( $self->error({ code => WS_PROTOCOL_ERROR, message => "Unable to send handshake to remote server: $!" }) );
    }
    my $send_cb = $self->on_send || sub{};
    try
    {
        $send_cb->( $self, $handshake_data );
    }
    catch( $e )
    {
        warn( "An error occurred while trying to call the send callback: $e" ) if( $self->_warnings_is_enabled() );
    }
    
    # Listen for server response and further handshake exchanges
    $self->listen(sub
    {
        return( !$self->disconnecting && !$hs->is_done );
    });
    
    $self->connected(1);

    # Now start our listener
    # If there is threads support, we use it
    my $ex_file = $self->new_tempfile({ suffix => '.txt', unlink => 1, use_file_map => 1 });
    $ex_file->mmap( my $result );
    # Block signal for fork
    my $sigset = POSIX::SigSet->new( POSIX::SIGINT );
    POSIX::sigprocmask( POSIX::SIG_BLOCK, $sigset ) || 
        return( $self->error( "Cannot block SIGINT for fork: $!" ) );
    
    # local $SIG{CHLD} = 'IGNORE';
    local $SIG{CHLD} = sub
    {
        while( ( my $child = waitpid( -1, POSIX::WNOHANG ) ) > 0 )
        {
            my $object = Storable::thaw( $result );
            if( $object )
            {
                if( ref( $object ) eq 'SCALAR' && $$object == 1 )
                {
                }
                elsif( ref( $object ) && $self->_is_a( $object => 'WebSocket::Exception' ) )
                {
                    warn( $object->error );
                    if( $object->code && $object->message )
                    {
                        $self->disconnect( $object->code, $object->message );
                    }
                    elsif( $object->code )
                    {
                        $self->disconnect( $object->code );
                    }
                    $self->shutdown unless( $self->disconnected );
                    return( $self->pass_error( $object ) );
                }
                else
                {
                    warn( "Fork child $child returned '$object', but I do not know what to do with it.\n" );
                }
            }
            else
            {
            }
        }
    };
    
    my $child = fork();
    # Parent
    if( $child )
    {
        POSIX::sigprocmask( POSIX::SIG_UNBLOCK, $sigset ) || 
            return( $self->error( "Cannot unblock SIGINT for fork: $!" ) );
    }
    # Child
    elsif( $child == 0 )
    {
        my $rv = $self->listen(sub
        {
            return( !$self->disconnecting );
        });
        if( !defined( $rv ) )
        {
            my $object = $self->error;
            $result = Storable::freeze( $object );
        }
        else
        {
            # We do not need to return our full object, so instead we just return \1 to say we are ok
            # It needs to be a reference for Storable to work
            $result = Storable::freeze( \1 );
        }
        exit(0);
    }
    else
    {
        my $err;
        if( $! == POSIX::EAGAIN() )
        {
            $err = "fork cannot allocate sufficient memory to copy the parent's page tables and allocate a task structure for the child.";
        }
        elsif( $! == POSIX::ENOMEM() )
        {
            $err = "fork failed to allocate the necessary kernel structures because memory is tight.";
        }
        else
        {
            $err = "Unable to fork a new process to execute promised code: $!";
        }
        return( $self->error( $err ) );
    }
    return( $self );
}

sub connected { return( shift->_set_get_boolean( 'connected', @_ ) ); }

sub do_pong { return( shift->_set_get_code( 'do_pong', @_ ) ); }

sub listen
{
    my $self = shift( @_ );
    my $cond = @_ ? shift( @_ ) : sub{1};
    return( $self->error( "Callback provided is not an anonymous ubsroutine or a reference to a subroutine." ) ) if( ref( $cond ) ne 'CODE' );
    my $timeout = $self->timeout;
    my $sock    = $self->socket || return( $self->error( "The socket is gone!" ) );
    while( $sock->opened && $cond->() )
    {
        my( $ready_read, $ready_write, undef() ) = IO::Select->select(
            $self->{select_readable},
            $self->{select_writable},
            undef(),
            $timeout
        );
        foreach my $fh ( $ready_read ? @$ready_read : () )
        {
            my $rv = $self->recv();
            if( !defined( $rv ) )
            {
                $self->disconnect( $self->error->code, $self->error->message ) if( !$self->disconnecting && $self->error->code );
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
    }
    return( $self );
}

sub cookie { return( shift->_set_get_scalar_as_object( 'cookie', @_ ) ); }

# Ref: <https://datatracker.ietf.org/doc/html/rfc6455#section-5.5.1>
sub disconnect
{
    my( $self, $code, $reason ) = @_;
    return( $self ) if( $self->disconnecting );
    $self->disconnecting(1);
    
    my $disconnect_cb = $self->on_disconnect || sub{};
    try
    {
        $disconnect_cb->( $self, $code, $reason );
    }
    catch( $e )
    {
        warn( "Error calling disconnect callback: $e" ) if( $self->_warnings_is_enabled() );
    }

    my $data = '';
    if( defined( $code ) || defined( $reason ) )
    {
        $code ||= WS_OK;
        $reason = '' unless( defined( $reason ) );
        $data = pack( "na*", $code, $reason );
    }
    $self->send( close => $data ) if( $self->handshake->is_done );
    $self->connected(0);

    # Now we wait a reasonable amount of time until the client acknowledges and send us too a close confirmation according to rfc6455 section 5.1.1
    local $SIG{ALRM} = sub
    {
        $self->shutdown;
    };
    alarm(3);
    return( $self );
}

sub disconnected { return( shift->_set_get_boolean( 'disconnected', @_ ) ); }

sub disconnecting { return( shift->_set_get_boolean( 'disconnecting', @_ ) ); }

sub frame_buffer { return( shift->_set_get_object_without_init( 'frame_buffer', 'WebSocket::Frame', @_ ) ); }

sub handshake { return( shift->_set_get_object_without_init( 'handshake', 'WebSocket::Handshake::Client', @_ ) ); }

sub ip { return( shift->_set_get_scalar_as_object( 'ip', @_ ) ); }

sub max_fragments_amount { return( shift->_set_get_number( 'max_fragments_amount', @_ ) ); }

sub max_payload_size { return( shift->_set_get_number( 'max_payload_size', @_ ) ); }

sub on
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    while( my( $key, $value ) = each( %$opts ) )
    {
        my $method = $self->can( "on_${key}" );
        return( $self->error( "Invalid event '$key'" ) ) if( !defined( $method ) );
        return( $self->error( "Expected a code reference for event '$key', but got '", overload::StrVal( $value ), "'." ) ) if( ref( $value ) ne 'CODE' );
        $method->( $self, $value ) || return( $self->pass_error );
    }
    return( $self );
}

sub on_binary { return( shift->_set_get_code( 'on_binary', @_ ) ); }

sub on_connect { return( shift->_set_get_code( 'on_connect', @_ ) ); }

sub on_disconnect { return( shift->_set_get_code( 'on_disconnect', @_ ) ); }

sub on_error { return( shift->_set_get_code( 'on_error', @_ ) ); }

sub on_handshake { return( shift->_set_get_code( 'on_handshake', @_ ) ); }

sub on_ping { return( shift->_set_get_code( 'on_ping', @_ ) ); }

sub on_pong { return( shift->_set_get_code( 'on_pong', @_ ) ); }

sub on_recv { return( shift->_set_get_code( 'on_recv', @_ ) ); }

sub on_send { return( shift->_set_get_code( 'on_send', @_ ) ); }

sub on_utf8 { return( shift->_set_get_code( 'on_utf8', @_ ) ); }

sub origin { return( shift->_set_get_scalar_as_object( 'origin', @_ ) ); }

sub ping { return( shift->send( 'ping', @_ ) ); }

sub pong { return( shift->send( 'pong', @_ ) ); }

sub recv
{
    my $self = shift( @_ );
    # my( $buffer ) = @_;
    my $socket = $self->socket;

    my $hs    = $self->handshake;
    my $frame = $self->frame_buffer;
    
    my( $len, $buffer ) = ( 0, '' );
    if( !( $len = sysread( $socket, $buffer, 8192 ) ) )
    {
        if( !defined( $len ) )
        {
            warn( "Unable to read from socket, disconnecting: $!") if( $self->_warnings_is_enabled() );
            if( $self->handshake )
            {
                return( $self->error({ code => 500, message => 'Unable to read from socket' }) );
            }
            else
            {
                $self->disconnect( WS_INTERNAL_SERVER_ERROR, 'Unable to read from socket' );
                return( $self->error( "Unable to read from socket: $!" ) );
            }
        }
        else
        {
            if( $self->handshake )
            {
                return( $self->error({ code => 500, message => 'Reading from socket returned zero byte' }) );
            }
            else
            {
                $self->disconnect( WS_PROTOCOL_ERROR, 'Reading from socket returned zero byte' );
                return( $self->error( "Reading from socket returned zero byte: $!" ) );
            }
        }
    }

    # read remaining data
    $len = sysread( $socket, $buffer, 8192, length( $buffer ) ) while( $len >= 8192 );

    
    my $error_cb  = $self->on_error || sub{};
    my $on_recv   = $self->on_recv || sub{};
    my $msg_cb    = $self->on_utf8 || sub{};
    my $binary_cb = $self->on_binary || sub{};
    my $ping_cb   = $self->on_ping || sub{};
    my $pong_cb   = $self->on_pong || sub{};
    my $do_pong   = $self->do_pong || sub{};
    if( $hs && !$hs->is_done )
    {
        my $rv = $hs->parse( $buffer );
        if( !defined( $rv ) )
        {
            try
            {
                $error_cb->( $self, $hs->error );
            }
            catch( $e )
            {
                warn( "Error calling the error callback: $e" ) if( $self->_warnings_is_enabled() );
                return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
            }
            return( $self );
        }
        elsif( $hs->is_done )
        {
            # Here subprotocol is an array ref
            if( $self->subprotocol->length )
            {
                # Here subprotocol is a scalar object
                my $proto = $self->handshake->response->subprotocol;
                if( $proto->length )
                {
                    my $found = 0;
                    my $ok_proto = $self->subprotocol->as_hash;
                    $proto->for(sub
                    {
                        my( $i, $p ) = @_;
                        return(1) unless( defined( $p ) && length( $p ) );
                        if( exists( $ok_proto->{ $p } ) )
                        {
                            $found++;
                            # Exit
                            return;
                        }
                    });
                
                    # unless( $self->subprotocol->has( $proto ) )
                    unless( $found )
                    {
                        return( $self->error({ code => WS_NOT_ACCEPTABLE, message => "Protocol mismatch. Supported client protocols are: '" . $self->subprotocol->join( "', '" )->scalar . "', but got '", $proto->join( "', '" )->scalar, "'." }) );
                    }
                }
                else
                {
                    return( $self->error({ code => WS_NOT_ACCEPTABLE, message => "Handshake did not return any protocol" }) );
                }
            }
    
            my $handshake_cb = $self->on_handshake || sub{1};
            try
            {
                $handshake_cb->( $self, $self->handshake ) || 
                    return( $self->error({ code => WS_NOT_ACCEPTABLE, message => "Handshake rejected" }) );
            }
            catch( $e )
            {
                warn( "Error calling the handshake callback: $e" ) if( $self->_warnings_is_enabled() );
                return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
            }
            return( $self );
        }
    }
    
    if( $hs->is_done )
    {
        $frame->append( $buffer );
        
        while( my $bytes = $frame->next )
        {
            if( !defined( $bytes ) )
            {
                return( $self->pass_error );
            }
            elsif( $frame->is_binary || $frame->is_text )
            {
                try
                {
                    $on_recv->( $frame, $bytes );
                }
                catch( $e )
                {
                    warn( "Error with callback \"on_recv\" to process incoming binary or text data: $e" ) if( $self->_warnings_is_enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }
            }
            
            if( $frame->is_binary )
            {
                try
                {
                    $binary_cb->( $self, $bytes );
                }
                catch( $e )
                {
                    warn( "Error with callback to process binary message: $e" ) if( $self->_warnings_is_enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }
            }
            elsif( $frame->is_text )
            {
                try
                {
                    $msg_cb->( $self, Encode::decode( 'UTF-8', $bytes ) );
                }
                catch( $e )
                {
                    warn( "Error with callback to process text message: $e" ) if( $self->_warnings_is_enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }
            }
            elsif( $frame->is_ping )
            {
                my $rv;
                try
                {
                    $rv = $ping_cb->( $self, $bytes );
                }
                catch( $e )
                {
                    warn( "Error with callback to process ping received from server: $e" ) if( $self->_warnings_is_enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }

                unless( defined( $rv ) && !$rv )
                {
                    # RFC says we should perform a pong as soon as possible and return whatever they were sent
                    try
                    {
                        $do_pong->( $self, $bytes );
                    }
                    catch( $e )
                    {
                        warn( "Error with callback to execute a pong to server in response to ping received: $e" ) if( $self->_warnings_is_enabled() );
                        return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                    }
                }
            }
            elsif( $frame->is_pong )
            {
                try
                {
                    $pong_cb->( $self, $bytes );
                }
                catch( $e )
                {
                    warn( "Error with callback to process pong received from the server: $e" ) if( $self->_warnings_is_enabled() );
                }
            }
            elsif( $frame->is_close )
            {
                # A reply to our own disconnection
                if( $self->disconnecting )
                {
                    $self->shutdown;
                }
                # We receive a disconnect notification. We reply back and shutdown
                else
                {
                    # We reply
                    if( length( "$bytes" ) )
                    {
                        my( $code, $reason ) = ( unpack( 'n', substr( $bytes, 0, 2, '' ) ), Encode::decode( 'UTF-8', $bytes ) );
                        $self->disconnect( $code );
                    }
                    else
                    {
                        $self->disconnect( WS_OK );
                    }
                    # And we disconnect
                    $self->shutdown;
                }
                return( $self );
            }
        }
    }
    return( $self );
}

sub send
{
    my $self = shift( @_ );
    my( $type, $buffer ) = @_;
    # For simplicity sake, if the user calls this method with one argument, 
    # this means it is a text message
    if( @_ == 1 && 
        defined( $type ) && 
        ( $type ne 'ping' || $type ne 'pong' ) )
    {
        ( $type, $buffer ) = ( 'text', shift( @_ ) );
    }
    else
    {
        ( $type, $buffer ) = @_;
    }
    return( $self->error( "Message of type \"$type\" is unsupported." ) ) if( !WebSocket::Frame->supported_types( $type ) );
    if( !$self->handshake->is_done )
    {
        warn( "Tried to send data before finishing handshake\n" ) if( $self->_warnings_is_enabled() );
        return(0);
    }
    
    my $frame;
    if( $self->_is_a( $buffer, 'WebSocket::Frame' ) )
    {
        $frame = $buffer;
    }
    else
    {
        my $params = 
        {
        masked  => 1,
        buffer  => $buffer,
        type    => $type,
        debug   => $self->debug,
        };
        $params->{max_payload_size} = $self->max_payload_size if( $self->max_payload_size );
        $params->{version} = $self->version if( $self->version );
        $frame = WebSocket::Frame->new( %$params );
    }
    my $send_cb = $self->on_send || sub{};
    my $bytes = $frame->to_bytes;
    try
    {
        $send_cb->( $self, $bytes );
    }
    catch( $e )
    {
        warn( "Error calling the send callback: $e" ) if( $self->_warnings_is_enabled() );
    }
    my $socket = $self->socket;
    return( $self->error( "No socket found to send data to!" ) ) if( !$socket );
    my $sent = $socket->send( $bytes );
    return( $self->pass_error( "Unable to send ", length( $bytes ), " bytes of data on socket: $!" ) ) if( !defined( $sent ) );
    warn( "I tried to send ", length( $bytes ), " but only actually sent $sent bytes.\n" ) if( length( $bytes ) != $sent );
    return( length( $bytes ) );
}

sub send_binary { return( shift->send( binary => @_ ) ); }

sub send_utf8 { return( shift->send( text => Encode::encode( 'UTF-8', shift( @_ ) ) ) ); }

sub shutdown
{
    my $self = shift( @_ );
    return( $self ) if( $self->disconnected );
    $self->socket->shutdown( SHUT_RDWR );
    $self->disconnected(1);
    return( $self );
}

sub socket { return( shift->_set_get_object_without_init( 'socket', 'IO::Socket', @_ ) ); }

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
        my $v = $self->_set_get_array_as_object( 'subprotocol', $ref ) || return( $self->pass_error );
        $self->handshake->request->subprotocol( $v ) if( $self->handshake );
    }
    return( $self->_set_get_array_as_object( 'subprotocol' ) );
}

sub timeout { return( shift->_set_get_number( 'timeout', @_ ) ); }

sub uri { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub version { return( shift->_set_get_object_without_init( 'version', 'WebSocket::Version', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Client - WebSocket Client

=head1 SYNOPSIS

    use WebSocket::Client;
    use Term::Prompt;
    my $uri = "ws://localhost:8080?csrf=token";
    my $ws;
    $ws = WebSocket::Client->new( $uri,
    {
        do_pong       => sub{ $ws->pong },
        on_binary     => \&on_binary,
        on_connect    => \&on_connect,
        on_disconnect => \&on_disconnect,
        on_error      => \&on_error,
        on_handshake  => \&on_handshake,
        on_ping       => \&on_ping,
        on_pong       => \&on_pong,
        on_recv       => \&on_recv,
        on_send       => \&on_send,
        on_utf8       => \&on_message,
        origin        => 'http://localhost',
        debug         => 3,
        version       => 13,
    }) || die( WebSocket::Client->error );
    $ws->connect() || die( $ws->error );

    $SIG{INT} = $SIG{TERM} = sub
    {
        my( $sig ) = @_;
        $ws->disconnect if( $ws );
        exit( $sig eq 'TERM' ? 0 : 1 );
    };
    
    while(1)
    {
        my $msg = prompt( 'x', "> ", 'type the message to send', '' );
        next unless( $msg =~ /\S+/ );
        $ws->send_utf8( $msg ) || die( $ws->error );
    }

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This is the WebSocket client class. It contains all the methods and api to connect to a remote WebSocket server and interact with it.

=head1 CONSTRUCTOR

=head2 new

The constructor takes an uri and the following options. If an uri is not provided as a first argument, it can be provided as a C<uri> parameter; see below:

=over 4

=item C<compression_threshold>

See L</compression_threshold>

=item C<cookie>

A C<Cookie> http field header value. It must be properly formatted.

=item C<do_pong>

The code reference used to issue a C<pong>. By default this is set to L</pong>

=item C<extensions>

Optional. One or more extension enabled for this client. For example C<permessage-deflate> to enable message compression.

You can set this to either a string or a L<WebSocket::Extension> object if you want, for example to set the extension parameters.

See L<rfc6455 section 9.1|https://datatracker.ietf.org/doc/html/rfc6455#section-9.1> for more information on extension.

Seel also L</compression_threshold>.

=item C<max_fragments_amount>

=item C<max_payload_size>

=item C<on_binary>

A code reference that will be triggered upon a binary message received from the server.

See L</on_binary> for more details.

=item C<on_connect>

A code reference that will be triggered upon successful connection to the remote WebSocket server, but before any handshake is performed.

See L</on_connect> for more details.

=item C<on_disconnect>

A code reference that will be triggered upon the closing of the connection with the server.

See L</on_disconnect> for more details.

=item C<on_error>

A code reference that will be triggered whenever an error is encountered upon parsing of the handshake.

See L</on_error> for more details.

=item C<on_handshake>

A code reference that will be triggered just before the handshake procedure is completed, but right after the handshake has been received from the server.

Be careful, the code reference B<must> return true upon success, or else, it will trigger a handshake failure.

=item C<on_ping>

A code reference that will be triggered when a C<ping> is received from the WebSocket server.

See L</on_ping> for more details. and L<Mozilla documentation on ping and pong|https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#Pings_and_Pongs_The_Heartbeat_of_WebSockets>

See also L</do_pong> to set the code reference to perform a C<pong>

=item C<on_pong>

A code reference that will be triggered when a C<pong> is received from the WebSocket server, most likely as a reply to our initial C<ping>.

See L</on_pong> for more details. and L<Mozilla documentation on ping and pong|https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#Pings_and_Pongs_The_Heartbeat_of_WebSockets>

=item C<on_recv>

A code reference that will be triggered whenever some text or binary payload data is received from the server.

See L</on_recv> for more details.

=item C<on_send>

A code reference that will be triggered whenever data is sent to the remote WebSocket server.

See L</on_send> for more details.

=item C<on_utf8>

A code reference that will be triggered whenever text message is sent to the remote WebSocket server.

See L</on_utf8> for more details.

=item C<origin>

The C<origin> of the request. See L<rfc6455 section on opening handshake|https://datatracker.ietf.org/doc/html/rfc6455#section-1.3>

=item C<subprotocol>

An array reference of protocols. They can be arbitrary identifiers and they are optionals.

See L<rfc6455 section on subprotocol|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

This can be changed later with L</subprotocol>

=item C<uri>

The uri for the remote WebSocket server.

=item C<version>

The version of the WebSocket protocol. For example: C<draft-ietf-hybi-17>

=back

=head1 METHODS

=head2 compression_threshold

Inherited from L<WebSocket>

Set or get the threshold in bytes above which the ut8 or binary messages will be compressed if the client and the server support compression and it is activated as an extension.

=head2 connect

Initiate the handshake with the server and return the current object.

Before returning, this method will fork a separate process to listen to incoming messages in the background, so as to be non-blocking and return control to the caller.

    my $client = WebSocket::Client->new( 'wss://chat.example.org' )->connect ||
        die( WebSocket::Client->error );
    # Listener process runs now in the background
    $client->send( 'Hello !' );

=head2 connected

Sets or gets the boolean value representing whether the client is currently connected to the remote WebSocket server.

=head2 cookie

Set or get the C<Cookie> header value.

Returns a L<scalar object|Module::Generic::Scalar>

=head2 disconnect

Provided with an optional code and an optional reason, and this will close the connection with the server, and return the current object.

=head2 disconnected

Set or get a boolean value representing the connection status to the remote server socket.

There are 2 status: C<disconnecting> and C<disconnected>. The former is set when the client has issued a disconnection message to the remote server and is waiting for the server to acknowledge it, as per the L<WebSocket protocol|https://datatracker.ietf.org/doc/html/rfc6455#page-36>, and the latter is set when the connection is effectively shut down.

=head2 disconnecting

Set or get the boolean value indicating the state of connection to the remote server socket.

This is set to a true value when the client has issued a disconnection notification to the server and is awaiting a response from the server, as per the L<rfc6455 protocol|https://datatracker.ietf.org/doc/html/rfc6455#page-36>

=head2 do_pong

Set or get the code reference used to issue a C<pong>. By default this is set to L</pong>

=head2 frame_buffer

Set or get the L<frame buffer|WebSocket::Frame> object.

=head2 handshake

Set or get the L<handshake object|WebSocket::Handshake::Client>

=head2 ip

Set or get the ip of the remote server. This is set once a L<connection|/connect> is established.

=head2 listen

This method is called by L</connect> to listen to incoming message from the server. It is actually called twice. Once during the handshake and once the handshake is completed, the client forks a separate process in which it calls this method to listen to incoming messages.

=head2 max_fragments_amount

Takes an integer and set or get the maximum fragments amount.

=head2 max_payload_size

Takes an integer and set or get the maximum payload size.

=head2 on

Provided with an array or array reference of event name and core reference pairs and this will set those event handlers.

It returns the current object.

=head2 on_binary

    $ws->on( binary => sub
    {
        my( $ws, $msg ) = @_;
        # Do something
    });

Event handler triggered when a binary message is received.

The current client object and the binary message are passed as argument to the event handler.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>)

=head2 on_connect

    $ws->on( connect => sub
    {
        my( $ws ) = @_;
        # Do something
    });

Event handler triggered when the connection with the server has been made and B<before> any handshake has been performed.

The current client object is passed as argument to the event handler.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will set an L<error|WebSocket::Exception> and return C<undef> or an empty list depending on the context.

=head2 on_disconnect

    $ws->on( disconnect => sub
    {
        my( $ws, $code, $reason ) = @_;
        # Do something
    });

Event handler triggered B<before> the connection with the server is closed.

The current client object, the code and optional reason are passed as argument to the event handler.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will raise a warning if warnings are enabled.

=head2 on_error

    $ws->on( error => sub
    {
        my( $ws, $error ) = @_;
        # Do something
        print( STDERR "Error received upon handshake: $error\n" );
    });

Event handler triggered whenever an error occurs upon parsing of the handshake.

The current client object and the L<error object|WebSocket::Exception> are passed as argument to the event handler.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will raise a warning if warnings are enabled.

=head2 on_handshake

    $ws->on( handshake => sub
    {
        my( $ws ) = @_;
        # Do something
    });

Event handler triggered just before the handshake sequence is completed, but right after the handshake has been received from the server.

Be careful that this must return a true value, or else, it will fail the handshake.

The current client object is passed as argument to the event handler.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will raise a warning if warnings are enabled.

=head2 on_ping

    $ws->on( ping => sub
    {
        my( $ws, $msg ) = @_;
        # Do something
        print( STDOUT "Received a ping from the server: $msg\n" );
    });

A code reference that will be triggered when a C<ping> is received from the WebSocket server and right before a C<pong> is sent back.

The current client object, and the possible message, if any, are passed as arguments to the event handler.

If the callback returns a defined, but false value, no C<pong> will be issued in reply. A defined but false value could be an empty string or C<0>. This is designed in case when you do not waant to reply to the server's ping and thus inform it the client is still there.

It would probably be best to simply disconnect, but anyhow the feature is there.

See L<Mozilla documentation on ping and pong|https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#Pings_and_Pongs_The_Heartbeat_of_WebSockets>

See also L</do_pong> to set the code reference to perform a C<pong> in response.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will set an L<error|WebSocket::Exception> and return C<undef> or an empty list depending on the context.

=head2 on_pong

    $ws->on( pong => sub
    {
        my( $ws, $msg ) = @_;
        # Do something
        print( STDOUT "Received a pong from the server: $msg\n" );
    });

A code reference that will be triggered when a C<pong> is received from the WebSocket server, most likely as a reply to our initial C<ping>.

The event handler is then passed the current client object, and the optional message received in the original ping, if any.

See L<Mozilla documentation on ping and pong|https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#Pings_and_Pongs_The_Heartbeat_of_WebSockets>

See L<rfc6455 for more on this|https://datatracker.ietf.org/doc/html/rfc6455#section-5.5.2>

Note that this handler is different from L</do_pong>, which is used to issue a C<pong> back to the server in response to a C<ping> received.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will set an L<error|WebSocket::Exception> and return C<undef> or an empty list depending on the context.

=head2 on_recv

Event handler triggered whenever a binary or text payload is received from the server.

The current L<frame|WebSocket::Frame> object and the payload data are passed as arguments to the event handler.

    use JSON;
    $ws->on_recv(sub
    {
        my( $frame, $payload ) = @_;
        if( $frame->is_binary )
        {
            # do something
        }
        elsif( $frame->is_text )
        {
            # do something else
            my $hash = JSON::decode_json( $payload );
        }
    });

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will set an L<error|WebSocket::Exception> and return C<undef> or an empty list depending on the context.

=head2 on_send

    $ws->on( send => sub
    {
        my( $ws, $msg ) = @_;
        # Do something
        print( STDOUT "Message sent to the server: $msg\n" );
    });

Event handler triggered whenever a message is sent to the remote server.

The current client object and the message are passed as argument to the event handler.

This callback is triggered on two occasions:

=over 4

=item 1. upon connecting, B<after> the client has sent the handshake data to the server.

=item 2. upon sending data to the server.

=back

In either case, fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>), and if an error occurs, this method will raise a warning if warnings are enabled.

=head2 on_utf8

    $ws->on( utf8 => sub
    {
        my( $ws, $msg ) = @_;
        # Do something
        print( STDOUT "Message received from the server: $msg\n" );
    });

Event handler triggered whenever a text message is sent to the remote server.

The current client object and the message are passed as argument to the event handler.

Any fatal error occurring in the callback are caught using try-catch with (L<Nice::Try>)

=head2 origin

Set or get the origin of the request as a L<Module::Generic::Scalar> object.

=head2 ping

Send a ping to the WebSocket server and returns the value returned by L</send>. It passes L</send> whatever extra argument was provided.

=head2 pong

Send a pong to the WebSocket server and returns the value returned by L</send>. It passes L</send> whatever extra argument was provided.

=head2 recv

Will attempt to read data from the server socket and call all relevant event handlers. It returns the current object.

=head2 send

Sends data to the server socket and returns the current object. This will also trigger associated event handlers.

Returns the current object.

=head2 send_binary

Sends binary data to the server socket and returns the current object. This will also trigger associated event handlers.

Returns the current object.

=head2 send_utf8

Sends data to the server socket after having encoded them using L<Encode/encode> and returns the current object. This will also trigger associated event handlers.

Returns the current object.

=head2 start

Start listening for possible events on the server socket.

Returns the current object.

=head2 subprotocol

Set or get an array object of WebSocket protocols and set the WebSocket header C<Sec-WebSocket-Protocol>.

Returns a L<Module::Generic::Array> object.

See L<rfc6455 for more information|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

=head2 shutdown

Shut down the socket by sending a L<IO::Socket/shutdown> command and sets the L</disconnected> status to true.

Returns the current object.

=head2 socket

Set or get the remote server socket. This expects the object to be a L<IO::Socket> instance, or an inheriting package.

=head2 timeout

Set or get the timeout used when issuing messages to the remote server, such as C<close> and waiting for the server response.

=head2 uri

Returns the uri of the server uri.

See L<rfc6455 specification|https://datatracker.ietf.org/doc/html/rfc6455#section-3>

=head2 version

The WebSocket protocol version being used, such as C<draft-ietf-hybi-17>

See L<rfc6455 about suport for multiple versions|https://datatracker.ietf.org/doc/html/rfc6455#page-26>

=head1 CREDITS

Graham Ollis for L<AnyEvent::WebSocket::Client>, Eric Wastl for L<Net::WebSocket::Server>, Vyacheslav Tikhanovsky aka VTI for L<Protocol::WebSocket>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Server>, L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
