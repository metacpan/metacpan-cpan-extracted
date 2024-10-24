##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket.pm
## Version v0.2.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/13
## Modified 2024/09/05
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
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
    our $VERSION = 'v0.2.1';
};

sub init
{
    my $self = shift( @_ );
    $self->{compression_threshold}  = WEBSOCKET_COMPRESSION_THRESHOLD unless( defined( $self->{compression_threshold} ) && length( $self->{compression_threshold} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'WebSocket::Exception';
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

1;
# NOTE: POD
__END__

=head1 NAME

WebSocket - WebSocket Client & Server

=head1 SYNOPSIS

    use WebSocket qw( :ws ); # exports standard codes as constant

=head1 VERSION

    v0.2.1

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

=head1 SECURITY CONSIDERATIONS

Some consideration about security. The following are merely food for thoughts that would hopefully be helpful to you, but your mileage may vary.

Always use SSL, which means use the proto C<wss> over C<ws>

Since there is no authentication in the WebSocket protocol, and it does not accept custom headers, a good way to implement authentication is by using L<double submit cookie security measure|https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html> on your website.

In a nutshel:

=over 4

=item 1. User logs in and your API issues an authentication token as cookie not accessible by JavaScript with the cookie option C<HttpOnly>

    GET /auth/signin?code=220a4e8a-e4e5-11ed-9be8-f6e9e4564960 HTTP/1.1
    Host: api.example.com

Your API would respond something like:

    HTTP/1.1 302 Found
    Date: Thu, 27 Apr 2023 10:21:35 GMT
    Server: Apache
    Vary: Origin
    Location: https://example.com/account/
    Set-Cookie: my_auth_token=eyJwMmMiOjUwMDAsInAycyI6ImlMQlAtbkE4ZU5pTWhnU3VTOEdEZHciLCJlbmMiOiJBMTI4R0NNIiwiZXhwIjoxNjgzMTk1Njk2LCJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1cifQ.zYrrWho2QZUTEYE0YziGTtcn6q7GjzjE.t-KP3Jao3jl_VaoZ.j3H2k96_sVZUbQCjUw51vZTqyejjP5ioYTVl4WvL9fJo_ohA3ci2SJXawf1NOaRStKI5xmpnSNmMJLpjCpvxV0DW7mBgpcw4jddUOQLX4wm7XlHqyBOSdmgmusTgQiQ2SnQH6MFXBZfXkz0zx7s8o9w2pHQm9JS8r_av_SkFEDrx4uRlEl0BXrTrVyDHPSiqt0Chz9mXVsVw3hAz-A7yTq1Xd_-Eeg.g4lVIVUFHbeOpnuQVFvII; Domain=example.com; Path=/; Expires=Thu, 04 May 2023 10:21:36 GMT; HttpOnly
    Expires: Wed, 29 Jun 2016 00:00:00 GMT
    Access-Control-Allow-Origin: *
    Cache-Control: private, no-cache, no-store, must-revalidate

=item 2. Your JavaScript issues an API call to refresh and get an updated CSRF every 30 seconds for example.

    POST /csrf HTTP/1.1
    Host: api.example.com
    Accept: application/json, text/javascript, */*; q=0.01
    Accept-Encoding: gzip, deflate, br
    Referer: https://example.com/
    Origin: https://example.com
    Cookie: my_auth_token=eyJwMmMiOjUwMDAsInAycyI6ImlMQlAtbkE4ZU5pTWhnU3VTOEdEZHciLCJlbmMiOiJBMTI4R0NNIiwiZXhwIjoxNjgzMTk1Njk2LCJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1cifQ.zYrrWho2QZUTEYE0YziGTtcn6q7GjzjE.t-KP3Jao3jl_VaoZ.j3H2k96_sVZUbQCjUw51vZTqyejjP5ioYTVl4WvL9fJo_ohA3ci2SJXawf1NOaRStKI5xmpnSNmMJLpjCpvxV0DW7mBgpcw4jddUOQLX4wm7XlHqyBOSdmgmusTgQiQ2SnQH6MFXBZfXkz0zx7s8o9w2pHQm9JS8r_av_SkFEDrx4uRlEl0BXrTrVyDHPSiqt0Chz9mXVsVw3hAz-A7yTq1Xd_-Eeg.g4lVIVUFHbeOpnuQVFvII

=item 3. The API returns an encrypted CSRF token

For example using L<Digest::HMAC/hmac_hex> and the payload is something that can be compared with the authentication token. For example, a user id. To set the CSRF to a short time span, you would want to also add to the payload a timestamp, so the payload could be a combination of the user id and timestamp, such as:

    my $ts = time() + $csrf_time_to_live; # e.g. 30 seconds
    my $payload = join( ';', $user_id, $ts );

    # Add the timestamp at the end to easily find out if it expired
    my $csrf_token = Digest::HMAC::hmac_hex( $payload, $secret, \&Digest::SHA::sha256 ) . ".$ts";

The API returns it in a custom HTTP response header and/or in a JSON reply, something like:

    HTTP/1.1 200 OK
    Date: Thu, 27 Apr 2023 10:21:38 GMT
    Server: Apache
    Vary: Origin
    Access-Control-Allow-Origin: https://example.com
    Access-Control-Allow-Credentials: true
    Access-Control-Max-Age: 5
    X-CSRF-Token: 899106ee26933c654c33b0fac9adc93f2adad2c95ff30a4eeebe200fbfeafb6a.1682591199
    Access-Control-Expose-Headers: X-CSRF-Token
    Cache-Control: private, no-cache, no-store, must-revalidate
    Keep-Alive: timeout=5, max=99
    Connection: Keep-Alive
    Transfer-Encoding: chunked
    Content-Type: application/json

    {"token":"899106ee26933c654c33b0fac9adc93f2adad2c95ff30a4eeebe200fbfeafb6a.1682591199","code":200}

=item 4. Your JavaScript stores the CSRF in the web browser local storage

=item 5. Your JavaScript opens up a WebSocket connection to the same api

This is important so that the authentication cookie can be received (cookies cannot be shared across domains)

Also, the URL of the connection contains a query string with the current CSRF token such as:

    var webSocket = new WebSocket('wss://api.example.com/wss?csrf=899106ee26933c654c33b0fac9adc93f2adad2c95ff30a4eeebe200fbfeafb6a.1682591199');

Query strings are encrypted under SSL, however they will be recorded in the server HTTP logs.

You can use the L<WebSocket JavaScript library|https://gitlab.com/jackdeguest/WebSocket/-/blob/master/examples/websocket.js> provided in the examples folder in L<this distribution|/https://metacpan.org/dist/WebSocket/source/examples/websocket.js> and its L<documentation|https://metacpan.org/dist/WebSocket/view/examples/websocket.pod>.

=item 6. Your API reverse proxy that WebSocket request to the WebSocket server

This can be achieved with Apache and Nginx. For example with Apache:

Inside the VirtualHost, add the following:

    RewriteEngine On
    # When Upgrade:websocket header is present, redirect to ws
    # Using NC flag (case-insensitive) as some browsers will pass Websocket
    RewriteCond %{REQUEST_URI}  ^/wss                  [NC]
    RewriteCond %{HTTP:Upgrade}             =websocket [NC]
    RewriteRule ^/wss/(.*)     ws://localhost:8080/$1 [P,L]

    RewriteCond %{REQUEST_URI}  ^/wss                  [NC]
    RewriteCond %{QUERY_STRING} transport=websocket    [NC]
    RewriteRule ^/wss/(.*)     ws://localhost:8080/$1 [P,L]

    ProxyRequests Off
    ProxyPass /wss            ws://localhost:8080
    ProxyPassReverse /wss     ws://localhost:8080

You will need to enable the Apache modules C<proxy>, C<proxy_http> and C<proxy_wstunnel>

See also this L<StackOverflow thread|https://stackoverflow.com/questions/27526281/websockets-and-apache-proxy-how-to-configure-mod-proxy-wstunnel>

For Nginx, check its L<documentation|https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/>

=item 7. The WebSocket server would receive the initial connection request such as:

    GET /wss?csrf=899106ee26933c654c33b0fac9adc93f2adad2c95ff30a4eeebe200fbfeafb6a.1682591199 HTTP/1.1
    Host: api.example.com
    Upgrade: websocket
    Connection: Upgrade
    Cookie: my_auth_token=eyJwMmMiOjUwMDAsInAycyI6ImlMQlAtbkE4ZU5pTWhnU3VTOEdEZHciLCJlbmMiOiJBMTI4R0NNIiwiZXhwIjoxNjgzMTk1Njk2LCJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1cifQ.zYrrWho2QZUTEYE0YziGTtcn6q7GjzjE.t-KP3Jao3jl_VaoZ.j3H2k96_sVZUbQCjUw51vZTqyejjP5ioYTVl4WvL9fJo_ohA3ci2SJXawf1NOaRStKI5xmpnSNmMJLpjCpvxV0DW7mBgpcw4jddUOQLX4wm7XlHqyBOSdmgmusTgQiQ2SnQH6MFXBZfXkz0zx7s8o9w2pHQm9JS8r_av_SkFEDrx4uRlEl0BXrTrVyDHPSiqt0Chz9mXVsVw3hAz-A7yTq1Xd_-Eeg.g4lVIVUFHbeOpnuQVFvIIg
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: https://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

This will be handled by the L<WebSocket::Connection/on_handshake> handler.

The L<WebSocket::Server> would respond like so:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

=item 8. Validate the authentication cookie and CSRF token

    use Cookie::Jar;
    use DB::Object;
    $ws->on( handshake => sub
    {
        my( $conn, $hs );
        my $req = $hs->request;
        my $cookie = $req->header( 'Cookie' );
        my $jar = Cookie::Jar->new;
        $jar->fetch( string => $cookie );
        my $token = $jar->get( 'my_auth_token' );
        my $csrf = $req->uri->query_param( 'csrf' );
        # Do authentication checks
        my $dbh = DB::Object->new( conf_file => '/some/where/sql_connection.json' );
        my $tbl = $dbh->sessions || die( "No table 'sessions' in database" );
        $tbl->where( $tbl->fo->session_id => '?' );
        my $sth = $tbl->select || die( $tbl->error );
        $sth->exec( $token ) || die( $sth->error );
        my $ref = $sth->fetchrow_hashref;
        if( !%$ref )
        {
            # At the hanshake stage, we use an HTTP error in reply
            # http_error() will also disconnect
            my $bytes = $conn->http_error({
                code => 403,
                message => "You do not have permission to access this websocket.",
            });
            defined( $bytes ) || die( $conn->error );
            return;
        }
        my $user_id = $ref->{user_id};
        # Stores some unique user id that we will use to check the csrf submitted in each message
        $conn->metadata({ id => $user_id });
        my( $payload, $ts ) = ( $csrf =~ /^(\w+)\.(\d{10})$/ );
        my $check = Digest::HMAC::hmac_hex( join( ';', $user_id, $ts ), $secret, \&Digest::SHA::sha256 ) . '.' . $ts;
        if( $check ne $csrf )
        {
            my $bytes = $conn->http_error({
                code => 403,
                message => "You do not have permission to access this websocket.",
            });
            defined( $bytes ) || die( $conn->error );
            return;
        }
        # etc...
    });

Using the handler set with L<WebSocket::Connection/on_handshake>, your API checks the authentication token is valid and the CSRF token has not expired.

It also re-creates the CSRF payload using the timestamp provided, re-encrypts it  and compares is to the CSRF token received.

You can then stores the id used in the CSRF payload in the L<connection metadata|WebSocket::Connection/metadata>

=item 9. Once established, the JavaScript will send JSON messages containing a property C<csrf> with the current CSRF token.

=item 10. Check the CSRF token in message received.

Check each CSRF token to ensure the message received is valid using the id stored in the connection metadata using L<WebSocket::Connection/metadata>

At this stage, we use WebSocket message to return an error, contrary to the handshake stage earlier

    use JSON;
    $conn->on( utf8 => sub
    {
        my( $conn, $msg ) = @_;
        my $j = JSON->new->utf8;
        my $ref = $j->decode( $msg );
        my $id = $conn->metadata->{id};
        my $csrf = $ref->{csrf};
        if( !length( $csrf // '' ) )
        {
            my $msg = 
            {
            code => 403,
            message => "You do not have permission to access this websocket.",
            };
            my $json = $j->encode( $msg );
            my $bytes = $conn->send_utf8( $json );
            $conn->disconnect;
            defined( $bytes ) || die( $conn->error );
            return;
        }
        elsif( $ts < time() )
        {
            my $msg = 
            {
            code => 403,
            message => "The CSRF provided has expired.",
            };
            my $json = $j->encode( $msg );
            my $bytes = $conn->send_utf8( $json );
            $conn->disconnect;
            defined( $bytes ) || die( $conn->error );
            return;
        }
        my( $encrypted, $ts ) = ( $csrf =~ /^(\w+)\.(\d{10})$/ );
        my $payload = join( ';', $id, $ts );
        my $check = Digest::HMAC::hmac_hex( $payload, $secret, \&Digest::SHA::sha256 ) . ".$ts";
        if( $check ne $csrf )
        {
            my $msg = 
            {
            code => 403,
            message => "You do not have permission to access this websocket.",
            };
            my $json = $j->encode( $msg );
            my $bytes = $conn->send_utf8( $json );
            $conn->disconnect;
            defined( $bytes ) || die( $conn->error );
            return;
        }
        # etc...
    });

=back

=head1 CREDITS

Graham Ollis for L<AnyEvent::WebSocket::Client>, Eric Wastl for L<Net::WebSocket::Server>, Vyacheslav Tikhanovsky aka VTI for L<Protocol::WebSocket>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API>

L<WebSocket::Client>, L<WebSocket::Common>, L<WebSocket::Connection>, L<WebSocket::Exception>, L<WebSocket::Extension>, L<WebSocket::Frame>, L<WebSocket::Handshake>, L<WebSocket::Handshake::Client>, L<WebSocket::Handshake::Server>, L<WebSocket::Headers>, L<WebSocket::HeaderValue>, L<WebSocket::Request>, L<WebSocket::Response>, L<WebSocket::Server>, L<WebSocket::Version>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
