##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Connection.pm
## Version v0.1.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/13
## Modified 2021/10/23
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Connection;
BEGIN
{
    use strict;
    use warnings;
    # Import constants
    use WebSocket qw( :ws );
    use parent qw( WebSocket );
    use Encode;
    use HTTP::Response ();
    use HTTP::Status ();
    use JSON ();
    use Nice::Try;
    use Socket qw( IPPROTO_TCP TCP_NODELAY );
    use URI;
    use WebSocket::Handshake::Server;
    use WebSocket::Frame;
    our $VERSION = 'v0.1.1';
};

sub init
{
    my $self = shift( @_ );
    # Need to have this setup before, because calls to subprotocol depend on it
    $self->{handshake}     = WebSocket::Handshake::Server->new;
    $self->{max_recv_size} = eval{ WebSocket::Frame->new->max_payload_size } || 65536,
    $self->{max_send_size} = eval{ WebSocket::Frame->new->max_payload_size } || 65536,
    $self->{nodelay}       = 1,
    $self->{on_binary}     = sub{},
    $self->{on_disconnect} = sub{},
    $self->{on_handshake}  = sub{},
    $self->{on_origin}     = sub{1},
    $self->{on_pong}       = sub{},
    $self->{on_ready}      = sub{},
    $self->{on_utf8}       = sub{},
    $self->{server}        = undef,
    $self->{socket}        = undef,
    $self->{subprotocol}   = [];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self->error( "socket parameter is required." ) ) if( !$self->{socket} );
    return( $self->error( "server parameter is required." ) ) if( !$self->{server} );
    $self->{handshake}->debug( $self->debug );
    $self->{disconnecting} = 0;
    $self->{disconnected}  = 0;
    $self->{ip} = $self->{socket}->peerhost;
    $self->{port} = $self->{socket}->peerport;

    # only attempt to start SSL if this is an IO::Socket::SSL-like socket that also has not completed its SSL handshake (SSL_startHandshake => 0)
    $self->{needs_ssl} = 1 if( $self->{socket}->can( 'accept_SSL' ) && !$self->{socket}->opened );
    return( $self );
}

sub disconnect
{
    my( $self, $code, $reason ) = @_;
    # XXX Remove once debugged
    my $trace = $self->_get_stack_trace;
    $self->message( 3, "Disconnecting remote client connection. Stack trace -> $trace" );
    return( $self ) if( $self->disconnecting || $self->disconnected );
    $self->disconnecting(1);
    
    my $disconnect_cb = $self->on_disconnect || sub{};
    $disconnect_cb->( $self, $code, $reason );

    my $data = '';
    if( defined( $code ) || defined( $reason ) )
    {
        $code ||= 1000;
        $reason = '' unless( defined( $reason ) );
        $data = pack( "na*", $code, $reason );
    }
    # During handshake, still under http protocol, we just close the connection.
    $self->send( close => $data ) unless( !$self->handshake->is_done );
    # Now we wait a reasonable amount of time until the client acknowledges and send us too a close confirmation according to rfc6455 section 5.1.1
    local $SIG{ALRM} = sub
    {
        $self->shutdown;
    };
    alarm(3);
    # $self->server->disconnect( $self->{socket} );
    return( $self );
}

sub disconnected { return( shift->_set_get_boolean( 'disconnected', @_ ) ); }

sub disconnecting { return( shift->_set_get_boolean( 'disconnecting', @_ ) ); }

sub frame { return( shift->_set_get_object_without_init( 'frame', 'WebSocket::Frame', @_ ) ); }

sub handshake { return( shift->_set_get_object_without_init( 'handshake', 'WebSocket::Handshake::Server', @_ ) ); }

sub http_error
{
    my $self   = shift( @_ );
    if( $self->handshake->is_done )
    {
        return( $self->error( "You cannot call http_error after the handshake is completed." ) );
    }
    my( $code, $msg );
    if( ( @_ == 1 && ref( $_[0] ) ne 'HASH' ) || 
        # e.g.: 500 => { status => 'Oh my', message => 'Something went wrong' }
        ( @__ == 2 && ref( $_[1] ) eq 'HASH' ) ||
        # e.g. 500 => 'Internal error'
        ( @_ == 2 && !ref( $_[1] ) ) ||
        # e.g.: 500, status => 'Oh my!', message => 'Something went wrong'
        ( @_ > 2 && ( @_ % 2 ) ) )
    {
        $code = shift( @_ );
    }
    $msg       = shift( @_ ) if( @_ == 1 && !ref( $_[0] ) );
    my $opts   = $self->_get_args_as_hash( @_ );
    $code      = $opts->{code} if( exists( $opts->{code} ) && length( $opts->{code} ) );
    return( $self->error( "No http code provided." ) ) if( !defined( $code ) || !length( $code ) );
    # If status line is missing, HTTP::Response will get the default value
    my $status = $opts->{status} || $self->status_message( $code );
    my $header = $opts->{headers} // [];
    my $data   = $msg || $opts->{data} || $status;
    unless( ref( $data ) eq 'HASH' )
    {
        $data =
        {
        code    => $code,
        message => $data,
        status  => $status,
        };
    }
    $data = JSON->new->convert_blessed->relaxed->utf8->encode( $data );
    my $resp   = WebSocket::Response->new( $code, $status, $header, $data,
        extensions  => $self->server->extensions.
        versions => $self->versions
    );
    $resp->protocol( $self->handshake->request->protocol->scalar );
    my $h = $resp->headers;
    $h->header( Upgrade => 'websocket' ) unless( $h->header( 'Upgrade' ) );
    $h->header( Connection => 'Upgrade' ) unless( $h->header( 'Connection' ) );
    my $version = $self->server->version;
    $h->date( time() );
    $h->expires( time() );
    $h->header( Pragma => 'no-cache' );
    $h->header(
        'Content-Language'          => 'en_GB',
        'Cache-Control'             => 'no-cache',
        'Strict-Transport-Security' => 'max-age=0',
        'X-Content-Type-Options'    => 'nosniff',
        'X-Frame-Options'           => 'sameorigin',
        'X-XSS-Protection'          => '1; mode=block',
    );
    # $resp->content( $data ) if( $data );
    my $socket = $self->socket || return( $self->error( "No socket found to print the http error to" ) );
    my $rv = syswrite( $socket, $resp->as_string );
    return( $self->error( "Unable to write to socket: $!" ) ) if( !defined( $rv ) );
    $self->server->disconnect( $socket );
    return( $rv );
}

sub ip { return( shift->_set_get_scalar_as_object( 'ip', @_ ) ); }

sub is_ready { return( shift->handshake->is_done ); }

sub max_recv_size
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->error( "Cannot change max_recv_size; handshake is already complete" ) ) if( $self->frame );
        $self->_set_get_number( 'max_recv_size', @_ );
    }
    return( $self->_set_get_number( 'max_recv_size' ) );
}

sub max_send_size { return( shift->_set_get_number( 'max_send_size', @_ ) ); }

sub needs_ssl { return( shift->_set_get_boolean( 'needs_ssl', @_ ) ); }

sub nodelay
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->_set_get_boolean( 'nodelay', @_ );
        setsockopt( $self->{socket}, IPPROTO_TCP, TCP_NODELAY, $self->{nodelay} ? 1 : 0 ) unless( $self->{handshake} );
    }
    return( $self->_set_get_boolean( 'nodelay' ) );
}

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

sub on_disconnect { return( shift->_set_get_code( 'on_disconnect', @_ ) ); }

sub on_handshake { return( shift->_set_get_code( 'on_handshake', @_ ) ); }

sub on_origin { return( shift->_set_get_code( 'on_origin', @_ ) ); }

sub on_pong { return( shift->_set_get_code( 'on_pong', @_ ) ); }

sub on_ready { return( shift->_set_get_code( 'on_ready', @_ ) ); }

sub on_utf8 { return( shift->_set_get_code( 'on_utf8', @_ ) ); }

sub origin { return( shift->_set_get_uri( 'origin', @_ ) ); }

sub port { return( shift->_set_get_number( 'port', @_ ) ); }

# Called by WebSocket::Server
sub recv
{
    my $self = shift( @_ );
    
    my $socket = $self->socket;
    my $hs     = $self->handshake;
    if( $self->needs_ssl )
    {
        my $ssl_done = $socket->accept_SSL;
        if( $socket->errstr )
        {
            $self->message( 3, "SSL socket error: ", $socket->errstr );
            warnings::warn( "SSL socket error: ", $socket->errstr ) if( warnings::enabled( $self->server ) );
            if( $hs )
            {
                $self->http_error({ code => 500, message => 'SSL socket error' });
            }
            else
            {
                $self->disconnect( WS_INTERNAL_SERVER_ERROR, 'SSL socket error' );
            }
            return( $self->pass_error( $socket->errstr ) );
        }
        unless( $ssl_done )
        {
            warnings::warn( "SSL is needed, but socket is not accepting ssl.") if( warnings::enabled( $self->server ) );
            return( $self->error({ code => 417, message => "SSL is needed, but socket is not accepting ssl." }) );
        }
        $self->needs_ssl(0);
    }

    my( $len, $data ) = ( 0, '' );
    if( !( $len = sysread( $socket, $data, 8192 ) ) )
    {
        $self->message( 3, "Unable to read from socket, disconnecting: $!" );
        warnings::warn( "Unable to read from socket, disconnecting: $!") if( warnings::enabled( $self->server ) );
        if( $hs )
        {
            $self->http_error({ code => 500, message => 'Unable to read from socket' });
        }
        else
        {
            $self->disconnect( WS_INTERNAL_SERVER_ERROR, 'Unable to read from socket' );
        }
        return( $self->error( "Unable to read from socket: $!" ) );
    }

    # read remaining data
    $len = sysread( $socket, $data, 8192, length( $data ) ) while( $len >= 8192 );

    $self->message( 3, "Received ", length( $data ), " bytes of data. Handshake done? ", ( $hs->is_done ? 'yes' : 'no' ) );
    
    if( $hs && !$hs->is_done )
    {
        $hs->debug( $self->debug );
        my $rv = $hs->parse( $data );
        if( !defined( $rv ) )
        {
            $self->message( 3, "Handshake error occurred, disconnecting with code '", WS_PROTOCOL_ERROR, "': '", $hs->error->message, "'" );
            # $self->disconnect( WS_PROTOCOL_ERROR ); # 1002, protocol error
            $self->http_error({ code => 400, message => 'Handshake error' });
            return( $self->pass_error( $hs->error ) );
        }
        # Done parsing
        elsif( $hs->is_done )
        {
            my $req_path = $hs->request->uri->path;
            my $req_host = $hs->request->host;
            $self->message( 3, "Parsing request is done with path '$req_path' and host '$req_host'" );
            my $uri = URI->new( ( $self->needs_ssl ? 'wss' : 'ws' ) . '://' . ( $req_host || $self->server->ip ) );
            # rfc6455 says those are the standard ports
            if( ( $self->needs_ssl && $self->server->port != 443 ) ||
                ( !$self->needs_ssl && $self->server->port != 80 ) )
            {
                $uri->port( $self->server->port );
            }
            $uri->path( $req_path );
            $self->request_uri( $uri );
            
            my $orig = URI->new( $hs->request->origin );
            $self->origin( $orig );
            $self->message( 3, "Origin is '$orig'" );
            my $origin_cb = $self->on_origin || sub{1};
            # Callback as the user may reject connection with 403 Forbidden if origin is not satisfactory
            # rfc6455, section 4.2.2 <https://datatracker.ietf.org/doc/html/rfc6455#section-4.2.2>
            try
            {
                local $SIG{ALRM} = sub{ die( "timeout\n" ); };
                alarm(2);
                my $orig_rv = $origin_cb->( $self, $orig, $hs );
                $self->message( 3, "origin callback returned '$orig_rv'" );
                unless( $orig_rv )
                {
                    $self->message( 3, "origin callback did not return a true value." );
                    $self->http_error({
                        code => 403,
                        message => "Unacceptable origin \"$orig\""
                    });
                    return( $self->error({ code => 403, message => "origin callback did not return a true value." }) );
                }
                alarm(0);
            }
            catch( $e )
            {
                $self->message( 3, "Error trying to execute the origin callback: $e" );
                if( $e =~ /timeout/ )
                {
                    $self->http_error({
                        code => 408,
                        message => "Timeout checking for origin"
                    });
                    return( $self->error({ code => 408, message => "Timeout checking for origin" }) );
                }
                else
                {
                    $self->http_error({
                        code => 500,
                        message => "Unexpected server error occurred"
                    });
                    return( $self->error({ code => 500, message => "Unexpected error while calling origin callback: $e" }) );
                }
            }
            
            $self->message( 3, "Checking version negotiation. Server version is '", $self->server->versions->join( ',' )->scalar, "'" );
            if( $self->server->versions->length )
            {
                # Servers can have multiple supported versions
                # but client has only one
                my $ok_versions = $self->server->versions;
                my $client_version = $hs->request->version;
                $self->message( 3, "Checking server supported versions '", $ok_versions->join( ',' )->scalar, "' vs the client requested one -> '", $client_version->version, "'." );
                if( !defined( $client_version ) || !length( "$client_version" ) )
                {
                    $self->http_error({
                        code => 400,
                        message => "Missing version header",
                    });
                    return( $self->error({ code => 400, message => "Missing version header" }) );
                }
                # If there is only one version supported and it does not match the client requested one,
                # as per the rfc6455 section 4.2.2, we abort the connection
                if( $ok_versions->length == 1 && 
                    $ok_versions->first != $client_version )
                {
                    $self->http_error({
                        code => 400,
                        message => "Protocol version $client_version unsupported",
                    });
                    return( $self->error({ code => 400, message => "Protocol version $client_version unsupported" }) );
                }
                
                # Check each server supported version to see if the one requested by the client is among them
                my $found = 0;
                my $do_version_negotiation = 0;
                $ok_versions->foreach(sub
                {
                    my $v = shift( @_ );
                    if( $v == $client_version )
                    {
                        $found++;
                        return;
                    }
                    elsif( $v->type eq 'hybi' && $v->revision >= 15 )
                    {
                        $do_version_negotiation++;
                    }
                });
                # Nothing was found, so we enter in version negotiation as per rfc6455 revision
                if( !$found )
                {
                    if( $do_version_negotiation )
                    {
                        # The necessary headers based on protocol version will be set by http_error()
                        $self->http_error({ code => 426, message => "Unsupported version \"${client_version}\"" });
                        return( $self->error({ code => 426, message => "Unsupported version \"${client_version}\"" }) );
                    }
                }
            }
            
            $self->message( 3, "Version is all good. Checking extensions." );
            # Client has provided extension and we have some that we support.
            # Let's check
            my $client_ext = $hs->request->extensions;
            if( $client_ext->length &&
                $self->server->extensions->length )
            {
                my $server_ext = $self->server-extensions;
                my $ok_extensions = $self->new_array;
                $client_ext->foreach(sub
                {
                    my $ext = shift( @_ );
                    $server_ext->foreach(sub
                    {
                        my $candidate_ext = shift( @_ );
                        if( $candidate_ext->extension eq $ext->extension )
                        {
                            $ok_extensions->push( $candidate_ext );
                            return;
                        }
                    });
                });
                if( scalar( @$ok_extensions ) )
                {
                    $hs->response->extensions( $ok_extensions );
                }
            }
            
            my $client_proto = $hs->request->subprotocol;
            $self->message( 3, "Checking on client subprotocol -> '", $client_proto->join( "', '" ), "' against server supported ons -> '", $self->server->subprotocol->join( "', '" ), "'." );
            if( $client_proto->length && 
                $self->server->subprotocol->length )
            {
                my $ok_proto = $client_proto->intersection( $self->server->subprotocol );
                $self->message( 3, "Resulting common subprotocols found -> '", $ok_proto->join( "', '" ), "'." );
                $self->subprotocol( $ok_proto );
            }
            
            my $handshake_cb = $self->on_handshake || sub{};
            try
            {
                $handshake_cb->( $self, $hs );
            }
            catch( $e )
            {
                warnings::warn( "Error calling the handshake callback: $e" ) if( warnings::enabled( $self->server ) );
                $self->http_error({ code => 500, message => 'Internal error' });
                return( $self->error({ code => 500, message => "Error calling the handshake callback: $e" }) ); 
            }
            
            unless( do{ local $SIG{__WARN__} = sub{}; $socket->connected } )
            {
                $self->http_error({ code => 410, message => "Connection gone" });
                return( $self->error( "Socket is not connected." ) );
            }
            
            $self->message( 3, "Sending out server handshake response: ", $hs->as_string );
            my $len = syswrite( $socket, $hs->as_string );
            if( !defined( $len ) )
            {
                return( $self->error({ code => 500, message => "Unable to write handshake response to socket: $!" }) );
            }
            # CORE::delete( $self->{handshake} );
            # XXX We use is_done to check
            # $self->handshake( undef() );

            # $self->{frame} = WebSocket::Frame->new( max_payload_size => $self->max_recv_size );
            # XXX Set frame object for this connection
            my $frame = WebSocket::Frame->new( max_payload_size => $self->max_recv_size, debug => $self->debug ) || do
            {
                $self->disconnect( WS_INTERNAL_SERVER_ERROR => 'Internal error' );
                return( $self->pass_error( WebSocket::Frame->error ) );
            };
            $self->frame( $frame );
            setsockopt( $socket, IPPROTO_TCP, TCP_NODELAY, 1 ) if( $self->nodelay );
            my $ready_cb = $self->on_ready || sub{};
            try
            {
                $ready_cb->( $self );
            }
            catch( $e )
            {
                $self->message( 3, "Error while trying to execute the 'ready' callback: $e" );
                warnings::warn( "An error occurred while trying to call the ready callback: $e" ) if( warnings::enabled( $self->server ) );
            }
        }
        # return( $self->error( "Client handshake parsed, but still not marked as done? Should not get here." ) );
        return( $self );
    }
    # End of handshake

    my $frame = $self->frame;
    $self->message( 3, "Processing ", length( $data ), " bytes of data -> '$data'" );
    $frame->append( $data );
    $self->message( 3, "Frame debug value is '", $frame->debug, "'" );

    my $bytes;
    my $binary_cb = $self->on_binary || sub{};
    my $msg_cb = $self->on_utf8 || sub{};
    my $pong_cb = $self->on_pong || sub{};
    while( defined( $bytes = $frame->next_bytes ) )
    {
        $self->message( 3, "Server connection received ", length( $bytes ), " bytes of data -> '$bytes'" );
        if( $frame->is_binary )
        {
            $self->message( 3, "Frame is of type binary" );
            try
            {
                $binary_cb->( $self, $bytes );
            }
            catch( $e )
            {
                $self->message( 3, "Error with callback to process binary message: $e" );
                warnings::warn( "Error with callback to process binary message: $e" ) if( warnings::enabled( $self->server ) );
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
                $self->message( 3, "Error with callback to process text message: $e" );
                warnings::warn( "Error with callback to process text message: $e" ) if( warnings::enabled( $self->server ) );
            }
        }
        elsif( $frame->is_pong )
        {
            $self->message( 3, "Frame is of type pong" );
            try
            {
                $pong_cb->( $self, $bytes );
            }
            catch( $e )
            {
                $self->message( 3, "Error with callback to process pong: $e" );
                warnings::warn( "Error with callback to process pong: $e" ) if( warnings::enabled( $self->server ) );
            }
        }
        # rfc6455, section 5.5.1:
        # "If an endpoint receives a Close frame and did not previously send a Close frame, the endpoint MUST send a Close frame in response. (When sending a Close frame in response, the endpoint typically echos the status code it received.)"
        elsif( $frame->is_close )
        {
            $self->message( 3, "Received disconnection notice from client." );
            # A reply to our own disconnection
            if( $self->disconnecting )
            {
                $self->message( 3, "Receiving client reply to our disconnection." );
                $self->shutdown;
            }
            # We receive a disconnect notification. We reply back and shutdown
            else
            {
                # We reply
                if( length( "$bytes" ) )
                {
                    my( $code, $reason ) = ( unpack( 'n', substr( $bytes, 0, 2, '' ) ), Encode::decode( 'UTF-8', $bytes ) );
                    $self->message( 3, "Frame is of type close with code '$code' and reason '$reason'" );
                    $self->disconnect( $code );
                }
                else
                {
                    $self->message( 3, "Frame is of type close" );
                    $self->disconnect( WS_OK );
                }
                # And we disconnect
                $self->shutdown;
            }
            return( $self );
        }
        else
        {
            $self->message( 3, "Frame is of unknown type." );
        }
    }
    $self->message( 3, "Done receiving data." );

    if( !$bytes && $frame->error )
    {
        $self->message( 3, "Error occurred, disconnecting with code '", WS_PROTOCOL_ERROR, "': ", $frame->error );
        my $code = $frame->error->code || WS_PROTOCOL_ERROR;
        my $msg  = $frame->error->message || 'Protocol error';
        $self->disconnect( $code => $msg ); # 1002, protocol error
        return( $self );
    }
    # XXX Returning number of bytes received or our object?
    return( $self );
}

sub request_uri { return( shift->_set_get_uri( 'request_uri', @_ ) ); }

sub send
{
    my( $self, $type, $data ) = @_;

    if( !$self->handshake->is_done )
    {
        warnings::warn( "Tried to send data before finishing handshake\n" ) if( warnings::enabled( $self->{server} ) );
        return(0);
    }

    my $trace = $self->_get_stack_trace;
    $self->message( 3, "Sending message of type '$type' -> '$data' with trace: $trace" );
    my $frame = WebSocket::Frame->new(
        type             => $type,
        max_payload_size => $self->max_send_size,
        debug            => $self->debug,
    );
    $frame->append( $data ) if( defined( $data ) );
    
    try
    {
        my $bytes = $frame->to_bytes;
        my $rv = syswrite( $self->socket, $bytes );
        return( $self->error( "Error write to socket: $!" ) ) if( !defined( $rv ) );
        return( $rv );
    }
    catch( $e )
    {
        return( $self->error( "Error while building message: $e" ) );
    }
}

sub send_binary { return( shift->send( binary => @_ ) ); }

sub send_utf8 { return( shift->send( text => Encode::encode( 'UTF-8', shift( @_ ) ) ) ); }

sub server { return( shift->_set_get_object_without_init( 'server', 'WebSocket::Server', @_ ) ); }

sub shutdown
{
    my $self = shift( @_ );
    $self->message( 3, "Shutting down this connection with remote client." );
    return( $self ) if( $self->disconnected );
    $self->server->disconnect( $self->{socket} );
    $self->disconnected(1);
    return( $self );
}

sub socket { return( shift->_set_get_object_without_init( 'socket', 'IO::Socket', @_ ) ); }

sub status_message { return( HTTP::Status::status_message( $_[1] ) ); }

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
        $self->handshake->response->subprotocol( $v ) if( !$self->handshake->is_done );
    }
    return( $self->_set_get_array_as_object( 'subprotocol' ) );
}

1;

# XXX POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Connection - WebSocket Server Connection

=head1 SYNOPSIS

    use WebSocket qw( :ws );
    use WebSocket::Connection;
    my $conn = WebSocket::Connection->new(
        max_recv_size   => 65536,
        max_send_size   => 65536,
        nodelay         => 1,
        on_binary       => \&on_binary_message,
        on_disconnect   => \&on_close,
        on_handshake    => \&on_handshake,
        on_origin       => \&on_origin,
        on_pong     	=> \&on_pong,
        on_ready        => \&on_ready,
        on_utf8         => \&on_utf8_message,
        # required
        server          => $websocket_server_object,
        # required
        socket          => $net_socket_object,
    ) || die( WebSocket::Connection->error, "\n" );

    $conn->disconnect( WS_INTERNAL_SERVER_ERROR, 'Something bad happened' );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

Class initiated by L<WebSocket::Server> for each connection received.

=head1 METHODS

=head2 disconnect

    $conn->disconnect( WS_INTERNAL_SERVER_ERROR, 'Something bad happened' );

Provided with a code and a reason, and this will disconnect from the WebSocket and terminate the client connection.

It returns the current object.

=head2 disconnected

Set or get a boolean value representing the connection status to the remote client socket.

There are 2 status: C<disconnecting> and C<disconnected>. The former is set when the server has issued a disconnection message to the remote client and is waiting for the client to acknowledge it, as per the L<WebSocket protocol|https://datatracker.ietf.org/doc/html/rfc6455#page-36>, and the latter is set when the connection is effectively shut down.

=head2 disconnecting

Set or get the boolean value indicating the connection is disconnecting.

=head2 frame

Returns the connection L<frame object|WebSocket::Frame>.

=head2 handshake

Set or get the handshake object (L<WebSocket::Handshake::Server>)

This object is instantiated upon instantiation of connection object, so there is no need to create it.

=head2 http_error

    $conn->http_error( 426 );
    $conn->http_error( 426, "Upgrade Required" );
    $conn->http_error( 426, "Upgrade Required", "Oh no!" );
    $conn->http_error( 426, "Upgrade Required", "Oh no!", [] );
    $conn->http_error( 426, "Upgrade Required", "Oh no!",
        HTTP::Headers->new(
            Content_Language => "en_GB",
            Cache_Control    => "no-cache"
        )
    );

Provided with an http status code, an optional status line, some optional content and some optional headers and this will push out on the socket the server error.

This method is meant to respond to the client handshake with a proper http error when required, such as if the version or host is missing in the request.

It will return an error if this method is called after a successful handshake has occurred. Otherwise, it returns the return value from L<perlfunc/syswrite> which is the number of bytes writen

=head2 ip

Set or get the remote ip address of the client connected.

=head2 is_ready

Returns true once the handshake has been performed, false otherwise.

=head2 max_recv_size

Set or get the maximum bytes that can be received in one time.

=head2 max_send_size

Set or get the maximum bytes that can be sent in one time.

=head2 needs_ssl

Returns true if the server is using ssl, false otherwise.

=head2 nodelay

Set the client socket option C<TCP_NODELAY> to true or false.

Returns the currently set boolean value.

=head2 on

Provided with an array or array reference of event name and core reference pairs and this will set those event handlers.

It returns the current object.

=head2 on_binary

Set or get the code reference that is triggered when a binary message is received from the client.

The event handler is then passed the current connection object and the message itself.

=head2 on_disconnect

Set or get the code reference that is triggered when the connection is closed.

The event handler is then passed the current connection object.

=head2 on_handshake

Event handler called after the handshake between the client and the server has been performed.

The handler is passed this connection object (L<WebSocket::Connection> and the handshake object (L<WebSocket::Handshake>)

You can get the requested uri using L</request_uri>, which will return a L<URI> object.

=head2 on_origin

Event handler called during the handshake between the client and the server. This is a convenient handler so that the caller can be called with the client submitted origin and decide to accept it by returning true, or reject it by return false.

=head2 on_pong

Event handler called when a ping is received from the client.

The event handler is then passed the current connection object.

See L<rfc6455 for more on this|https://datatracker.ietf.org/doc/html/rfc6455#section-5.5.2>

=head2 on_ready

Event handler called when the connection is ready.

The event handler is then passed the current connection object.

=head2 on_utf8

Event handler called when a text message is received from the client.

The event handler is then passed the current connection object and the message itself, after having been utf8 decoded.

=head2 origin

Set or get the L<origin|https://datatracker.ietf.org/doc/html/rfc6455#page-50> of the client as set in the request header.

=head2 port

Set or get the port number on which the remote client is connected.

=head2 recv

Attempts to read chunks of 8192 bytes of data from the client L</socket>

If the handshake has not been done yet, it will be performed and the L</on_handshake> handler called and the L</on_ready> handler as well.

Then, based on the type of data received, it will trigger the L</on_binary> for binary message, L</on_utf8> for text message, L</on_pong> if this is a pong.

=head2 request_uri

Returns a L<URI> object representing the uri been requested by the client. For example, a request such as:

    GET /?csrf=7a292e3.1631279571 HTTP/1.1
    Upgrade: WebSocket
    Connection: Upgrade
    Host: localhost:8080
    Origin: http://localhost:8082
    Sec-WebSocket-Key: XcCcHD+q7fmfqRSnPJA9Lg==
    Sec-WebSocket-Version: 13

would result maybe in the uri being C<wss://localhost:8080/?csrf=7a292e3.1631279571> assuming the server is using SSL.

=head2 send

Sends data to the client socket.

Be careful this will return an error if you attempt to send data before the handshake is completed, so you need to check L</is_ready>

It returns the number of bytes actually written to the socket.

=head2 send_binary

Provided with some data, and this will send the binary message to the client socket.

=head2 send_utf8

Provided with some text message, and this will utf8 encode it using L<Encode/encode> and send it to the client socket.

=head2 server

Set or get the L<WebSocket::Server> object.

=head2 status_message

Returns the status message provided by the other party.

=head2 shutdown

Terminate the client connection by calling L<WebSocket::Server/disconnect> passing it the current connection socket. This does not terminate the server connection itself. For this, check L<WebSocket::Server/shutdown>.

=head2 socket

Set or get the L<IO::Socket> (or one of its inheriting package such as L<IO::Socket::INET>) object.

=head2 subprotocol

Set or get an array object of WebSocket protocols and set the WebSocket header C<Sec-WebSocket-Protocol>.

Returns a L<Module::Generic::Array> object.

See L<rfc6455 for more information|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

=head1 CREDITS

Graham Ollis for L<AnyEvent::WebSocket::Client>, Eric Wastl for L<Net::WebSocket::Server>, Vyacheslav Tikhanovsky aka VTI for L<Protocol::WebSocket>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
