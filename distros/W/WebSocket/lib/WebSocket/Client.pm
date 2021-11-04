##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Client.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/14
## Modified 2021/09/14
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Client;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
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
    our $VERSION = 'v0.1.0';
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
    $self->{cookie}         = undef;
    $self->{ip}             = undef;
    $self->{max_fragments_amount} = undef;
    $self->{max_payload_size} = undef;
    $self->{on_binary}      = sub{};
    $self->{on_connect}     = sub{};
    $self->{on_disconnect}  = sub{},
    $self->{on_error}       = sub{};
    $self->{on_handshake}   = sub{1},
    $self->{on_ping}        = sub{};
    $self->{on_recv}        = sub{};
    $self->{on_send}        = sub{};
    $self->{on_utf8}        = sub{};
    $self->{origin}         = undef;
    $self->{socket}         = undef;
    $self->{subprotocol}    = [];
    $self->{timeout}        = undef;
    $self->{uri}            = $uri;
    # e.g. draft-ietf-hybi-17
    # Default to empty string prevent Module::Generic from setting this to the module version
    $self->{version}        = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{disconnecting}  = 0;
    $self->{disconnected}   = 0;
    $uri = $self->uri || return( $self->error( "No websocket uri was provided to connect to." ) );
    $self->message( 3, "Using uri '$uri' with path_query '", $uri->path_query, "'" );
    try
    {
        my $ref = { uri => $uri, debug => $self->debug };
        $ref->{version} = $self->version if( $self->version );
        my $headers = [];
        # Only those 2 headers are recognised, on top of the ones dedicated for WebSocket
        push( @$headers, Cookie => $self->cookie->scalar ) if( $self->cookie->defined && $self->cookie->length );
        # push( @$headers, Origin => $self->{origin} ) if( defined( $self->{origin} ) && length( $self->{origin} ) );
        $self->message( 3, "Setting WebSocket::Request->uri to '$uri'." );
        my $req_ref =
        {
        debug   => $self->debug,
        headers => $headers,
        uri     => $uri,
        };
        $self->message( 3, "Origin is set to '", $self->origin, "'." );
        $req_ref->{origin} = $self->origin if( $self->origin->defined && $self->origin->length );
        $ref->{request} = WebSocket::Request->new( %$req_ref ) ||
            return( $self->pass_error( WebSocket::Request->error ) );
        $self->message( 3, "Subprotocol contains '", $self->subprotocol->join( ',' ), "'." );
        if( $self->subprotocol->length )
        {
            $ref->{request}->subprotocol( $self->subprotocol );
            $self->message( 3, "In WebSocket::Request (", overload::StrVal( $ref->{request} ), "), version is '", $ref->{request}->version, "' and subprotocol is '", $ref->{request}->subprotocol->join( ',' )->scalar, "'." );
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
    $self->message( 3, "Trying to connect to remote host '$host' on port '$port'." );
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
    $self->message( 3, "Sending handshake -> ", $hs->as_string );
    my $handshake_data;
    $handshake_data = $hs->as_string || do
    {
        $self->message( 3, "Error getting handshake as string: ", $hs->error );
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
    $self->message( 3, "Pushed ", length( $handshake_data ), " bytes of handshake data to socket." );
    $self->message( 3, "Calling send callback." );
    my $send_cb = $self->on_send || sub{};
    try
    {
        $send_cb->( $self, $handshake_data );
    }
    catch( $e )
    {
        $self->message( 3, "An error occurred while trying to call the send callback: $e" );
        warning::warn( "An error occurred while trying to call the send callback: $e" ) if( warnings::enabled() );
    }
    $self->message( 3, "Done calling send callback." );
    
    # Listen for server response and further handshake exchanges
    $self->listen(sub
    {
        return( !$self->disconnecting && !$hs->is_done );
    });

    # Now start our listener
    # If there is threads support, we use it
    my $ex_file = Module::Generic::File->tempfile({ suffix => '.txt', unlink => 1, use_file_map => 1 });
    $ex_file->mmap( my $result );
    $self->message( 3, "Using fork to listen" );
    # Block signal for fork
    my $sigset = POSIX::SigSet->new( POSIX::SIGINT );
    POSIX::sigprocmask( POSIX::SIG_BLOCK, $sigset ) || 
        return( $self->error( "Cannot block SIGINT for fork: $!" ) );
    
    # local $SIG{CHLD} = 'IGNORE';
    local $SIG{CHLD} = sub
    {
        while( ( my $child = waitpid( -1, POSIX::WNOHANG ) ) > 0 )
        {
            $self->message( 3, "Listner child process ($child) has terminated." );
            $self->message( 3, "Exit value: ", ( $? >> 8 ) );
            $self->message( 3, "Signal: ", ( $? & 127 ) );
            $self->message( 3, "Has core dump? ", ( $? & 128 ) );
            my $object = Storable::thaw( $result );
            if( $object )
            {
                if( ref( $object ) eq 'SCALAR' && $$object == 1 )
                {
                    $self->message( 3, "All ok and our asynchronous listener exited normally." );
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
                    $self->message( 3, "Client done, connections closed." );
                    return( $self->pass_error( $object ) );
                }
                else
                {
                    $self->message( 3, "Fork child $child returned '$object', but I do not know what to do with it." );
                    warn( "Fork child $child returned '$object', but I do not know what to do with it.\n" );
                }
            }
            else
            {
                $self->message( 3, "No value returned from child listener. This is not normal." );
            }
        }
    };
    
    my $child = fork();
    # Parent
    if( $child )
    {
        $self->message( 3, "Parent: Forked child with pid '$child'." );
        POSIX::sigprocmask( POSIX::SIG_UNBLOCK, $sigset ) || 
            return( $self->error( "Cannot unblock SIGINT for fork: $!" ) );
        $self->message( 3, "Parent: Letting child run separately and return" );
    }
    # Child
    elsif( $child == 0 )
    {
        $self->message( 3, "Child: Listening with pid $$" );
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
        $self->message( 3, "Parent: Failed to fork to listen" );
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
        $self->message( 3, "Error forking occurred: $err" );
        return( $self->error( $err ) );
    }
    $self->message( 3, "Parent: We are connected and our listner is running in the background with pid $child, returning." );
    return( $self );
}

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
                $self->message( 3, "Error receiving data: ", $self->error );
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
                warnings::warn( "Filehandle $fh became writable, but no handler took responsibility for it; removing it\n" ) if( warnings::enabled() );
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
    $self->message( 3, "Disconnecting from server connection." );
    return( $self ) if( $self->disconnecting );
    $self->disconnecting(1);
    
    my $disconnect_cb = $self->on_disconnect || sub{};
    try
    {
        $disconnect_cb->( $self, $code, $reason );
    }
    catch( $e )
    {
        warnings::warn( "Error calling disconnect callback: $e" ) if( warnings::enabled() );
    }

    my $data = '';
    if( defined( $code ) || defined( $reason ) )
    {
        $code ||= WS_OK;
        $reason = '' unless( defined( $reason ) );
        $data = pack( "na*", $code, $reason );
    }
    $self->send( close => $data ) if( $self->handshake->is_done );

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

sub on_recv { return( shift->_set_get_code( 'on_recv', @_ ) ); }

sub on_send { return( shift->_set_get_code( 'on_send', @_ ) ); }

sub on_utf8 { return( shift->_set_get_code( 'on_utf8', @_ ) ); }

sub origin { return( shift->_set_get_scalar_as_object( 'origin', @_ ) ); }

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
            $self->message( 3, "Unable to read from socket, disconnecting: $!" );
            warnings::warn( "Unable to read from socket, disconnecting: $!") if( warnings::enabled() );
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
            $self->message( 3, "Reading from socket returned zero byte: $!" );
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

    $self->message( 3, "Received ", ( length( $buffer ) || 0 ), " bytes of data. Handshake done? ", ( $hs->is_done ? 'yes' : 'no' ) );
    
    my $error_cb  = $self->on_error || sub{};
    my $on_recv   = $self->on_recv || sub{};
    my $msg_cb    = $self->on_utf8 || sub{};
    my $binary_cb = $self->on_binary || sub{};
    my $ping_cb   = $self->on_ping || sub{};
    if( $hs && !$hs->is_done )
    {
        my $rv = $hs->parse( $buffer );
        if( !defined( $rv ) )
        {
            $self->message( 3, "Handshake encountered some problems -> ", $hs->error );
            try
            {
                $error_cb->( $self, $hs->error );
            }
            catch( $e )
            {
                warnings::warn( "Error calling the error callback: $e" ) if( warnings::enabled() );
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
                $self->message( 3, "Checking protocol '", $proto->join( "', " ), "'" );
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
                        $self->message( 3, "Unknown protocol '", $proto->join( "', '" )->scalar, "'" );
                        return( $self->error({ code => WS_NOT_ACCEPTABLE, message => "Protocol mismatch. Supported client protocols are: '" . $self->subprotocol->join( "', '" )->scalar . "', but got '", $proto->join( "', '" )->scalar, "'." }) );
                    }
                }
                else
                {
                    $self->message( 3, "Handshake did not return any protocol" );
                    return( $self->error({ code => WS_NOT_ACCEPTABLE, message => "Handshake did not return any protocol" }) );
                }
            }
    
            $self->message( 3, "Server handshake received ok, calling connect handler." );
            my $handshake_cb = $self->on_handshake || sub{1};
            try
            {
                $handshake_cb->( $self, $self->handshake ) || 
                    return( $self->error({ code => WS_NOT_ACCEPTABLE, message => "Handshake rejected" }) );
            }
            catch( $e )
            {
                warnings::warn( "Error calling the handshake callback: $e" ) if( warnings::enabled() );
                return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
            }
            return( $self );
        }
    }
    
    if( $hs->is_done )
    {
        $self->message( 3, "Appending buffer to frame object -> '$buffer'" );
        $frame->append( $buffer );
        
        while( my $bytes = $frame->next )
        {
            $self->message( 3, "Received frame with opcode value '", $frame->opcode, "' with paylod '$bytes'" );
            if( !defined( $bytes ) )
            {
                $self->message( 3, "WebSocket::Frame->next returned undef, we pass on the error" );
                return( $self->pass_error );
            }
            elsif( $frame->is_binary || $frame->is_text )
            {
                try
                {
                    $self->message( 3, "Calling the \"recv\" handler and pass it the frame object and ", CORE::length( $bytes ), " bytes of payload data." );
                    $on_recv->( $frame, $bytes );
                }
                catch( $e )
                {
                    warnings::warn( "Error with callback \"on_recv\" to process incoming binary or text data: $e" ) if( warnings::enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }
            }
            
            if( $frame->is_binary )
            {
                $self->message( 3, "Frame is of type binary" );
                try
                {
                    $binary_cb->( $self, $bytes );
                }
                catch( $e )
                {
                    warnings::warn( "Error with callback to process binary message: $e" ) if( warnings::enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }
            }
            elsif( $frame->is_text )
            {
                $self->message( 3, "Frame is of type text" );
                try
                {
                    $msg_cb->( $self, Encode::decode( 'UTF-8', $bytes ) );
                }
                catch( $e )
                {
                    warnings::warn( "Error with callback to process text message: $e" ) if( warnings::enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }
            }
            elsif( $frame->is_ping )
            {
                $self->message( 3, "Frame is of type ping" );
                try
                {
                    $ping_cb->( $self, $bytes );
                }
                catch( $e )
                {
                    warnings::warn( "Error with callback to process ping: $e" ) if( warnings::enabled() );
                    return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Internal error" }) );
                }
            }
            elsif( $frame->is_close )
            {
                $self->message( 3, "Frame is of type close" );
                # A reply to our own disconnection
                if( $self->disconnecting )
                {
                    $self->message( 3, "Receiving server reply to our disconnection." );
                    $self->shutdown;
                }
                # We receive a disconnect notification. We reply back and shutdown
                else
                {
                    $self->message( 3, "Received a close notification from server. Replying back and shutting down the connection." );
                    # We reply
                    if( length( "$bytes" ) )
                    {
                        my( $code, $reason ) = ( unpack( 'n', substr( $bytes, 0, 2, '' ) ), Encode::decode( 'UTF-8', $bytes ) );
                        $self->message( 3, "Frame from server is of type close with code '$code' and reason '$reason'" );
                        $self->disconnect( $code );
                    }
                    else
                    {
                        $self->message( 3, "Frame from server is of type close with no particular payload" );
                        $self->disconnect( WS_OK );
                    }
                    # And we disconnect
                    $self->shutdown;
                }
                return( $self );
            }
        }
    }
    $self->message( 3, "Nothing more to do. Returning." );
    return( $self );
}

sub send
{
    my $self = shift( @_ );
    my( $type, $buffer ) = @_;
    # For simplicity sake, if the user calls this method with one argument, 
    # this means it is a text message
    if( @_ == 1 )
    {
        ( $type, $buffer ) = ( 'text', shift( @_ ) );
    }
    else
    {
        ( $type, $buffer ) = @_;
    }
    $self->message( 3, "Sending ", length( $buffer ), " bytes of payload data of type '$type' and data -> '", $buffer, "'" );
    return( $self->error( "Message of type \"$type\" is unsupported." ) ) if( !WebSocket::Frame->supported_types( $type ) );
    if( !$self->handshake->is_done )
    {
        warnings::warn( "Tried to send data before finishing handshake\n" ) if( warnings::enabled() );
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
        $send_cb->( $bytes );
    }
    catch( $e )
    {
        warnings::warn( "Error calling the send callback: $e" ) if( warnings::enabled() );
    }
    $self->message( 3, "> Writing" );
    my $socket = $self->socket;
    return( $self->error( "No socket found to send data to!" ) ) if( !$socket );
    $self->message( 3, "Writing ", length( $bytes ), " bytes of data -> '$bytes'" );
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
        $self->message( 3, "Called with -> ", sub{ $self->dump( $ref ) } );
        my $v = $self->_set_get_array_as_object( 'subprotocol', $ref ) || return( $self->pass_error );
        $self->handshake->request->subprotocol( $v ) if( $self->handshake );
    }
    return( $self->_set_get_array_as_object( 'subprotocol' ) );
}

sub timeout { return( shift->_set_get_number( 'timeout', @_ ) ); }

sub uri { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub version { return( shift->_set_get_object_without_init( 'version', 'WebSocket::Version', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

WebSocket::Client - WebSocket Client

=head1 SYNOPSIS

    use WebSocket::Client;
    my $uri = "ws://localhost:8080?csrf=token";
    my $ws  = WebSocket::Client->new( $uri,
    {
        on_binary     => \&on_binary,
        on_connect    => \&on_connect,
        on_disconnect => \&on_disconnect,
        on_error      => \&on_error,
        on_utf8       => \&on_message,
        on_recv       => \&on_recv,
        on_send       => \&on_send,
        origin        => 'http://localhost',
        debug         => 3,
    }) || die( WebSocket::Client->error );
    $ws->start() || die( $ws->error );

    my $stdin = AnyEvent::Handle->new(
        fh      => \*STDIN,
        on_read => sub
        {
            my $handle = shift( @_ );
            my $buf = delete( $handle->{rbuf} );
            $ws->send_utf8( $buf );
        },
        on_eof => sub
        {
            $ws->disconnect;
        }
    );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is the WebSocket client class. It contains all the methods and api to connect to a remote WebSocket server and interact with it.

=head1 CONSTRUCTOR

=head2 new

The constructor takes an uri and the following options. If an uri is not provided as a first argument, it can be provided as a I<uri> parameter; see below:

=over 4

=item I<compression_threshold>

See L</compression_threshold>

=item I<cookie>

A C<Cookie> http field header value. It must be properly formatted.

=item I<extensions>

Optional. One or more extension enabled for this client. For example C<permessage-deflate> to enable message compression.

You can set this to either a string or a L<WebSocket::Extension> object if you want, for example to set the extension parameters.

See L<rfc6455 section 9.1|https://datatracker.ietf.org/doc/html/rfc6455#section-9.1> for more information on extension.

Seel also L</compression_threshold>.

=item I<max_fragments_amount>

=item I<max_payload_size>

=item I<on_binary>

A code reference that will be triggered upon a binary message received from the server.

See L</on_binary>

=item I<on_connect>

A code reference that will be triggered upon successful connection to the remote WebSocket server.

See L</on_connect>

=item I<on_disconnect>

A code reference that will be triggered upon the closing of the connection with the server.

See L</on_disconnect>

=item I<on_error>

A code reference that will be triggered whenever an error is encountered.

See L</on_error>

=item I<on_handshake>

A code reference that will be triggered just before the handshake procedure is completed.

Be careful, the code reference B<must> return true upon success, or else, it will trigger a handshake failure.

=item I<on_ping>

A code reference that will be triggered when a C<ping> is issued.

See L</on_ping>

=item I<on_recv>

A code reference that will be triggered whenever some text or binary payload data is received from the server.

=item I<on_send>

A code reference that will be triggered whenever data is sent to the remote WebSocket server.

See L</on_send>

=item I<on_utf8>

A code reference that will be triggered whenever text message is sent to the remote WebSocket server.

See L</on_utf8>

=item I<origin>

The C<origin> of the request. See L<rfc6455 section on opening handshake|https://datatracker.ietf.org/doc/html/rfc6455#section-1.3>

=item I<subprotocol>

An array reference of protocols. They can be arbitrary identifiers and they are optionals.

See L<rfc6455 section on subprotocol|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

This can be changed later with L</subprotocol>

=item I<uri>

The uri for the remote WebSocket server.

=item I<version>

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

=head2 cookie

Set or get the C<Cookie> header value.

=head2 disconnect

Close the connection with the server, and return the current object.

=head2 disconnected

Set or get a boolean value representing the connection status to the remote server socket.

There are 2 status: C<disconnecting> and C<disconnected>. The former is set when the client has issued a disconnection message to the remote server and is waiting for the server to acknowledge it, as per the L<WebSocket protocol|https://datatracker.ietf.org/doc/html/rfc6455#page-36>, and the latter is set when the connection is effectively shut down.

=head2 disconnecting

Set or get the boolean value indicating the state of connection to the remote server socket.

This is set to a true value when the client has issued a disconnection notification to the server and is awaiting a response from the server, as per the L<rfc6455 protocol|https://datatracker.ietf.org/doc/html/rfc6455#page-36>

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

Event handler triggered when a binary message is received.

The current client object and the binary message are passed as argument to the event handler.

=head2 on_connect

Event handler triggered when the connection with the server has been made and handshake performed.

The current client object is passed as argument to the event handler.

=head2 on_disconnect

Event handler triggered when the connection with the server is closed.

The current client object is passed as argument to the event handler.

=head2 on_error

Event handler triggered whenever an error occurs.

The current client object and the error message are passed as argument to the event handler.

=head2 on_handshake

Event handler triggered just before the handshake sequence is completed.

Be careful that this must return a true value, or else, it will fail the handshake.

The current client object is passed as argument to the event handler.

=head2 on_ping

Event handler triggered whenever a ping is issued to the server.

The current client object is passed as argument to the event handler.

=head2 on_recv

Event handler triggered whenever a binary or text payload is received from the server.

The current L<frame|WebSocket::Frame> object and the payload data are passed as arguments to the event handler.

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
        }
    });

=head2 on_send

Event handler triggered whenever a message is sent to the remote server.

The current client object and the message are passed as argument to the event handler.

=head2 on_utf8

Event handler triggered whenever a text message is sent to the remote server.

The current client object and the message are passed as argument to the event handler.

=head2 origin

Set or get the origin of the request as a L<Module::Generic::Scalar> object.

=head2 recv

Will attempt to read data from the server socket and call all relevant event handlers. It returns the current object.

=head2 send

Sends data to the server socket and returns the current object. This will also trigger associated event handlers.

Returns the current object.

=head2 send_binary

Sends binary data to the server socket and returns the current object. This will also trigger associated event handlers.

Returns the current object.

=head2 send_utf8

Sends data to the server socket after having encoded them using L<Encode/encode>> and returns the current object. This will also trigger associated event handlers.

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

Copyright(c) 2021 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut

