##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket.pm
## Version v0.1.5
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/13
## Modified 2021/10/23
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    # <https://datatracker.ietf.org/doc/html/rfc6455#section-7.4.1>
    use constant WS_OK                      => 1000;
    use constant WS_GONE                    => 1001;
    use constant WS_PROTOCOL_ERROR          => 1002;
    use constant WS_NOT_ACCEPTABLE          => 1003;
    # 1004 is reserved and undefined
    use constant WS_NO_STATUS               => 1005;
    use constant WS_CLOSED_ABNORMALLY       => 1006;
    # 1007 indicates that an endpoint is terminating the connection	
    # because it has received data that was supposed to be UTF-8 (such	
    # as in a text frame) that was in fact not valid UTF-8 [RFC3629].
    use constant WS_BAD_MESSAGE             => 1007;
    use constant WS_FORBIDDEN               => 1008;
    use constant WS_MESSAGE_TOO_LARGE       => 1009;
    use constant WS_EXTENSIONS_NOT_AVAILABLE   => 1010;
    use constant WS_INTERNAL_SERVER_ERROR   => 1011;
    # Nothing defined for 1012, 1013 and 1014 yet as of 2021-09-14
    use constant WS_TLS_HANDSHAKE_FAIL      => 1015;
    use constant WEBSOCKET_DRAFT_VERSION_DEFAULT => 'draft-ietf-hybi-17';
    # 10kb
    use constant WEBSOCKET_COMPRESSION_THRESHOLD => 10240;
    our %EXPORT_TAGS = ( all => [qw( WS_OK WS_GONE WS_PROTOCOL_ERROR WS_NOT_ACCEPTABLE WS_NO_STATUS WS_CLOSED_ABNORMALLY WS_BAD_MESSAGE WS_FORBIDDEN WS_MESSAGE_TOO_LARGE WS_EXTENSIONS_NOT_AVAILABLE WS_INTERNAL_SERVER_ERROR WS_TLS_HANDSHAKE_FAIL WEBSOCKET_DRAFT_VERSION_DEFAULT )] );
    $EXPORT_TAGS{ws} = $EXPORT_TAGS{all};
    our @EXPORT_OK = qw( WS_OK WS_GONE WS_PROTOCOL_ERROR WS_NOT_ACCEPTABLE WS_NO_STATUS WS_CLOSED_ABNORMALLY WS_BAD_MESSAGE WS_FORBIDDEN WS_MESSAGE_TOO_LARGE WS_EXTENSIONS_NOT_AVAILABLE WS_INTERNAL_SERVER_ERROR WS_TLS_HANDSHAKE_FAIL WEBSOCKET_DRAFT_VERSION_DEFAULT );
    our $VERSION = 'v0.1.5';
};

sub init
{
    my $self = shift( @_ );
    $self->{compression_threshold}  = WEBSOCKET_COMPRESSION_THRESHOLD unless( defined( $self->{compression_threshold} ) && length( $self->{compression_threshold} ) );
    $self->{_init_strict_use_sub} = 1;
    $this->{_exception_class} = 'WebSocket::Exception';
    $self->SUPER::init( @_ );
    return( $self );
}

sub client
{
    my $self = shift( @_ );
    require WebSocket::Client;
    return( WebSocket::Client->new( @_ ) );
}

sub compression_threshold { return( shift->_set_get_number( 'compression_threshold', @_ ) ); }

sub server
{
    my $self = shift( @_ );
    require WebSocket::Server;
    return( WebSocket::Server->new( @_ ) );
}

{
    package
        WebSocket::Exception;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic::Exception );
    };
}

1;

# XXX POD
__END__

=head1 NAME

WebSocket - WebSocket Client & Server

=head1 SYNOPSIS

    use WebSocket qw( :ws ); # exports standard codes as constant

=head1 VERSION

    v0.1.5

=head1 DESCRIPTION

This is the client (L<WebSocket::Client>) and server (L<WebSocket::Server>) implementation of WebSocket api. It provides a comprehensive well documented and hopefully easy-to-use implementation.

Also, this api, by design, does not die, but rather returns C<undef> and set an L<WebSocket::Exception> that can be retrieved with the inherited L<Module::Generic/error> method.

It is important to always check the return value of a method. If it returns C<undef> and unless this means something else, by default it means an error has occurred and you can retrieve it with the L<error|Module::Generic/error> method. If you fail to check return values, you are in for some trouble. If you would rather have error be fatal, you can instantiate objects with the option I<fatal> set to a true value.

Most of methods here allows chaining.

You can also find a JavaScript WebSocket client library in this distribution under the C<example> folder. The JavaScript library also has a pod documentation.

=head1 CONSTRUCTOR

=head2 new

Create a new L<WebSocket> object acting as an accessor.

One object should be created per po file, because it stores internally the po data for that file in the L<Text::PO> object instantiated.

Returns the object.

=head1 METHODS

=head2 client

Convenient shortcut to instantiate a new L<WebSocket::Client> object, passing it whatever argument was provided.

=head2 compression_threshold

Set or get the threshold in bytes above which the ut8 or binary messages will be compressed if the client and the server support compression and it is activated as an extension.

See L<WebSocket::Client/extensions> and L<WebSocket::Server/extensions>.

=head2 server

Convenient shortcut to instantiate a new L<WebSocket::Server> object, passing it whatever argument was provided.

=head1 CONSTANTS

The following constants are available, but not exported by default. You can import them into your namespace using either the tag C<:ws> or C<:all>, such as:

    use WebSocket qw( :ws );

=head2 WS_OK

Code C<1000>. 

The default, normal closure (used if no code supplied),

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1000 indicates a normal closure, meaning that the purpose for which the connection was established has been fulfilled."

=head2 WS_GONE

Code C<1001>

The party is going away, e.g. server is shutting down, or a browser leaves the page.

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1001 indicates that an endpoint is "going away", such as a server going down or a browser having navigated away from a page."

=head2 WS_PROTOCOL_ERROR

Code C<1002>

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1002 indicates that an endpoint is terminating the connection due to a protocol error."

=head2 WS_NOT_ACCEPTABLE

Code C<1003>

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1003 indicates that an endpoint is terminating the connection because it has received a type of data it cannot accept (e.g., an endpoint that understands only text data MAY send this if it receives a binary message)."

=head2 WS_NO_STATUS

Code C<1005>

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1005 is a reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. It is designated for use in applications expecting a status code to indicate that no status code was actually present."

=head2 WS_CLOSED_ABNORMALLY

Code C<1006>

No way to set such code manually, indicates that the connection was lost (no close frame).

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1006 is a reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint.  It is designated for use in applications expecting a status code to indicate that the connection was closed abnormally, e.g., without sending or receiving a Close control frame."

=head2 WS_BAD_MESSAGE

Code C<1007>

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1007 indicates that an endpoint is terminating the connection because it has received data within a message that was not consistent with the type of the message (e.g., non-UTF-8 [L<RFC3629|https://datatracker.ietf.org/doc/html/rfc3629>] data within a text message)."

=head2 WS_FORBIDDEN

Code C<1008>

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1008 indicates that an endpoint is terminating the connection because it has received a message that violates its policy. This is a generic status code that can be returned when there is no other more suitable status code (e.g., 1003 or 1009) or if there is a need to hide specific details about the policy."

=head2 WS_MESSAGE_TOO_LARGE

Code C<1009>

The message is too big to process.

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1009 indicates that an endpoint is terminating the connection because it has received a message that is too big for it to process."

=head2 WS_EXTENSIONS_NOT_AVAILABLE

Code C<1010>

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1010 indicates that an endpoint (client) is terminating the connection because it has expected the server to negotiate one or more extension, but the server didn't return them in the response message of the WebSocket handshake. The list of extensions that are needed SHOULD appear in the /reason/ part of the Close frame. Note that this status code is not used by the server, because it can fail the WebSocket handshake instead."

=head2 WS_INTERNAL_SERVER_ERROR

Code C<1011>

Unexpected error on server.

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1011 indicates that a server is terminating the connection because it encountered an unexpected condition that prevented it from fulfilling the request."

=head2 WS_TLS_HANDSHAKE_FAIL

Code C<1015>

L<rfc6455|https://tools.ietf.org/html/rfc6455#section-7.4.1> describes this as:
"1015 is a reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint.  It is designated for use in applications expecting a status code to indicate that the connection was closed due to a failure to perform a TLS handshake (e.g., the server certificate can't be verified)."

=head1 CREDITS

Graham Ollis for L<AnyEvent::WebSocket::Client>, Eric Wastl for L<Net::WebSocket::Server>, Vyacheslav Tikhanovsky aka VTI for L<Protocol::WebSocket>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API>

L<WebSocket::Client>, L<WebSocket::Common>, L<WebSocket::Connection>, L<WebSocket::Exception>, L<WebSocket::Extension>, L<WebSocket::Frame>, L<WebSocket::Handshake>, L<WebSocket::Handshake::Client>, L<WebSocket::Handshake::Server>, L<WebSocket::Headers>, L<WebSocket::HeaderValue>, L<WebSocket::Request>, L<WebSocket::Response>, L<WebSocket::Server>, L<WebSocket::Version>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
