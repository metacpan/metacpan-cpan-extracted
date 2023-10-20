##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Message.pm
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
package WebSocket::Common;
BEGIN
{
    use strict;
    use warnings;
    use vars qw(
        $MAX_MESSAGE_SIZE
        %EXPORT_TAGS @EXPORT_OK $VERSION
    );
    use WebSocket qw( WEBSOCKET_DRAFT_VERSION_DEFAULT );
    use parent qw( WebSocket );
    use Digest::MD5 ();
    use HTTP::Status ();
    use MIME::Base64 ();
    use Scalar::Util qw( readonly );
    use WebSocket::Headers;
    use WebSocket::Version;
    our $MAX_MESSAGE_SIZE = 10 * 2048;
    # Either one is ok
    use constant BYTES_RANDOM_SECURE => eval( "require Bytes::Random::Secure;" );
    use constant MATH_RANDOM_SECURE => eval( "require Math::Random::Secure;" );
    # token is (RFC 2616, ASCII)
    # our $HEADER_TOKEN = qr/[\x21\x23-\x27\x2a\x2b\x2d\x2e\x30-\x39\x41-\x5a\x5e-\x7a\x7c\x7e]+/;
    use constant PARSE_DONE         => 0;
    use constant PARSE_INCOMPLETE   => -1;
    use constant PARSE_WAITING      => -2;
    use constant PARSE_MAYBE_MORE   => -3;
    our %EXPORT_TAGS = ( all => [qw( PARSE_DONE PARSE_INCOMPLETE PARSE_WAITING PARSE_MAYBE_MORE WEBSOCKET_DRAFT_VERSION_DEFAULT )] );
    our @EXPORT_OK = qw( PARSE_DONE PARSE_INCOMPLETE PARSE_WAITING PARSE_MAYBE_MORE WEBSOCKET_DRAFT_VERSION_DEFAULT );
    our $VERSION = 'v0.1.0';
};

INIT
{
    require WebSocket::Request;
    require WebSocket::Response;
};

sub init
{
    my $self = shift( @_ );
    # There is no method for this. We use this as internal buffer
    $self->{buffer}         = '' unless( length( $self->{buffer} // '' ) );
    $self->{checksum}       = undef unless( length( $self->{checksum} // '' ) );
    $self->{cookies}        = undef unless( length( $self->{cookies} // '' ) );
    $self->{extensions}     = [] unless( exists( $self->{extensions} ) && length( $self->{extensions} ) );
    $self->{max_message_size} = $MAX_MESSAGE_SIZE unless( length( $self->{max_message_size} // '' ) );
    $self->{protocol}       = '' unless( length( $self->{protocol} // '' ) );
    # Chunk parser
    $self->{state}          = 'blank';
    # <https://datatracker.ietf.org/doc/html/rfc6455#section-1.9>
    $self->{subprotocol}    = [];
    $self->{uri}            = '' unless( length( $self->{uri} // '' ) );
    # $self->{version}        = 'draft-ietf-hybi-17' unless( length( $self->{version} ) );
    $self->{version}        = '' unless( length( $self->{version} // '' ) );
    $self->{_exception_class} = 'WebSocket::Exception' unless( defined( $self->{_exception_class} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $headers = $self->headers;
    unless( $self->version )
    {
        if( $headers->header( 'Sec-WebSocket-Version' )->length &&
            $headers->header( 'Sec-WebSocket-Version' )->match( qr/^\d{1,2}$/ ) )
        {
            my $v = WebSocket::Version->new( $headers->header( 'Sec-WebSocket-Version' )->scalar ) ||
                return( $self->pass_error( WebSocket::Version->error ) );
            $self->version( $v );
        }
        elsif( $headers->header( 'WebSocket-Version' )->length &&
               $headers->header( 'WebSocket-Version' )->match( qr/^\d{1,2}$/ ) )
        {
            my $v = WebSocket::Version->new( $headers->header( 'WebSocket-Version' )->scalar ) ||
                return( $self->pass_error( WebSocket::Version->error ) );
            $self->version( $v );
        }
        else
        {
            my $v = WebSocket::Version->new( WEBSOCKET_DRAFT_VERSION_DEFAULT ) ||
                return( $self->pass_error( WebSocket::Version->error ) );
            $self->version( $v );
        }
    }
    return( $self );
}

sub buffer { return( shift->_set_get_scalar_as_object( 'buffer', @_ ) ); }

sub challenge { return( shift->_set_get_scalar_as_object( 'challenge', @_ ) ); }

sub checksum
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{checksum} = shift( @_ );
        return( $self );
    }
    return( $self->{checksum} ) if( defined( $self->{checksum} ) );
    return( $self->error( "number1 is required" ) )   unless( defined( $self->number1 ) && length( $self->number1 ) );
    return( $self->error( "number2 is required" ) )   unless( defined( $self->number2 ) && length( $self->number2 ) );
    return( $self->error( "challenge is required" ) ) unless( defined( $self->challenge ) && length( $self->challenge ) );

    my $checksum = '';
    $checksum .= pack( 'N' => $self->number1 );
    $checksum .= pack( 'N' => $self->number2 );
    $checksum .= $self->challenge;
    $checksum = Digest::MD5::md5( $checksum );

    return( $self->{checksum} ||= $checksum );
}

# Alias
sub content { return( shift->buffer( @_ ) ); }

sub extensions { return( shift->_set_get_object_array_object( 'extensions', 'WebSocket::Extension', @_ ) ); }

sub headers
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        if( $self->_is_a( $v, 'HTTP::Headers' ) )
        {
            my $h = $v->clone;
            $self->{headers} = bless( $h => 'WebSocket::Headers' );
        }
        elsif( $self->_is_array( $v ) )
        {
            $self->{headers} = WebSocket::Headers->new( @$v );
        }
        else
        {
            return( $self->error( "Bad value for headers. I was expecting either an array reference or a HTTP::Headers object (including WebSocket::Headers) and I got instead '", overload::StrVal( $v ), "'." ) );
        }
    }
    elsif( !$self->{headers} )
    {
        $self->{headers} = WebSocket::Headers->new;
    }
    return( $self->{headers} );
}

sub headers_as_string { return( shift->headers->as_string( @_ ) ) };

sub host { return( shift->headers->header( 'Host', @_ ) ); }

sub is_client_error { return( HTTP::Status::is_client_error( $_[1] ) ); }

sub is_done { return( shift->_set_get_boolean( 'is_done', @_ ) ); }

sub is_error { return( HTTP::Status::is_error( $_[1] ) ); }

sub is_redirect { return( HTTP::Status::is_redirect( $_[1] ) ); }

sub is_server_error { return( HTTP::Status::is_server_error( $_[1] ) ); }

sub is_success { return( HTTP::Status::is_success( $_[1] ) ); }

sub max_message_size { return( shift->_set_get_number( 'max_message_size', @_ ) ); }

sub number1 { return( shift->_set_get_scalar( 'number1', @_ ) ); }

sub number2 { return( shift->_set_get_scalar( 'number2', @_ ) ); }

sub parse_chunk
{
    my( $self, $s ) = @_;
    $s = '' if( !defined( $s ) );
    $self->buffer->append( $s );

    # pre-header blank lines are allowed (RFC 2616 4.1)
    if( $self->{state} eq 'blank' )
    {
        $self->buffer->replace( qr/^(\x0d?\x0a)+/, '' );
        return( PARSE_WAITING ) unless( $self->buffer->length );
        # done with blank lines; fall through
        $self->{state} = 'header';
    }

    # still waiting for the header
    if( $self->{state} eq 'header' )
    {
        # double line break indicates end of header; parse it
        if( my $re = $self->buffer->match( qr/^(.*?)\x0d?\x0a\x0d?\x0a/s ) )
        {
            return( $self->_parse_header_chunk( length( $re->capture->first ) ) );
        }
        # still waiting for unknown amount of header lines
        return( PARSE_WAITING );
    }
    # waiting for main body of request
    elsif( $self->{state} eq 'body' )
    {
        return( $self->_parse_body_chunk() );
    }
    # chunked data
#     elsif( $self->{state} eq 'chunked' )
#     {
#         return( $self->_parse_chunk() );
#     }
    # trailers
    elsif( $self->{state} eq 'trailer' )
    {
        # double line break indicates end of trailer; parse it
        if( my $re = $self->buffer->match( qr/^(.*?)\x0d?\x0a\x0d?\x0a/s ) )
        {
            return( $self->_parse_header_chunk( length( $re->capture->first ), 1 ) );
        }
        # still waiting for unknown amount of trailer data
        return( PARSE_INCOMPLETE );
    }
    return( $self->error( "Unknown state '$self->{state}'" ) );
}

# e.g. HTTP/1.1
sub protocol { return( shift->_set_get_scalar_as_object( 'protocol', @_ ) ); }

sub request { return( shift->_set_get_object( 'request', 'WebSocket::Request', @_ ) ); }

sub response { return( shift->_set_get_object( 'response', 'WebSocket::Response', @_ ) ); }

sub secure { return( shift->_set_get_boolean( 'secure', @_ ) ); }

sub status_message { return( HTTP::Status::status_message( $_[1] ) ); }

# sub subprotocol { return( shift->_set_get_array_as_object( 'subprotocol', @_ ) ); }
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
    }
    return( $self->_set_get_array_as_object( 'subprotocol' ) );
}

sub uri { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub version { return( shift->_set_get_object_without_init( 'version', 'WebSocket::Version', @_ ) ); }

sub _append
{
    my $self = shift( @_ );
    return( $self->pass_error ) if( $self->error );

    # if( ref( $_[0] ) )
    if( $self->_is_object( $_[0] ) && $_[0]->can( 'read' ) )
    {
        $_[0]->read( my $buf, $self->max_message_size );
        $self->buffer->append( $buf );
    }
    else
    {
        $self->buffer->append( $_[0] );
        # NOTE: Emptying implicitly the caller's variable passed is very bad design
        # It is up to the caller to decide of the content of its variable, not us.
        # This makes for head-scratching troubles and is a way of doing never used in perl
        # The only time when the caller's variable content is modified is with perl's read() or sysread()
        # and this is an explicit, well documented and optional feature
        # $_[0] = '' unless( readonly( $_[0] ) );
    }

    if( $self->buffer->length > $self->max_message_size )
    {
        return( $self->error( "Message is too long" ) );
    }
    return( $self );
}

sub _extract_number
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    my $number = join( '' => $key =~ m/\d+/g );
    my $spaces = $key =~ s/ / /g;
    return if( $spaces == 0 );
    return( int( $number / $spaces ) );
}

sub _generate_16bit_nonce
{
    my $self = shift( @_ );
    my $rand = '';
    if( BYTES_RANDOM_SECURE )
    {
        $rand = Bytes::Random::Secure::random_bytes_base64(16, '');
    }
    elsif( MATH_RANDOM_SECURE )
    {
        $rand .= chr( Math::Random::Secure::irand(256) ) for( 1 .. 16 );
        $rand = MIME::Base64::encode_base64( $rand, '' );
    }
    else
    {
        $rand .= chr( int( rand(256) ) ) for( 1 .. 16 );
        $rand = MIME::Base64::encode_base64( $rand, '' );
    }
    return( $rand );
}

sub _parse_body_chunk
{
    my $self = shift( @_ );
    $self->{obj}->content( $self->buffer->scalar );
    # $self->{buffer} = '';
    $self->buffer->empty;
    # return( $self->{obj} );
    return( PARSE_DONE );
}

sub _parse_header_chunk
{
    my( $self, $eoh, $trailer ) = @_;
    my $header = $self->buffer->substr( 0, $eoh, '' );
    $self->buffer->replace( qr/^\x0d?\x0a\x0d?\x0a/, '' );

    # parse into lines
    my $headers = $header->split( qr/\x0d?\x0a/ );
    my $request = $headers->shift unless( $trailer );

    # join folded lines
    my @out;
    for( @$headers )
    {
        if( s/^[ \t]+// )
        {
            return( $self->error( 'Linear white space on first header line' ) ) unless( @out );
            $out[-1] .= $_;
        }
        else
        {
            push( @out, $_ );
        }
    }

    # parse request or response line
    my( $obj, $req, $res );
    unless( $trailer )
    {
        my( $major, $minor );
        # is it an HTTP response?
        if( $request =~ /^HTTP\/(\d+)\.(\d+)/i )
        {
            ( $major, $minor ) = ( $1, $2 );
            $request =~ /^HTTP\/\d+\.\d+ (\d+) (.+)$/;
            my $state = $1;
            my $msg = $2;
            $res = $obj = $self->{obj} = WebSocket::Response->new( $state, $msg );
            # perhaps a request?
            $self->response( $res );
        }
        else
        {
            my( $method, $uri, $http ) = split( / /, $request );
            unless( $http and $http =~ /^HTTP\/(\d+)\.(\d+)$/i )
            {
                return( $self->error( "'$request' is not the start of a valid HTTP request or response" ) );
            }
            ( $major, $minor ) = ( $1, $2 );

            # If the Request-URI is an abs_path, we need to tell URI that we don't
            # know the scheme, otherwise it will misinterpret paths that start with
            # // as being scheme-relative uris, and will interpret the first
            # component after // as the host (see rfc 2616)
            $uri = "//$uri" if( $uri =~ m(^/) );
            $req = $obj = $self->{obj} = WebSocket::Request->new( method => $method, uri => $uri );
            $self->request( $req );
        }
        # pseudo-header
        # $obj->header( X_HTTP_Version => "$major.$minor" );
    }
    # we've already seen the initial line and created the object
    else
    {
        $obj = $self->{obj};
    }

    # import headers
    my $token = qr/[^][\x00-\x1f\x7f()<>@,;:\\"\/?={} \t]+/;
    for $header( @$headers )
    {
        return( $self->error( "Bad header name in '$header'" ) ) unless( $header =~ s/^($token):[\t ]*// );
        $obj->headers->push_header( $1 => $header );
    }
    # if we're parsing trailers we don't need to look at content
    return( $obj ) if( $trailer );

    $self->{state} = 'body';
    return( $self->_parse_body_chunk() );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Message - Common Class for Request and Response

=head1 SYNOPSIS

    use WebSocket::Request;
    my $req = WebSocket::Request->new(
        host        => 'example.com',
        uri         => '/demo'
        protocol    => 'com.example.chat',
    ) || die( WebSocket::Request->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a common class for L<WebSocket::Request> and L<WebSocket::Response>

=head1 METHODS

=head2 buffer

Sets or gets the buffer. It returns a L<scalar object|Module::Generic::Scalar>

=head2 challenge

Sets or gets the challenge returned to the client. 

=head2 checksum

Sets or gets the checksum. If a checksum is provided, it returns the current object.

If no checksum is provided, it will compute one based on the value of L</number1>, L</number2> and L</challenge>. It returns the checksum as a regular string.

=head2 content

Alias for L</buffer>

=head2 extensions

Set or get the available extensions. For example C<permessage-deflate> to enable message compression.

You can set this to either a string or a L<WebSocket::Extension> object if you want, for example to set the extension parameters.

See L<rfc6455 section 9.1|https://datatracker.ietf.org/doc/html/rfc6455#section-9.1> for more information on extension.

=head2 headers

If an argument is provided, it takes either an L<WebSocket::Headers> object, or an object that inherits from L<HTTP::Headers>, or an array reference.

It returns a L<WebSocket::Headers> and will instantiate a L<WebSocket::Headers> object if one is not already set.

=head2 headers_as_string

Returns the L<WebSocket::Headers> as a string by calling L<WebSocket::Headers/as_string>

=head2 host

Sets or gets the header value for C<Host>

=head2 is_client_error

Returns true if the error code provided is a client error.

=head2 is_done

Returns true when the parsing is done.

=head2 is_error

Returns true when the provided code is an error

=head2 is_redirect

Returns true when the provided code is a redirect, which under the WebSocket is possible during the handshake only.

=head2 is_server_error

Returns true when the provided code is a server error.

=head2 is_success

Returns true when the provided code is a success

=head2 max_message_size

Sets or gets the maximum message size as an integer.

=head2 number1

This is a default method to store a number used for the checksum challenge sent to the client.

This method is overriden by L<WebSocket::Request> or L<WebSocket::Response>

=head2 number2

This is a default method to store a number used for the checksum challenge sent to the client.

This method is overriden by L<WebSocket::Request> or L<WebSocket::Response>

=head2 parse_chunk

Provided with some chunk data, and this will parse it and return a status. See L</CONSTANTS> below.

Once parsing is done, you can retrieve the relevant object with L</request> which returns a L<WebSocket::Request> object or L</response> which returns a L<WebSocket::Response> object.

If an error occurs, this will returns C<undef> and sets an L<error|Module::Generic/error> L<exception|WebSocket::Exception>

=head2 protocol

Returns the http protocol used, which should always be C<HTTP/1.1>

=head2 request

Set or get a L<WebSocket::Request> object. This is set by L</parse_chunk>

=head2 response

Set or get a L<WebSocket::Response> object. This is set by L</parse_chunk>

=head2 secure

Boolean value. True when the connection is using ssl, false otherwise.

=head2 status_message

Returns the status message provided by the other party.

=head2 subprotocol

Set or get an array object of WebSocket protocols.

Returns a L<Module::Generic::Array> object.

See L<rfc6455 for more information|https://datatracker.ietf.org/doc/html/rfc6455#page-12>

=head2 uri

Set or get the uri of the current request or response. Returns a L<URI> object.

=head2 version

Set or get the WebSocket version supported.

=head1 PRIVATE METHODS

=head2 _append

Provided with some data, or a L<IO::Socket> object, and this will add the data to the current buffer (I<buffer>), or issue a C<read> call on the L<IO::Socket> object and read L</max_message_size> bytes of data.

If the resulting I<buffer> exceeds L</max_message_size>, this will return C<undef> and sets an L<error|Module::Generic/error> object, so you need to check that the size of the current buffer + the data you provide doe snot exceed the value of L</max_message_size>

=head2 _extract_number

Provided with some value and this will extract any digit, count the number of spaces and return an integer of the number extracted divided by the number of spaces found.

This is called by the methods L</number1> and L</number2>

=head1 CONSTANTS

The following constants are available and can be exported into your name space either individually, or by using the tag C<:all>

=over 4

=item PARSE_DONE

Returned by L</parse_chunk> when the parsing is done.

=item PARSE_INCOMPLETE

Returned by L</parse_chunk> when the parsing is incomplete.

=item PARSE_WAITING

Returned by L</parse_chunk> when the parsing is ongoing and the double line end of header separator has not yet been reached.

=item PARSE_MAYBE_MORE

Returned by L</parse_chunk> to indicate that maybe more data is expected.

=back

=head1 CREDITS

Credits to David Robins for code borrowed from L<HTTP::Parser> for chunk parsing

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Request>, L<WebSocket::Response>, L<HTTP::Headers>, L<HTTP::Parser>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut

