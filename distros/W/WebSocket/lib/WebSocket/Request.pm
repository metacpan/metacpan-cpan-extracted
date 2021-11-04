##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Request.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/16
## Modified 2021/09/16
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Request;
BEGIN
{
    use strict;
    use warnings;
    use WebSocket::Common qw( :all );
    use parent qw( WebSocket::Common );
    use Digest::MD5 ();
    use HTTP::Request ();
    use MIME::Base64 ();
    use Nice::Try;
    use Scalar::Util qw( readonly );
    use WebSocket::Extension;
    use WebSocket::Headers;
    use WebSocket::Version;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my( $headers, $buffer );
    if( @_ && 
        ( $self->_is_array( $_[0] ) || $self->_is_a( $_[0], 'HTTP::Headers' ) ) )
    {
        $headers = shift( @_ );
        if( $self->_is_a( $headers, 'HTTP::Headers' ) )
        {
            $headers = $headers->clone;
            $headers = bless( $headers => 'WebSocket::Headers' );
        }
        else
        {
            $headers = WebSocket::Headers->new( @$headers );
        }
        # $req->new( $headers, $buffer, k1 => v1, k2 => v2);
        # $req->new( $headers, $buffer, { k1 => v1, k2 => v2 });
        # $req->new( $headers, k1 => v1, k2 => v2);
        # $req->new( $headers, { k1 => v1, k2 => v2 });
        if( ( ( @_ % 2 ) && ref( $_[1] ) ne 'HASH' ) || 
            ref( $_[1] ) eq 'HASH' )
        {
            $buffer = shift( @_ );
        }
    }
    $self->{buffer}         = $buffer;
    $self->{headers}        = $headers;
    $self->{method}         = '';
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order}   = [qw( buffer headers )];
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $eol  = shift( @_ ) || "\x0d\x0a";

    my $version = $self->version || WebSocket::Version->new( WEBSOCKET_DRAFT_VERSION_DEFAULT );
    return( $self->error( "uri is required" ) ) unless( defined( $self->uri ) );
    return( $self->error( "Host is required" ) ) unless( $self->host->defined && $self->host->length );
    $self->message( 3, "Version is '$version', revision '", $version->revision, "' and subprotocol is '", $self->subprotocol->join( ',' )->scalar, "'." );
    my $req_line = "GET " . ( $self->uri->path_query || '/' ) . " HTTP/1.1";
    my $h = $self->headers;
    $h->header( Upgrade => 'WebSocket', Connection => Upgrade );
    if( $self->cookies->length )
    {
        $h->header( Cookie => $self->cookies->scalar );
    }
    my $origin = $self->origin ? $self->origin : 'http://' . $self->host;
    $origin =~ s{^http:}{https:} if( $self->secure );
    # Version 10 or lower; From version 11, it uses 'Origin' only; but from version 0 to 3, it uses also Origin
    if( $version->type eq 'hybi' &&
        ( $version->revision >= 4 && $version->revision <= 10 ) )
    {
        $h->header( 'Sec-WebSocket-Origin' => $origin );
    }
    else
    {
        $h->header( Origin => $origin );
    }
    
    if( $version->type eq 'hybi' && $version->revision >= 4 )
    {
        my $key = $self->key;
        if( !$key )
        {
            $key = $self->_generate_16bit_nonce();
        }
        
        # rfc6455, section 4.1 §10 <https://datatracker.ietf.org/doc/html/rfc6455#section-4.1>
        # "If present, this value indicates one or more comma-separated subprotocol the client wishes to speak, ordered by preference."
        if( $self->subprotocol->length )
        {
            $h->header( 'Sec-WebSocket-Protocol' => $self->subprotocol->join( ',' )->scalar );
        }
        $h->header( 'Sec-WebSocket-Key' => $key );
        # $h->header( 'Sec-WebSocket-Version' => ( $version eq 'draft-ietf-hybi-17' ? 13 : 8 ) );
        $h->header( 'Sec-WebSocket-Version' => "$version" );
    }
    # Otherwise from hybi version 0 to 3 there is no version request header
    elsif( $version->type eq 'hybi' || 
           ( $version->type eq 'hixie' && $version->revision == 76 ) )
    {
        $self->_generate_keys;
        # Up to version HyBi 04, subprotocol are separated by a space
        if( $self->subprotocol->length )
        {
            $h->header( 'Sec-WebSocket-Protocol' => $self->subprotocol->join( ' ' )->scalar );
        }
        $h->header( 'Sec-WebSocket-Key1' => $self->key1 );
        $h->header( 'Sec-WebSocket-Key2' => $self->key2 );
        $h->header( 'Content-Length' => length( $self->challenge ) );
    }
    elsif( $version->type eq 'hixie' )
    {
        # Up to version HyBi 04, subprotocol are separated by a space
        $h->header( 'WebSocket-Protocol' => $self->subprotocol->join( ' ' )->scalar ) if( $self->subprotocol->length );
    }
    else
    {
        return( $self->error( 'Version ' . $self->version . ' is not supported' ) );
    }
    
    return(
        join(
            '',
            $req_line,
            $eol,
            $self->headers->as_string( $eol ),
            $eol,
            ( $version eq 'draft-ietf-hybi-00' ? $self->challenge : '' )
        )
    );
}

sub connection { return( shift->headers->header( 'Connection', @_ ) ); }

sub cookies { return( shift->_set_get_scalar_as_object( 'cookies', @_ ) ); }

sub key  { return( shift->_key( key  => @_ ) ); }

sub key1 { return( shift->_key( key1 => @_ ) ); }

sub key2 { return( shift->_key( key2 => @_ ) ); }

sub method { return( shift->_set_get_scalar_as_object( 'method', @_ ) ); }

sub number1 { return( shift->_number( 'number1', 'key1', @_ ) ); }

sub number2 { return( shift->_number( 'number2', 'key2', @_ ) ); }

# XXX Need to improve this and set the right header based on the version set
# sub origin { return( shift->headers->header( 'Origin', @_ ) ); }
sub origin
{
    my $self = shift( @_ );
    my $h = $self->headers;
    if( @_ )
    {
        # Based on our version, we set the right header
        my $v = $self->version;
        # $self->message( 3, "Setting origin '$_[0]' for client version $v" );
        if( $v && $v->type eq 'hybi' && $v->revision >= 4 && $v->revision <= 10 )
        {
            $h->header( 'Sec-WebSocket-Origin' => shift( @_ ) );
        }
        elsif( $v && 
               $v->type eq 'hybi' && 
               (
                   ( $v->revision >= 0 && $v->revision <= 3 ) ||
                   ( $v->revision >= 11 && $v->revision <= 17 )
               ) )
        {
            # $self->message( 3, "Setting origin for client with header 'Origin' and value '$_[0]'" );
            $h->header( 'Origin' => shift( @_ ) );
        }
    }
    return( $h->header( 'Origin' ) || $h->header( 'Sec-WebSocket-Origin' ) );
}

sub parse
{
    my $self = shift( @_ );
    my $req;
    try
    {
        return(1) unless( defined( $_[0] ) );
        # Add data to buffer
        $self->_append( @_ ) || return( $self->pass_error );
        my $re;
        unless( $re = $self->buffer->match( qr/^(?<method>\w+)[[:blank:]\h]+(?<uri>\S+)[[:blank:]\h]+(?<proto>HTTP\/\d+\.\d+)/ ) )
        {
            return( $self->error( "Wrong request line" ) );
        }
        unless( $re->name->method eq 'GET' && $re->name->proto eq 'HTTP/1.1' )
        {
            return( $self->error( "Wrong method or http version" ) );
        }
        $req = HTTP::Request->parse( $self->buffer->scalar );
        $self->method( $req->method );
        $self->uri( $req->uri );
        $self->protocol( $req->protocol );
        $self->headers( $req->headers );
        # The rest is the body
        $self->buffer( $req->content );
    }
    catch( $e )
    {
        return( $self->error( "Error parsing request data: $e" ) );
    }
    # Used in both parse() and parse_chunk()
    return( $self->parse_body );
}

sub parse_body
{
    my $self = shift( @_ );
    # Check body
    if( $self->key1 && $self->key2 )
    {
        return(1) if( $self->buffer->length < 8 );

        my $challenge = $self->buffer->substr( 0, 8, '' );
        $self->challenge( $challenge );
    }
    return( $self->error( "Excessive unknown data found in request body: ", $self->buffer->scalar ) ) if( $self->buffer->length );
    $self->is_done(1);
    
    $self->message( 3, "Key is '", $self->key, "', key1 is '", $self->key1, "' and key2 is '", $self->key2, "'." );
    if( !$self->{_parse_postprocessed} && $self->is_done )
    {
        $self->{_parse_postprocessed} = 1;
        if( $self->key1 && $self->key2 )
        {
            # $self->version( 'draft-ietf-hybi-00' );
            # Latest draft revision that uses key1 and key2
            $self->version( 'draft-ietf-hybi-03' );
        }
        elsif( $self->key )
        {
            if( $self->headers->header( 'Sec-WebSocket-Version' ) )
            {
                $self->version( $self->headers->header( 'Sec-WebSocket-Version' )->scalar );
            }
            # XXX Since there is no Sec-WebSocket-Version in request, maybe we should set
            # the version to draft protocol revision 3 or earlier when there was no 
            # Sec-WebSocket-Version header?
            else
            {
                # $self->version( 'draft-ietf-hybi-10' );
                $self->version( WEBSOCKET_DRAFT_VERSION_DEFAULT );
            }
        }
        else
        {
            $self->version( 'draft-hixie-75' );
        }

        if( !$self->_parse_postprocess )
        {
            return( $self->error( 'Not a valid request: ', $self->error ) );
        }
    }
    $self->message( 3, "Version set to '", $self->version, "' (", $self->version->draft, ")." );
    return( $self );
}

sub upgrade { return( shift->headers->header( 'Upgrade', @_ ) ); }

sub _generate_keys
{
    my $self = shift( @_ );

    unless( $self->key1 )
    {
        my( $number, $key ) = $self->_generate_key;
        $self->number1( $number );
        $self->key1( $key );
    }

    unless( $self->key2 )
    {
        my( $number, $key ) = $self->_generate_key;
        $self->number2( $number );
        $self->key2( $key );
    }
    $self->challenge( $self->_generate_challenge ) unless( $self->challenge );
    return( $self );
}

sub _generate_key
{
    my $self = shift( @_ );

    # A random integer from 1 to 12 inclusive
    my $spaces = int( rand(12) ) + 1;

    # The largest integer not greater than 4,294,967,295 divided by spaces
    my $max = int( 4_294_967_295 / $spaces );

    # A random integer from 0 to $max inclusive
    my $number = int( rand( $max + 1 ) );

    # The result of multiplying $number and $spaces together
    my $product = $number * $spaces;

    # A string consisting of $product, expressed in base ten
    my $key = "$product";

    # Insert between one and twelve random characters from the ranges U+0021
    # to U+002F and U+003A to U+007E into $key at random positions.
    my $random_characters = int( rand(12) ) + 1;

    for( 1 .. $random_characters )
    {
        # From 0 to the last position
        my $random_position = int( rand( length( $key ) + 1 ) );

        # Random character
        my $random_character = chr(
              int( rand(2) )
            ? int( rand( 0x2f - 0x21 + 1 ) ) + 0x21
            : int( rand( 0x7e - 0x3a + 1 ) ) + 0x3a
        );

        # Insert random character at random position
        substr( $key, $random_position, 0, $random_character );
    }

    # Insert $spaces U+0020 SPACE characters into $key at random positions
    # other than the start or end of the string.
    for( 1 .. $spaces )
    {
        # From 1 to the last-1 position
        my $random_position = int( rand( length( $key ) - 1 ) ) + 1;

        # Insert
        substr( $key, $random_position, 0, ' ' );
    }
    return( $number, $key );
}

sub _generate_challenge
{
    my $self = shift( @_ );
    # A string consisting of eight random bytes (or equivalently, a random 64
    # bit integer encoded in big-endian order).
    my $challenge = '';

    $challenge .= chr( int( rand(256) ) ) for( 1 .. 8 );
    return( $challenge );
}

sub _key
{
    my $self  = shift( @_ );
    my $name  = shift( @_ ) || return( $self->error( "No Sec-WebSocket header name was provided" ) );
    my $hname = 'Sec-WebSocket-' . ucfirst( lc( $name ) );
    if( @_ )
    {
        my $val = shift( @_ );
        if( !defined( $val ) )
        {
            $self->headers->remove_header( $hname );
        }
        else
        {
            $self->headers->header( $hname => $val );
        }
    }
    return( $self->headers->header( $hname ) );
}

sub _number
{
    my $self = shift( @_ );
    my( $name, $key, $value ) = @_;

    if( defined( $value ) )
    {
        $self->{ $name}  = $value;
        return( $self );
    }
    return( $self->{ $name } ) if( defined( $self->{ $name } ) );
    return( $self->{ $name } ||= $self->_extract_number( $self->$key ) );
}

# Called from parse_chunk()
sub _parse_body_chunk
{
    my $self = shift( @_ );
    my $req  = $self->SUPER::_parse_body_chunk;
    $self->method( $req->method );
    $self->uri( $req->uri );
    $self->protocol( $req->protocol );
    $self->headers( $req->headers );
    # The rest is the body
    $self->buffer( $req->content );
    # Used in both parse() and parse_chunk()
    return( $self->parse_body );
}

sub _parse_postprocess
{
    my $self = shift( @_ );
    $self->message( 3, "Upgrade header is '", $self->upgrade->lc, "'" );
    return( $self->error( "No upgrade header or its value is not \"WebSocket\"." ) ) unless( $self->upgrade->lc eq 'websocket' );

    my $connection = $self->connection;
    $self->message( 3, "Connection header is '", $self->connection, "' (", overload::StrVal( $connection ), ")." );
    return( $self->error( "No \"Connection\" header" ) ) unless( $connection->length );
    
    my $connections = $connection->split( qr/[[:blank:]\h]*\,[[:blank:]\h]*/ );
    return( $self->error( "Connection header has no \"Upgrade\" value." ) ) unless( $connections->grep(sub{ lc( $_ ) eq 'upgrade' })->length );
    my $origin = $self->headers->header( 'Sec-WebSocket-Origin' ) || $self->headers->header( 'Origin' );
    $self->message( 3, "Client origin provided is '$origin'" );
    $self->origin( $origin );
    if( $origin->length )
    {
        $self->secure(1) if( $origin->match( qr/^https:/i ) );
    }
    my $host = $self->host;
    return( $self->error( "No \"Host\" header value found." ) ) unless( $host->length );
    # $self->host($host);

    my $subprotocol = $self->headers->header( 'Sec-WebSocket-Protocol' ) || 
                      $self->headers->header( 'WebSocket-Protocol' );
    $self->message( 3, "Subprotocol value found from header is '$subprotocol'" );
    my $v = $self->version;
    # rfc6455, section 4.1: multiple values are comma separated
    # XXX Careful. If version is < HyBi 04 subprotocol are separated by a space, not by a comma
    if( $subprotocol->length )
    {
        if( $subprotocol->index( ',' ) != -1 )
        {
            $self->subprotocol( $subprotocol->split( qr/[[:blank:]\h]*\,[[:blank:]\h]*/ ) );
        }
        # version older than draft hybi revision 4
        else
        {
            $self->subprotocol( $subprotocol->split( qr/[[:blank:]\h]+/ ) );
            if( $v->type eq 'hybi' && $v->revision > 3 )
            {
                $v = $self->version(2) || return( $self->pass_error );
            }
        }
    }
    
    if( $v->type eq 'hybi' && $v->revision >= 4 )
    {
        my $extensions = $self->headers->header( 'Sec-WebSocket-Extensions' );
        if( $extensions->length )
        {
            # Returns a Module::Generic::Array of WebSocket::Extension objects
            my $ref = WebSocket::Extension->new_from_multi( $extensions->scalar ) ||
                return( $self->pass_error( WebSocket::Extension->error ) );
            $self->extensions( $ref );
        }
    }
    
    $self->cookies( $self->headers->header( 'Cookie' ) );
    return( $self );
}

1;

# XXX POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Request - WebSocket Request

=head1 SYNOPSIS

    use WebSocket::Request;
    my $req = WebSocket::Request->new(
        host        => 'example.com',
        uri         => '/demo'
        protocol    => 'com.example.chat',
    ) || die( WebSocket::Request->error, "\n" );
    # or
    my $req = WebSocket::Request->new( $headers, $buffer, host => 'example.com', origin => 'https://example.com');
    my $req = WebSocket::Request->new( $headers, $buffer, { host => 'example.com', origin => 'https://example.com' });
    my $req = WebSocket::Request->new( $headers, host => 'example.com', origin => 'https://example.com');
    my $req = WebSocket::Request->new( $headers, { host => 'example.com', origin => 'https://example.com' });
    $req->as_string;
    # GET /demo HTTP/1.1
    # Upgrade: WebSocket
    # Connection: Upgrade
    # Host: example.com
    # Origin: http://example.com
    # Sec-WebSocket-Key1: 32 0  3lD& 24+<    i u4  8! -6/4
    # Sec-WebSocket-Key2: 2q 4  2  54 09064
    # Set-WebSocket-Version: 13
    #
    # x#####

    # Parser
    my $req = WebSocket::Request->new;
    $req->parse( <<EOT );
    GET /demo HTTP/1.1
    Upgrade: WebSocket
    Connection: Upgrade
    Host: example.com
    Origin: http://example.com
    Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8
    Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0
    Set-WebSocket-Version: 13
    
    Tm[K T2u
    EOT

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Class to build or parse a WebSocket request. It inherits all the methods from L<WebSocket::Common>. For convenience, they are all listed here.

=head1 CONSTRUCTOR

=head2 new

    my $req = WebSocket::Request->new( $headers, $buffer,
        uri => 'wss://example.com/chat',
        subprotocol => 'com.example.chat'
    );
    my $req = WebSocket::Request->new( $headers, $buffer, {
        uri => 'wss://example.com/chat',
        subprotocol => 'com.example.chat'
    });
    my $req = WebSocket::Request->new( $headers,
        uri => 'wss://example.com/chat',
        subprotocol => 'com.example.chat'
    );
    my $req = WebSocket::Request->new( $headers, {
        uri => 'wss://example.com/chat',
        subprotocol => 'com.example.chat'
    });

Provided with an optional set of headers, as either an array reference or a L<HTTP::Headers> object, some optional content and an hash or hash reference of parameters, and this instantiates a new L<WebSocket::Request> object. The supported parameters are as follow. Each parameter can be set or changed later using the method with the same name:

=over 4

=item I<buffer>

Content buffer

=item I<cookies>

A C<Cookie> request header string. The string provided must be already properly formatted and encoded and will be added as is. For example:

    WebSocket::Request->new(
        cookies => q{lang=en-GB; access_token=eyJwMnMiOiJtaGpZQ3ZqeHZ3TVJrTFY1WGREaHJ3jiwiZXhwIjoxNjMxOTQ5NTc5LCJwMmMiOjUwMDAsImFsZyI6IlBCRVMyLUhTMjy2K0ExMjhLVyIsImVuYyI6IkExMjhlQ00ifQ.E522SASh8v_TIwVLO4RmIS3D76iO0Lqr.29IifZxeNjEoqRjw.x5_em7jOCABhXRJKN8-IFk0YLLXPGZecmWJujQxmTzgaCf9y-6AZhzRWoIfwUkjeZvqfTwvUJwrcHxePznJ7_HYCLUmEjRgHJMQ0c9OBStSJhSSKYtzwR3J3N_PpmcdEtWRWN1SPlnHp9aoLHHgmBSKQpuqNb9Rdkw7-XhAyznx9bMEehZUae1rmBtNRzlGtKyInBUF9iv03zETrCkdfVt2-0IGkkQ.qMayqY2qoKybazs6pntIpw},
        host    => 'example.com'
    );

=item I<headers>

Either an array reference of header-value pairs, or an L<HTTP::Headers> object.

If an array reference is provided, an L<HTTP::Headers> object will be instantiated with it.

=item I<host>

The C<Host> header value.

=item I<max_message_size>

Integer. Defaults to 20Kb. This is the maximum payload size.

=item I<number1>

=item I<number2>

=item I<origin>

The C<Origin> header value.

See L<rfc6454|https://datatracker.ietf.org/doc/html/rfc6454>

=item I<protocol>

HTTP/1.1. This is the only version supported by L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455>

=item I<secure>

Boolean. This is set to true when the connection is using ssl (i.e. C<wss>), false otherwise.

=item I<subprotocol>

The optional subprotocol which consists of multiple arbitrary identifiers that need to be recognised and supported by the server.

    WebSocket::Request->new(
        subprotocol => 'com.example.chat',
    );
    # or
    WebSocket::Request->new(
        subprotocol => [qw( com.example.chat com.example.internal )],
    );

See L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

=item I<uri>

The request uri, such as C</chat> or it could also be a fully qualified uri such as C<wss://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571>

=item I<version>

The WebSocket protocol version. Defaults to C<draft-ietf-hybi-17>

See L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455#page-26>

=back

=head1 METHODS

=head2 as_string

Provided with an optional line terminator and this returns a string version of the request, based on all the parameters set in the object.

=head2 buffer

Set or get the content buffer.

=head2 challenge

=head2 checksum

=head2 connection

Set or get the C<Connection> header value, which should typically be C<Upgrade>. 

=head2 cookies

Set or get the cookies string to be used in the C<Cookie> request header.

=head2 headers

Set or get the L<HTTP::Headers> object. If none is set, and this method is accessed, a new one will be instantiated.

=head2 headers_as_string

Calls C<as_string> on L<HTTP::Headers> and returns its value.

=head2 host

Set or get the C<Host> header value.

=head2 is_done

Set or get the boolean value. This is set to signal the parsing is complete.

=head2 key

=head2 key1

=head2 key2

=head2 method

The http method used, such as C<GET>

=head2 number1

=head2 number2

=head2 origin

Set or get the C<Origin> header value.

See L<rfc6455 section 1.3for more information|https://datatracker.ietf.org/doc/html/rfc6455#section-1.3> and L<section 4.1, paragraph 8|https://datatracker.ietf.org/doc/html/rfc6455#section-4.1>

=head2 parse

    my $rv = $req->parse( $some_request_data ) ||
        die( $req->error );

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

=head2 subprotocol

Set or get an array object (L<Module::Generic::Array>) of subprotocols.

See L<rfc6455 for more information|https://datatracker.ietf.org/doc/html/rfc6455>

=head2 upgrade

Set or get the C<Upgrade> request header value, which should typically be C<websocket>

=head2 uri

Set or get the request uri. This returns a L<URI> object.

=head2 version

Set the protocol version.

See L<rfc6455 section 4.1 for more information|https://datatracker.ietf.org/doc/html/rfc6455#section-4.4>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.



=cut

