SYNOPSIS
========

        use WebSocket qw( :ws ); # exports standard codes as constant

VERSION
=======

        v0.1.1

DESCRIPTION
===========

This is the client
([WebSocket::Client](https://metacpan.org/pod/WebSocket::Client){.perl-module})
and server
([WebSocket::Server](https://metacpan.org/pod/WebSocket::Server){.perl-module})
implementation of WebSocket api. It provides a comprehensive well
documented and hopefully easy-to-use implementation.

Also, this api, by design, does not die, but rather returns `undef` and
set an
[WebSocket::Exception](https://metacpan.org/pod/WebSocket::Exception){.perl-module}
that can be retrieved with the inherited [\"error\" in
Module::Generic](https://metacpan.org/pod/Module::Generic#error){.perl-module}
method.

It is important to always check the return value of a method. If it
returns `undef` and unless this means something else, by default it
means an error has occurred and you can retrieve it with the
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
method. If you fail to check return values, you are in for some trouble.
If you would rather have error be fatal, you can instantiate objects
with the option *fatal* set to a true value.

Most of methods here allows chaining.

You can also find a JavaScript WebSocket client library in this
distribution under the `example` folder. The JavaScript library also has
a pod documentation.

CONSTRUCTOR
===========

new
---

Create a new
[WebSocket](https://metacpan.org/pod/WebSocket){.perl-module} object
acting as an accessor.

One object should be created per po file, because it stores internally
the po data for that file in the
[Text::PO](https://metacpan.org/pod/Text::PO){.perl-module} object
instantiated.

Returns the object.

METHODS
=======

client
------

Convenient shortcut to instantiate a new
[WebSocket::Client](https://metacpan.org/pod/WebSocket::Client){.perl-module}
object, passing it whatever argument was provided.

compression\_threshold
----------------------

Set or get the threshold in bytes above which the ut8 or binary messages
will be compressed if the client and the server support compression and
it is activated as an extension.

See [\"extensions\" in
WebSocket::Client](https://metacpan.org/pod/WebSocket::Client#extensions){.perl-module}
and [\"extensions\" in
WebSocket::Server](https://metacpan.org/pod/WebSocket::Server#extensions){.perl-module}.

server
------

Convenient shortcut to instantiate a new
[WebSocket::Server](https://metacpan.org/pod/WebSocket::Server){.perl-module}
object, passing it whatever argument was provided.

CONSTANTS
=========

The following constants are available, but not exported by default. You
can import them into your namespace using either the tag `:ws` or
`:all`, such as:

        use WebSocket qw( :ws );

WS\_OK
------

Code `1000`.

The default, normal closure (used if no code supplied),

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1000 indicates a normal closure, meaning that the
purpose for which the connection was established has been fulfilled.\"

WS\_GONE
--------

Code `1001`

The party is going away, e.g. server is shutting down, or a browser
leaves the page.

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1001 indicates that an endpoint is \"going away\",
such as a server going down or a browser having navigated away from a
page.\"

WS\_PROTOCOL\_ERROR
-------------------

Code `1002`

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1002 indicates that an endpoint is terminating the
connection due to a protocol error.\"

WS\_NOT\_ACCEPTABLE
-------------------

Code `1003`

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1003 indicates that an endpoint is terminating the
connection because it has received a type of data it cannot accept
(e.g., an endpoint that understands only text data MAY send this if it
receives a binary message).\"

WS\_NO\_STATUS
--------------

Code `1005`

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1005 is a reserved value and MUST NOT be set as a
status code in a Close control frame by an endpoint. It is designated
for use in applications expecting a status code to indicate that no
status code was actually present.\"

WS\_CLOSED\_ABNORMALLY
----------------------

Code `1006`

No way to set such code manually, indicates that the connection was lost
(no close frame).

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1006 is a reserved value and MUST NOT be set as a
status code in a Close control frame by an endpoint. It is designated
for use in applications expecting a status code to indicate that the
connection was closed abnormally, e.g., without sending or receiving a
Close control frame.\"

WS\_BAD\_MESSAGE
----------------

Code `1007`

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1007 indicates that an endpoint is terminating the
connection because it has received data within a message that was not
consistent with the type of the message (e.g., non-UTF-8
\[[RFC3629](https://datatracker.ietf.org/doc/html/rfc3629){.perl-module}\]
data within a text message).\"

WS\_FORBIDDEN
-------------

Code `1008`

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1008 indicates that an endpoint is terminating the
connection because it has received a message that violates its policy.
This is a generic status code that can be returned when there is no
other more suitable status code (e.g., 1003 or 1009) or if there is a
need to hide specific details about the policy.\"

WS\_MESSAGE\_TOO\_LARGE
-----------------------

Code `1009`

The message is too big to process.

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1009 indicates that an endpoint is terminating the
connection because it has received a message that is too big for it to
process.\"

WS\_EXTENSIONS\_NOT\_AVAILABLE
------------------------------

Code `1010`

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1010 indicates that an endpoint (client) is
terminating the connection because it has expected the server to
negotiate one or more extension, but the server didn\'t return them in
the response message of the WebSocket handshake. The list of extensions
that are needed SHOULD appear in the /reason/ part of the Close frame.
Note that this status code is not used by the server, because it can
fail the WebSocket handshake instead.\"

WS\_INTERNAL\_SERVER\_ERROR
---------------------------

Code `1011`

Unexpected error on server.

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1011 indicates that a server is terminating the
connection because it encountered an unexpected condition that prevented
it from fulfilling the request.\"

WS\_TLS\_HANDSHAKE\_FAIL
------------------------

Code `1015`

[rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4.1){.perl-module}
describes this as: \"1015 is a reserved value and MUST NOT be set as a
status code in a Close control frame by an endpoint. It is designated
for use in applications expecting a status code to indicate that the
connection was closed due to a failure to perform a TLS handshake (e.g.,
the server certificate can\'t be verified).\"

CREDITS
=======

Graham Ollis for
[AnyEvent::WebSocket::Client](https://metacpan.org/pod/AnyEvent::WebSocket::Client){.perl-module},
Eric Wastl for
[Net::WebSocket::Server](https://metacpan.org/pod/Net::WebSocket::Server){.perl-module},
Vyacheslav Tikhanovsky aka VTI for
[Protocol::WebSocket](https://metacpan.org/pod/Protocol::WebSocket){.perl-module}

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55a98a740af8)"}\>

SEE ALSO
========

[Mozilla
documentation](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API){.perl-module}

[WebSocket::Client](https://metacpan.org/pod/WebSocket::Client){.perl-module},
[WebSocket::Common](https://metacpan.org/pod/WebSocket::Common){.perl-module},
[WebSocket::Connection](https://metacpan.org/pod/WebSocket::Connection){.perl-module},
[WebSocket::Exception](https://metacpan.org/pod/WebSocket::Exception){.perl-module},
[WebSocket::Extension](https://metacpan.org/pod/WebSocket::Extension){.perl-module},
[WebSocket::Frame](https://metacpan.org/pod/WebSocket::Frame){.perl-module},
[WebSocket::Handshake](https://metacpan.org/pod/WebSocket::Handshake){.perl-module},
[WebSocket::Handshake::Client](https://metacpan.org/pod/WebSocket::Handshake::Client){.perl-module},
[WebSocket::Handshake::Server](https://metacpan.org/pod/WebSocket::Handshake::Server){.perl-module},
[WebSocket::Headers](https://metacpan.org/pod/WebSocket::Headers){.perl-module},
[WebSocket::HeaderValue](https://metacpan.org/pod/WebSocket::HeaderValue){.perl-module},
[WebSocket::Request](https://metacpan.org/pod/WebSocket::Request){.perl-module},
[WebSocket::Response](https://metacpan.org/pod/WebSocket::Response){.perl-module},
[WebSocket::Server](https://metacpan.org/pod/WebSocket::Server){.perl-module},
[WebSocket::Version](https://metacpan.org/pod/WebSocket::Version){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
