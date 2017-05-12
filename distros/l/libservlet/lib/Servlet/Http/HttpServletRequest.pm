# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpServletRequest;

use base qw(Servlet::ServletRequest);

use constant BASIC_AUTH => 'BASIC';
use constant CLIENT_CERT_AUTH => 'CERT-CLIENT';
use constant DIGEST_AUTH => 'DIGEST';
use constant FORM_AUTH => 'FORM';

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpServletRequest - HTTP servlet request interface

=head1 SYNOPSIS

  my $type = $request->getAuthType();

  my $contextpath = $request->getContextPath();

  my @cookies = $request->getCookies();

  my $date = $request->getDateHeader($name);

  for my $name ($request->getHeaderNames()) {
    my $val = $request->getHeader($name);
    # or
    my @vals = $request->getHeaders($name);
  }

  my $method = $request->getMethod();

  my $pathinfo = $request->getPathInfo();

  my $realpath = $request->getPathTranslated();

  my $querystring = $request->getQueryString();

  my $user = $request->getRemoteUser();

  my $sessionid = $request->getRequestedSessionID();

  my $uri = $request->getRequestURI();

  my $url = $request->getRequestURL();

  my $servletpath = $request->getServletPath();

  my $session = $request->getSession($createFlag);

  my $principal = $request->getUserPrincipal();

  my $bool = $request->isRequestedSessionIdFromCookie();
  my $bool = $request->isRequestedSessionIdFromURL();
  my $bool = $request->isRequestedSessionIdValid();

  my $bool = $request->isUserInRole($role);

=head1 DESCRIPTION

Extends the B<Servlet::ServletRequest> interface to provide request
information for HTTP servlets.

The servlet container creates this object and passes it as an argument
to the servlet's service methods (C<doGet()>, C<doPost()>, etc).

=head1 FIELDS

=over

=item BASIC_AUTH

String identifier for Basic authentication. Value "BASIC".

=item CLIENT_CERT_AUTH

String identifier for certificate authentication. Value "CERT-CLIENT".

=item DIGEST_AUTH

String identifier for Digest authentication. Value "DIGEST".

=item FORM_AUTH

String identifier for form authentication. Value "FORM".

=back

=head1 METHODS

=over

=item getAuthType()

Returns the name of the authentication scheme used to protect the
servlet. All servlet containers must support BASIC_AUTH, FORM_AUTH
and CLIENT_CERT_AUTH and may support DIGEST_AUTH. If the servlet is
not authenticated, I<undef> is returned.

Same as the CGI variable I<AUTH_TYPE>.

=item getContextPath()

Returns the portion of the request URI that indicates the context of
the request. The context path always comes first in a request URI. The
path starts with a "/" character but does not end with a "/"
character. For servlets in the default (root) context, this method
returns "". The container does not decode this string.

=item getCookies()

Returns an array containing all of the B<Servlet::Http::Cookie>
objects the client sent with this request, or an empty array if no
cookies were sent.

=item getDateHeader($name)

Returns the value of the specified request header as an integer value
representing the number of seconds since the epoch. Use this method
with headers that contain dates, such as If-Modified-Since.

B<Parameters:>

=over

=item I<$name>

the header name

=back

=item getHeader($name)

Returns the value of the specified request header, or I<undef> if the
request did not include a header of the specified name. The header
name is case insensitive. This method can be used with any request
header.

=item getHeaderNames()

Returns an array of all the header names this request contains, or an
empty array if the request has no headers.

Some servlet containers do not allow servlets to access headers using
this method, in which case this method returns I<undef>.

=item getHeaders($name)

Returns an array of the values of the specified request header, or an
empty array if the request did not include a header of the specified
name. The header name is case insensitive. This method can be used
with any request header.

Some headers (such as Accept-Language) can be sent by clients as
several headers each with a different value rather than sending the
header as a comma separated list.

B<Parameters:>

=over

=item I<$name>

the header name

=back

=item getMethod()

Returns the name of the HTTP method with which this request was made,
for example, GET, POST, or PUT. Same as the value of the CGI variable
I<REQUEST_METHOD>.

=item getPathInfo()

Returns any extra path information associated with the URL the client
sent when it made this request, or I<undef> if there was no extra path
information. The extra path information follows the servlet path but
precedes the query string. Same as the value of the CGI variable
I<PATH_INFO>.

=item getPathTranslated()

Returns any extra path information after the servlet name but before
the query string, translated to a real path, or I<undef> if there was
no extra path information. The web container does not decode this
string. Same as the value of the CGI variable I<PATH_TRANSLATED>.

=item getQueryString()

Returns the query string that is contained in the request URL after
the path, or I<undef> if the URL does not have a query string. Same as
the value of the CGI variable I<QUERY_STRING>.

=item getRemoteUser()

Returns the name of the user making this request, if the user has been
authenticated, or I<undef> if the user has not been
authenticated. Whether the user name is sent with each subsequent
request depends on the client and type of authentication. Same as the
value of the CGI variable I<REMOTE_USER>.

=item getRequestedSessionId()

Returns the session ID specified by the client (or I<undef> if the
request did not specify a session ID). This may not be the same as the
ID of the actual session in use. For example, if the request specified
an old (expired) session ID and the server has started a new session,
this method gets a new session with a new ID.

=item getRequestURI()

Returns the part of this request's URL from the protocol name up to
the query string in the first line of the HTTP request. The web
container does not decod this string.

To reconstruct a URL with a scheme and host, use C<getRequestURL()>.

=item getRequestURL()

Reconstructs the URL the client used to make the request. The returned
URL contains a protocol, server name, port number, and server path,
but it does no tinclude query string parameters.

This method is useful for creating redirect messages and for reporting
errors.

=item getServletPath()

Returns the part of this request's URL that calls the servlet. This
includes either the servlet name or a path to the servlet but does not
include any extra path information or a query string. Same as the
value of the CGI variable I<SCRIPT_NAME>.

=item getSession($boolean)

Returns the current session associated with this request, or if the
request does not have a session and I<$create> is true, creates
one. If I<$create> is false and the request has no valid session,
I<undef> is returned.

To make sure the session is properly maintained, you must call this
method before the response is committed.

B<Parameters:>

=over

=item I<$create>

true to create a new session for this request if necessary; false to
return I<undef> if there's no current session.

=back

=item getUserPrincipal()

Returns a B<XXX> object containing th ename of the current
authenticated user, or I<undef> if the user has not been
authenticated.

=item isRequestedSessionIdFromCookie()

Returns true if the requested session ID came in as a cookie,
otherwise false.

=item isRequestedSessionIdFromURL()

Returns true if the requested session ID came in as part of the
request URL, otherwise false.

=item isRequestedSessionIdValid()

Returns true if the requested session ID is still valid, false
otherwise.

=item isUserInRole($role)

Returns true if the authenticated user is included in the specified
logical role, or false if the user has not been authenticated or is
not included in the role. Roles and role membership can be defined
using deployment descriptors.

B<Parameters:>

=over

=item I<$role>

the name of the role

=back

=back

=head1 SEE ALSO

L<Servlet::ServletRequest>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
