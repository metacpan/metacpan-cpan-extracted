##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Response.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/17
## Modified 2021/09/17
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Response;
BEGIN
{
    use strict;
    use warnings;
    use WebSocket::Common qw( :all );
    use parent qw( WebSocket::Common );
    use vars qw( $VERSION );
    use Digest::SHA ();
    use HTTP::Response ();
    use MIME::Base64 ();
    use Nice::Try;
    use URI;
    use WebSocket::Extension;
    use WebSocket::Headers;
    use WebSocket::Version;
    # Defined since version 4 of the rfc6455 section 1.3
    # <https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-04#section-1.3>
    use constant GUID => '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
    use constant HTTP_SWITCHING_PROTOCOLS => 101;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my( $code, $status, $headers, $buffer );
    if( @_ && 
        ( $self->_is_array( $_[2] ) || $self->_is_a( $_[2], 'HTTP::Headers' ) ) )
    {
        ( $code, $status, $headers ) = splice( @_, 0, 3 );
        if( $self->_is_a( $headers, 'HTTP::Headers' ) )
        {
            $headers = $headers->clone;
            $headers = bless( $headers => 'WebSocket::Headers' );
        }
        else
        {
            $headers = WebSocket::Headers->new( @$headers );
        }
        # $req->new( 101, 'Switching Protocol', $headers, $buffer, k1 => v1, k2 => v2);
        # $req->new( 101, 'Switching Protocol', $headers, $buffer, { k1 => v1, k2 => v2 });
        # $req->new( 101, 'Switching Protocol', $headers, k1 => v1, k2 => v2 );
        # $req->new( 101, 'Switching Protocol', $headers, { k1 => v1, k2 => v2 });
        if( ( ( @_ % 2 ) && ref( $_[1] ) ne 'HASH' ) || 
            ref( $_[1] ) eq 'HASH' )
        {
            $buffer = shift( @_ );
        }
    }
    # Otherwise, the first parameter is not a known method, so we safely assume this is a code argument
    elsif( @_ && !$self->can( $_[0] ) )
    {
        $code = shift( @_ );
        # possibly followed by a status argument
        if( ( ( @_ % 2 ) && ref( $_[1] ) ne 'HASH' ) || 
            ref( $_[1] ) eq 'HASH' )
        {
            $status = shift( @_ );
        }
    }
    $self->{buffer}     = $buffer;
    $self->{code}       = $code || HTTP_SWITCHING_PROTOCOLS;
    $self->{cookies}    = [];
    $self->{headers}    = $headers;
    $self->{status}     = $status;
    $self->{version}    = [];
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order}   = [qw( buffer headers )];
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $eol  = shift( @_ ) || "\x0d\x0a";
    my $code = $self->code;
    my $resp_line = "HTTP/1.1 ${code} WebSocket Protocol Handshake";
    # my $resp_line = "HTTP/1.1 ${code} Switching Protocols";
    return( join( $eol, $resp_line, $self->headers_as_string( $eol ), $self->body_as_string ) );
}

sub body_as_string
{
    my $self = shift( @_ );
    # return( $self->checksum ) if( $self->version eq 'draft-ietf-hybi-00' );
    my $v = $self->version;
    # checksums are not used on and after version 4 or before hixie version 76
    # This is not set if this is an error
    if( $self->code == 101 &&
        (
            ( $v->type eq 'hybi'  && $v->revision < 4 ) ||
            ( $v->type eq 'hixie' && $v->revision == 76 ) )
        )
    {
        return( $self->checksum );
    }
    elsif( $self->is_error && $self->buffer->length )
    {
        $self->headers->header( 'Content-Length' => $self->buffer->length->scalar );
        return( $self->buffer->scalar );
    }
    return( '' );
}

sub code { return( shift->_set_get_number( 'code', @_ ) ); }

sub cookies { return( shift->_set_get_array_as_object( 'cookies', @_ ) ); }

sub header { return( shift->headers->header( @_ ) ); }

sub headers_as_string
{
    my $self = shift( @_ );
    my $eol  = shift( @_ ) || "\x0d\x0a";
    # Get the first version available
    my $version = $self->version || $self->version( WEBSOCKET_DRAFT_VERSION_DEFAULT );
    my $h = $self->headers;
    my $upgrade = 'WebSocket';
    # From version 4 onward the value of Upgrade header is all lowercase
    if( $version->type eq 'hybi' && $version->revision => 4 )
    {
        $upgrade = lc( $upgrade );
    }
    $h->header(
        Upgrade     => $upgrade,
        Connection  => 'Upgrade',
    );
    # return( $self->error( "Host is required" ) ) unless( $self->host->defined );
    my $location = URI->new( 'ws' . ( $self->secure ? 's' : '' ) . '://' . $self->host );
    $location->path( $self->uri->path ) if( $self->uri->path ne '/' );
    my $origin = URI->new( $self->origin ? $self->origin : 'http://' . $location->host );
    $origin->scheme( 'https' ) if( !$self->origin && $self->secure );

    # rfc6455 section 4.2.2 on server handshake response
    # For draft revision 4 to 17 (latest)
    if( $version->type eq 'hybi' && $version->revision >= 4 )
    {
        $h->header( 'Sec-WebSocket-Version' => $self->versions->join( ',' )->scalar ) unless( $h->header( 'Sec-WebSocket-Version' ) );
    }
    if( ( $version->type eq 'hybi' && $version->revision >= 0 && $version->revision <= 3 ) ||
        ( $version->type eq 'hixie' && $version->revision == 76 ) )
    {
        my $loc = URI->new( ( $self->handshake->request->secure ? 'wss://' : 'ws://' ) . $self->handshake->request->host . ( $self->handshake->request->uri->path || '/' ) );
        $h->header( 'Sec-WebSocket-Location' => $loc );
    }
    else
    {
        $h->remove_header( 'Sec-WebSocket-Location' );
    }
    
    if( ( $version->type eq 'hixie' && $version->revision == 76 ) ||
        ( $version->type eq 'hybi'  && $version->revision => 0 && $version->revision <= 3 ) )
    {
        $h->header(
            'Sec-WebSocket-Origin'      => $origin,
            'Sec-WebSocket-Location'    => $location,
        );
    }
    elsif( $version->type eq 'hixie' && $version->revision <= 75 )
    {
        $h->header(
            'WebSocket-Origin'      => $origin,
            'WebSocket-Location'    => $location,
        );
    }
    else
    {
        $h->remove_header( qw( Sec-WebSocket-Origin WebSocket-Origin Sec-WebSocket-Location WebSocket-Location ) );
    }
    
    if( $self->code == 101 && $version->type eq 'hybi' && $version->revision >= 4 )
    {
        return( $self->error( "key value is required." ) ) if( !defined( $self->key ) || !length( $self->key ) );
        my $key = $self->key;
        # This fixed uuid value is provided for in the rfc6455
        # See section 1,3 (opening handshake) <https://datatracker.ietf.org/doc/html/rfc6455#section-1.3>
        # since version 4
        $key .= GUID;
        $key = Digest::SHA::sha1( $key );
        $key = MIME::Base64::encode_base64( $key );
        $key =~ s{\s+}{}g;
        $h->header( 'Sec-WebSocket-Accept' => $key );
    }
    else
    {
        $h->remove_header( 'Sec-WebSocket-Accept' );
    }
    
    # <https://datatracker.ietf.org/doc/html/draft-ietf-hybi-thewebsocketprotocol-04#section-5.2.2>
    if( $self->code == 101 && $version->type eq 'hybi' && $version->revision >= 4 && $version->revision <= 5 )
    {
        my $nonce = $self->__generate_16bit_nonce();
        $h->header( 'Sec-WebSocket-Nonce' => $nonce );
    }
    else
    {
        $h->remove_header( 'Sec-WebSocket-Nonce' );
    }
    
    if( $self->subprotocol->length )
    {
        if( ( $version->type eq 'hixie' && $version->revision == 76 ) ||
            ( $version->type eq 'hybi' ) )
        {
            my $sep = ',';
            # From draft hybi revision 3 and lower and all hixie drafts, the separator is a space.
            # It changed with hybi draft revision 4
            if( ( $version->type eq 'hixie' ) ||
                ( $version->type eq 'hybi' && $version->revision <= 3 ) )
            {
                $sep = ' ';
            }
            $h->header( 'Sec-WebSocket-Protocol' => $self->subprotocol->join( $sep )->scalar )
        }
        elsif( $version->type eq 'hixie' && $version->revision >= 10 && $version->revision <= 75 )
        {
            $h->header( 'WebSocket-Protocol' => $self->subprotocol->join( ' ' )->scalar )
        }
        else
        {
            $h->remove_header( qw( Sec-WebSocket-Protocol WebSocket-Protocol ) );
        }
    }
    
    if( $self->extensions->length )
    {
        # if( $self->
        # This will automatically stringify each object in the array to their proper header representation
        $h->header( 'Sec-WebSocket-Extensions' => $self->extensions->join( ',' )->scalar );
    }
    
    if( $self->cookies->length )
    {
        # $h->header( 'Set-Cookie' => $self->cookies->join( ',' )->scalar );
        $self->cookies->for(sub
        {
            $h->header( 'Set-Cookie' => $_ );
        });
    }
    return( $h->as_string( $eol ) );
}

sub key { return( shift->_set_get_scalar_as_object( 'key', @_ ) ); }

sub key1 { return( shift->_set_get_scalar_as_object( 'key1', @_ ) ); }

sub key2 { return( shift->_set_get_scalar_as_object( 'key2', @_ ) ); }

sub location { return( shift->headers->header( 'Location', @_ ) ); }

sub number1 { return( shift->_number( 'number1', 'key1', @_ ) ); }

sub number2 { return( shift->_number( 'number2', 'key2', @_ ) ); }

sub origin { return( shift->headers->header( 'Sec-WebSocket-Origin', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    # Get the HTTP::Request object from parsing
    my $resp;
    try
    {
        return(1) unless( defined( $_[0] ) );
        # Add data to buffer
        # return( $self->pass_error ) unless( $self->_append( @_ ) );
        $self->_append( @_ ) || return( $self->pass_error );
        unless( $self->buffer->match( qr{^HTTP/1\.1[[:blank:]\h]+101 } ) )
        {
            my $bad_line = ( $self->buffer->length > 80 ? $self->buffer->substr( 0, 77 )->append( '...' ) : $self->buffer );
            $bad_line->replace( qr/(\x0d?\x0a)+$/s, '' );
            return( $self->error( "Wrong response line. Got \"$bad_line\", but expected something starting with \"HTTP/1.1 101 \"" ) );
        }
        $resp = HTTP::Response->parse( $self->buffer->scalar ) || return( $self->pass_error );
        $self->headers( $resp->headers );
        $self->protocol( $resp->protocol );
        $self->code( $resp->code );
        $self->status( $resp->message );
        # The rest is the body
        $self->buffer( $resp->content );
    }
    catch( $e )
    {
        return( $self->error( "Error parsing response data: $e" ) );
    }
    # Used in both parse() and parse_chunk()
    return( $self->parse_body );
}

sub parse_body
{
    my $self = shift( @_ );
    # Process body
    my $h = $self->headers;
    # Check if there is a Sec-WebSocket-Version header (available since draft revision 4)
    if( $h->header( 'Sec-WebSocket-Version' ) )
    {
        $self->version( $h->header( 'Sec-WebSocket-Version' )->scalar );
    }
    elsif( $h->header( 'Sec-WebSocket-Accept' ) )
    {
        # $self->version( 'draft-ietf-hybi-10' );
        # The latest version, i.e. revision 17
        $self->version( 'draft-ietf-hybi-17' );
    }
    elsif( $h->header( 'Sec-WebSocket-Origin' ) )
    {
        # $self->version( 'draft-ietf-hybi-00' );
        # The last version that used the response header Sec-WebSocket-Origin
        $self->version( 'draft-ietf-hybi-03' );
        return(1) if( $self->buffer->length < 16 );
        my $checksum = $self->buffer->substr( 0, 16, '' );
        $self->checksum( $checksum );
    }
    else
    {
        $self->version( 'draft-hixie-75' );
    }
    $self->is_done(1);
    
    # Finalise
    my $v = $self->version;
    # if( $self->version eq 'draft-hixie-75' )
    if( $v->type eq 'hixie' && $v->revision == 75 )
    {
        my $location = $h->header( 'WebSocket-Location' );
        return( $self->error( "No \"WebSocket-Location\" header found." ) ) unless( $location->defined );
        $self->location( $location );
        my $uri = URI->new( $location );
        $self->secure(1) if( $uri->scheme eq 'wss' );
        $self->host( $uri->host );
        $self->uri( $uri );
        $self->origin( $h->header( 'WebSocket-Origin' ) );
        $self->subprotocol( $h->header( 'WebSocket-Protocol' )->split( qr/[[:blank:]\h]+/ ) );
    }
    # elsif( $self->version eq 'draft-ietf-hybi-00' )
    elsif( ( $v->type eq 'hixie' && $v->revision == 76 ) ||
           ( $v->type eq 'hybi' && $v->revision <= 3 ) )
    {
        my $location = $h->header( 'Sec-WebSocket-Location' );
        return( $self->error( "No \"Sec-WebSocket-Location\" header found." ) ) unless( $location->defined );
        $self->location( $location );
        my $uri = URI->new( $location );
        $self->secure(1) if( $uri->scheme eq 'wss' );
        $self->host( $uri->host );
        $self->uri( $uri );
        $self->origin( $h->header( 'Sec-WebSocket-Origin' ) );
        $self->subprotocol( $h->header( 'Sec-WebSocket-Protocol' )->split( qr/[[:blank:]\h]+/ ) );
    }
    # No more Sec-WebSocket-Location or Sec-WebSocket-Origin on and after draft revision 4
    else
    {
        $self->subprotocol( $h->header( 'Sec-WebSocket-Protocol' )->split( qr/[[:blank:]\h]*\,[[:blank:]\h]*/ ) );
    }
    
    if( $h->header( 'Sec-WebSocket-Extensions' )->length )
    {
        # Returns a Module::Generic::Array of WebSocket::Extension objects
        my $ref = WebSocket::Extension->new_from_multi( $h->header( 'Sec-WebSocket-Extensions' )->scalar ) ||
            return( $self->pass_error( WebSocket::Extension->error ) );
        $self->extensions( $ref );
    }
    return( $self );
}

sub status { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

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

sub _number
{
    my $self = shift( @_ );
    my( $name, $key, $value ) = @_;
    my $method = "SUPER::$name";
    return( $self->$method( $value ) ) if( length( "$value" ) );
    $value = $self->$method();
    $value = $self->_extract_number( $self->$key ) if( !length( "$value" ) );
    return( $value );
}

# Called from parse_chunk()
sub _parse_body_chunk
{
    my $self = shift( @_ );
    my $resp = $self->SUPER::_parse_body_chunk;
    $self->protocol( $resp->protocol );
    $self->code( $resp->code );
    $self->headers( $resp->headers );
    # The rest is the body
    $self->buffer( $resp->content );
    # Used in both parse() and parse_chunk()
    return( $self->parse_body );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Response - WebSocket Response

=head1 SYNOPSIS

    use WebSocket::Response;
    my $res = WebSocket::Response->new(
        host        => 'example.com',
        uri         => '/demo',
        origin      => 'http://example.com',
        number1     => 777_007_543,
        number2     => 114_997_259,
        challenge   => "\x47\x30\x22\x2D\x5A\x3F\x47\x58"
    ) || die( WebSocket::Response->error, "\n" );
    $res->as_string;
    # HTTP/1.1 101 WebSocket Protocol Handshake
    # Upgrade: WebSocket
    # Connection: Upgrade
    # Sec-WebSocket-Origin: http://example.com
    # Sec-WebSocket-Location: ws://example.com/demo
    #
    # 0st3Rl&q-2ZU^weu

    # Parser
    $res = WebSocket::Response->new;
    $res->parse( <<EOT );
    HTTP/1.1 101 WebSocket Protocol Handshake
    Upgrade: WebSocket
    Connection: Upgrade
    Sec-WebSocket-Origin: file://
    Sec-WebSocket-Location: ws://example.com/demo
    
    0st3Rl&q-2ZU^weu
    EOT

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Class to build or parse a WebSocket response. It inherits all the methods from L<WebSocket::Common>. For convenience, they are all listed here.

=head1 CONSTRUCTOR

=head2 new

    my $req = WebSocket::Response->new( $code, $status, $headers, $buffer,
        host        => 'example.com',
        uri         => 'wss://example.com/chat',
        origin      => 'http://example.com',
        subprotocol => 'com.example.chat'
    );
    my $req = WebSocket::Response->new( $code, $status, $headers, $buffer, {
        host        => 'example.com',
        uri         => 'wss://example.com/chat',
        origin      => 'http://example.com',
        subprotocol => 'com.example.chat'
    });
    my $req = WebSocket::Response->new( $code, $status, $headers,
        host        => 'example.com',
        uri         => 'wss://example.com/chat',
        origin      => 'http://example.com',
        subprotocol => 'com.example.chat'
    );
    my $req = WebSocket::Response->new( $code, $status, $headers, {
        host        => 'example.com',
        uri         => 'wss://example.com/chat',
        origin      => 'http://example.com',
        subprotocol => 'com.example.chat'
    });

Provided with an http code, http status, an optional set of headers, as either an array reference or a L<HTTP::Headers> object, some optional content and an hash or hash reference of parameters, and this instantiates a new L<WebSocket::Response> object. The supported parameters are as follow. Each parameter can be set or changed later using the method with the same name:

=over 4

=item C<buffer>

Content buffer

=item C<code>

An integer representing the status code, such as C<101> (switching protocol).

=item C<cookies>

A C<Set-Cookie> response header string. The string provided must be already properly formatted and encoded and will be added as is. For example:

    WebSocket::Request->new(
        cookies => q{id=a3fWa; Max-Age=2592000},
        host    => 'example.com'
    );

=item C<headers>

Either an array reference of header-value pairs, or an L<HTTP::Headers> object.

If an array reference is provided, an L<HTTP::Headers> object will be instantiated with it.

=item C<max_message_size>

Integer. Defaults to 20Kb. This is the maximum payload size.

=item C<number1>

Value for key1 as used in protocol version 0 to 3 of WebSocket requests.

=item C<number2>

Value for key2 as used in protocol version 0 to 3 of WebSocket requests.

=item C<origin>

The C<Origin> header value.

See L<rfc6454|https://datatracker.ietf.org/doc/html/rfc6454>

=item C<protocol>

HTTP/1.1. This is the only version supported by L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455>

=item C<secure>

Boolean. This is set to true when the connection is using ssl (i.e. C<wss>), false otherwise.

=item C<status>

The status line, such as C<Switching Protocol>. This is set upon parsing. There should be no need to set this by yourself.

=item C<subprotocol>

The optional subprotocol which consists of multiple arbitrary identifiers that need to be recognised and supported by the server.

    WebSocket::Request->new(
        subprotocol => 'com.example.chat',
    );
    # or
    WebSocket::Request->new(
        subprotocol => [qw( com.example.chat com.example.internal )],
    );

See L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

=item C<uri>

The request uri, such as C</chat> or it could also be a fully qualified uri such as C<wss://example.com/chat>

=item C<version>

The WebSocket protocol version. Defaults to C<draft-ietf-hybi-17>

See L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455#page-26>

=item C<versions>

Same as I<version>, but pass an array of L<WebSocket::Version> objects or version number, or draft identifier such as <draft-ietf-hybi-17>

=back

=head1 METHODS

=head2 as_string

The response returned as a string.

=head2 body_as_string

The response body returned as a string.

=head2 code

The response code returned as a 3 or 4-digits integer.

=head2 cookies

L<Array object|Module::Generic::Array> of cookies.

=head2 header

This is a short-cut for L<WebSocket::Headers/header>

=head2 headers

Set or get the L<HTTP::Headers> object. If none is set, and this method is accessed, a new one will be instantiated.

=head2 headers_as_string

Calls C<as_string> on L<HTTP::Headers> and returns its value.

=head2 host

Set or get the C<Host> header value.

=head2 is_done

Set or get the boolean value. This is set to signal the parsing is complete.

=head2 key

Value of header C<Sec-WebSocket-Key> available in protocol version 4 to 17.

=head2 key1

Value of header C<Sec-WebSocket-Key1> available in protocol version 0 to 3.

=head2 key2

Value of header C<Sec-WebSocket-Key2> available in protocol version 0 to 3.

=head2 location

Value of header C<Sec-WebSocket-Location> available in protocol version 76, and 0 to 3.

=head2 number1

This is a default method to store a number used for the checksum challenge sent to the client.

=head2 number2

This is a default method to store a number used for the checksum challenge sent to the client.

=head2 parse

    my $rv = $res->parse( $some_response_data ) ||
        die( $res->error );

Provided with some request content buffer and this will parse it using L<HTTP::Headers> for the headers and the body with this module.

It returns C<undef> and set an L<error object|Module::Generic/error> upon failure, and returns the current object on success.

=head2 parse_body

This method is kind of a misnomer because it actually performs header-parsing post processing mostly. It does some body processing for earlier version of the protocol when the handshake challenge was in the body rather than in the header.

It also tries to find out the protocol version used by the other party.

Returns the current object used.

=head2 protocol

Set or get the protocol used. Typically C<HTTP/1.1>. This is set upon parsing. You should not have to set this yourself.

=head2 secure

Boolean value. True if the connection is using ssl, i.e. C<wss>

=head2 status

Set or get the response status line, such as C<Switching Protocol>

=head2 subprotocol

Set or get an array object (L<Module::Generic::Array>) of subprotocols.

See L<rfc6455 for more information|https://datatracker.ietf.org/doc/html/rfc6455>

=head2 uri

Set or get the request uri. This returns a L<URI> object.

=head2 version

Set the protocol version.

See L<rfc6455 section 4.1 for more information|https://datatracker.ietf.org/doc/html/rfc6455#section-4.4>

=head2 versions

Same as L</versions>, but pass an array of L<WebSocket::Version> objects or version number, or draft identifier such as <draft-ietf-hybi-17>

Multiple versions are part of the protocol handshake negotiation from protocol version 4 and above.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Request>, L<WebSocket::Headers>, L<WebSocket::Common>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut

