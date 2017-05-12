# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpServletResponse;

use base qw(Servlet::ServletResponse);

use constant SC_CONTINUE => 100;
use constant SC_SWITCHING_PROTOCOLS => 101;
use constant SC_OK => 200;
use constant SC_CREATED => 201;
use constant SC_ACCEPTED => 202;
use constant SC_NON_AUTHORITATIVE_INFORMATION => 203;
use constant SC_NO_CONTENT => 204;
use constant SC_RESET_CONTENT => 205;
use constant SC_PARTIAL_CONTENT => 206;
use constant SC_MULTIPLE_CHOICES => 300;
use constant SC_MOVED_PERMANENTLY => 301;
use constant SC_MOVED_TEMPORARILY => 302;
use constant SC_SEE_OTHER => 303;
use constant SC_NOT_MODIFIED => 304;
use constant SC_USE_PROXY => 305;
use constant SC_BAD_REQUEST => 400;
use constant SC_UNAUTHORIZED => 401;
use constant SC_PAYMENT_REQUIRED => 402;
use constant SC_FORBIDDEN => 403;
use constant SC_NOT_FOUND => 404;
use constant SC_METHOD_NOT_ALLOWED => 405;
use constant SC_NOT_ACCEPTABLE => 406;
use constant SC_PROXY_AUTHENTICATION_REQUIRED => 407;
use constant SC_REQUEST_TIMEOUT => 408;
use constant SC_CONFLICT => 409;
use constant SC_GONE => 410;
use constant SC_LENGTH_REQUIRED => 411;
use constant SC_PRECONDITION_FAILED => 412;
use constant SC_REQUEST_ENTITY_TOO_LARGE => 413;
use constant SC_REQUEST_URI_TOO_LONG => 414;
use constant SC_UNSUPPORTED_MEDIA_TYPE => 415;
use constant SC_REQUESTED_RANGE_NOT_SATISFIABLE => 416;
use constant SC_EXPECTATION_FAILED => 417;
use constant SC_INTERNAL_SERVER_ERROR => 500;
use constant SC_NOT_IMPLEMENTED => 501;
use constant SC_BAD_GATEWAY => 502;
use constant SC_SERVICE_UNAVAILABLE => 503;
use constant SC_GATEWAY_TIMEOUT => 504;
use constant SC_HTTP_VERSION_NOT_SUPPORTED => 505;

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpServletResponse - HTTP servlet response interface

=head1 SYNOPSIS

  $response->addCookie($cookie);

  $response->addDateHeader($name, $date);

  $response->addHeader($name, $value);

  $bool = $response->containsHeader($name);

  $response->encodeRedirectURL($url);

  $response->encodeURL($url);

  $response->sendError($sc, $msg);

  $response->sendRedirect($location);

  $response->setDateHeader($name, $date);

  $response->setHeader($name, $value);

  $response->setStatus($sc);

=head1 DESCRIPTION

Extends the B<Servlet::ServletResponse> interface to provide
HTTP-specific functionality in sending a response. For example, it has
methods to access HTTP headers and cookies.

The servlet container creates the object and passes it as an argument
to the servlet's service methods (C<doGet()>, C<doPost()>, etc).

=head1 FIELDS

=over

=item SC_ACCEPTED

Status code (202) indicating that a request was accepted for
processing, but was not completed.

=item SC_BAD_GATEWAY

Status code (502) indicating that the HTTP server received an invalid
response from a server it consulted when acting as a proxy or gateway.

=item SC_BAD_REQUEST

Status code (400) indicating the request sent by the client was
syntactically incorrect.

=item SC_CONFLICT

Status code (409) indicating that the request could not be completed
due to a conflict with the current state of the resource.

=item SC_CONTINUE

Status code (100) indicating the client can continue.

=item SC_CREATED

Status code (201) indicating the request succeeded and created a new
resource on the server.

=item SC_EXPECTATION_FAILED

Status code (417) indicating that the server could not meet the
expectation given in the Expect request header.

=item SC_FORBIDDEN

Status code (403) indicating the server understood the request but
refused to fulfill it.

=item SC_GATEWAY_TIMEOUT

Status code (504) indicating that the server did not receive a timely
response from the upstream server while acting as a gateway or proxy.

=item SC_GONE

Status code (410) indicating that the resource is no longer available
at the server and no forwarding address is known. This condition
I<SHOULD> be considered permanent.

=item SC_HTTP_VERSION_NOT_SUPPORTED

Status code (505) indicating that the server does not support or
refuses to support the HTTP protocol version that was used in the
request message.

=item SC_INTERNAL_SERER_ERROR

Status code (500) indicating an error inside the HTTP server which
prevented it from fulfilling the request.

=item SC_LENGTH_REQUIRED

Status code (411) indicating that the requst cannot be handled without
a defined Content-Length.

=item SC_METHOD_NOT_ALLOWED

Status code (405) indicating that the method specified in the
Request-Line is not allowed for the resource identified by the
Request-URI.

=item SC_MOVED_PERMANENTLY

Status code (301) indicating that the resource has permanently moved
to a new location, and that future references shoud use a new URI with
their requests.

=item SC_MOVED_TEMPORARILY

Status code (302) indicating that the resource has temporarily moved
to another location, but that future references should still use the
original URI to access the resource.

=item SC_MULTIPLE_CHOICES

Status code (300) indicating that the requested resource corresponds
to any one of a set of representations, each with its own specified
location.

=item SC_NO_CONTENT

Status code (204) indicating that the request succeeded but that there
was no new information to return.

=item SC_NON_AUTHORITATIVE_INFORMATION

Status code (203) indicating that the meta information presented by
the client did not originate from th server.

=item SC_NOT_ACCEPTABLE

Status code (406) indicating that the resource identified by the
request is only capable of generating response entities which have
content characteristics not acceptable according to the Accept headers
sent in the request.

=item SC_NOT_FOUND

Status code (404) indicating that the requested resource is not
available.

=item SC_NOT_IMPLEMENTED

Status code (501) indicating that the HTTP server does not support the
functionality needed to fulfill the request.

=item SC_NOT_MODIFIED

Status code (304) indicating that a conditional GET operation found
that the resource was available and not modified.

=item SC_OK

Status code (200) indicating the request succeeded normally.

=item SC_PARTIAL_CONTENT

Status code (206) indicating that the server has fulfilled the partial
GET request for the resource.

=item SC_PAYMENT_REQUIRED

Status code (402) reserved for future use.

=item SC_PRECONDITION_FAILED

Status code (412) indicating that the precondition given in one or
more of the request header fields evaluated to false when it was
tested on the server.

=item SC_PROXY_AUTHENTICATION_REQUIRED

Status code (407) indicating that the client I<MUST> first
authenticate itself with the proxy.

=item SC_REQUEST_ENTITY_TOO_LARGE

Status code (413) indicating that the server is refusing to process
the request because the request entity is larger than the server is
willing or able to process.

=item SC_REQUEST_TIMEOUT

Status code (408) indicating that the client did not produce a request
within the time that the server was prepared to wait.

=item SC_REQUEST_URI_TOO_LONG

Status code (414) indicating that the server is refusing to service
the request because the Request-URI is longer than the server is
willing to interpret.

=item SC_REQUESTED_RANGE_NOT_SATISFIABLE

Status code (416) indicating that the server cannot serve the
requested byte range.

=item SC_RESET_CONTENT

Status code (205) indicating that the agent I<SHOULD> reset the
document view which caused the request to be sent.

=item SC_SEE_OTHER

Status code (303) indicating that the response to the request can be
found under a different URI.

=item SC_SERVICE_UNAVAILABLE

Status code (503) indicating that the HTTP server is temporarily
overloaded and unable to handle the reqeust.

=item SC_SWITCHING_PROTOCOLS

Status code (101) indicating the server is switching protocols
according to the Upgrade header.

=item SC_UNAUTHORIZED

Status code (401) indicating that the request requires HTTP
authentication.

=item SC_UNSUPPORTED_MEDIA_TYPE

Status code (415) indicating that the server is refusing to service
the request because the entity of the request is in a format not
supported by the requested resource for the requested method.

=item SC_USE_PROXY

Status code (305) indicating that the requested resource I<MUST> be
accessed through the proxy given by the Location field.

=back

=head1 METHODS

=over

=item addCookie($cookie)

Adds the specified cookie to the response. This method can be called
multiple times to set more than one cookie.

B<Parameters:>

=over

=item I<$cookie>

the B<Servlet::Http::Cookie> to return to the client

=back

=item addDateHeader($name, $date)

Adds a response header with the given name and date-value. The date is
specified in terms of seconds since the epoch. This method allows
respone headers to have multiple values.

B<Parameters:>

=over

=item I<$name>

the name of the header to add

=item I<$date>

the additional header value

=back

=item addHeader($name, $value)

Adds a response header with the given name and value. This method
allows response headers to have multiple values.

B<Parameters:>

=over

=item I<$name>

the name of the header to add

=item I<$date>

the additional header value

=back

=item containsHeader($name)

Returns a boolean indicating whether the named response header has
already been set.

B<Parameters:>

=over

=item I<$name>

the name of the header

=back

=item encodeRedirectURL($url)

Encodes the specified URL for use in the C<sendRedirect()> method or,
if encoding is not needed, returns the URL unchanged. The
implementation of this method includes the logic to determine whether
the session ID needs to be encoded in the URL. Because the rules for
making this determination can differ from those used to decide whether
to encode a normal link, this method is separate from the C<encodeURL()>
method.

All URLs sent to the C<sendRedirect()> method should be run through
this method. Otherwise, URL rewriting cannot be used with browsers
which do not support cookies.

B<Parameters:>

=over

=item I<$url>

the url to be encoded

=back

=item encodeURL($url)

Encodes the session ID into the specified URL or, if encoding is not
needed, returns the URL unchanged. The implementation of this method
includes the logic to determine whether the session ID needs to be
encoded in the URL. For example, if the borwser supports cookies, or
session tracking is turned off, URL encoding is unnecessary.

For robust session tracking, all URLs emitted by a servlet should be
run through this method. Otherwise, URL rewriting cannot be used with
browsers which do not support cookies.

B<Parameters:>

=over

=item I<$url>

the url to be encoded

=back

=item sendError($sc, [$msg])

Sends an error response to the client using the specified status code
and optional descriptive message, clearing the output buffer. The
server defaults to creating the response to look like an
HTML-formatted server error page, setting the content type to
"text/html", leaving cookies and other headers unmodified. If an
error-page declaration has been made for the web application
corresponding to the status code passed in, it will be served back in
preference to the server-generated page.

After using this method, the response should be considered to be
committed and should not be written to.

B<Parameters:>

=over

=item I<$sc>

the error status code

=item I<msg>

the optional descriptive message; if unspecified, the standard message
for the given status code will be used.

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output exception occurs

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=item sendRedirect($location)

Sends a temporary redirect response to the client using the specified
redirect location URI. This method can accept relative URLs; the
servlet container must convert the relative URL to an absolute URL
before sending the response to the client. If the location is relative
without a leading "/" the container interprets it as relative to the
current request URI. If the location is relative with a leading "/"
the container interprets it as relative to the servlet container root.

After using this method, the response should be considered to be
committed and should not be written to.

B<Parameters:>

=over

=item I<$location>

the redirect location URL

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output exception occurs

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=item setDateHeader($name, $date)

Sets a respone header with the given name and date-value. The date is
specified in terms of seconds since the epoch. If the header has
already been set, the new value overwrites the previous one. The
C<containsHeader()> method can be used to test for the presence of a
header before setting its value.

B<Parameters:>

=over

=item I<$name>

the name of the header

=item I<$date>

the header value

=back

=item setHeader($name, $value)

Sets a response header with the given name and value. If the header
has already been set, the new value overwrites the previous one. The
C<containsHeader()> method can be used to test for the presence of a
header before setting its value.

B<Parameters:>

=over

=item I<$name>

the name of the header

=item I<$value>

the header value

=back

=item setStatus($sc)

Sets the status code for this response. This method is used to set the
return status code when there is no error (for example, for the status
codes I<SC_OK> or I<SO_MOVED_TEMPORARILY>). If there is an error, and
the caller wishes to invoke an error-page defined in the web
application, the C<sendError()> method should be used instead.

The container clears the output buffer and sets the Location header,
preserving cookies and other headers.

B<Parameters:>

=over

=item I<$sc>

the status code

=back

=back

=head1 SEE ALSO

L<Servlet::ServletResponse>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
