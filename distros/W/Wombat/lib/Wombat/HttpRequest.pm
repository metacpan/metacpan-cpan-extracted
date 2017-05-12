# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::HttpRequest;

use base qw(Servlet::Http::HttpServletRequest Wombat::Request);

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::HttpRequest - internal http request interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface extends B<Servlet::Http::HttpServletRequest> and
B<Wombat::Request> to provide fields and methods accessible only to
the container.

=head1 PUBLIC METHODS

=over

=item addCookie($cookie)

Add a Cookie to the set of Cookies for this Request.

B<Parameters:>

=over

=item $cookie

the B<Servlet::Http::Cookie>

=back

=item addHeader($name, $value)

Add a value for the named request header.

B<Parameters:>

=over

=item $name

the parameter name

=item $value

the parameter value, scalar

=back

=item clearCookies()

Remove all Cookies for this Request.

=item clearHeaders()

Unset all headers for this Request.

=item setAuthType($type)

Set the authentication type used for this request, or C<undef> for no
authentication.

B<Parameters:>

=over

=item $type

the authentication type, as defined in
C<Servlet::Http::HttpServletRequest>

=back

=item setContextPath($path)

Set the context path for this Request. This will normally be called
when the associated Application is mapping the Request to a particular
Wrapper.

B<Parameters:>

=over

=item $path

the context path

=back

=item setMethod($method)

Set the HTTP request method used for this Request.

B<Parameters:>

=over

=item $method

the request method

=back

=item setQueryString($query)

Set the query string for this Request. This will normally be called by
the Connector when it parses the request headers.

B<Parameters:>

=over

=item $query

the query string

=back

=item setPathInfo($path)

Set the path information for this Request. This will normally be
called when the associated Application is mapping the Request to a
particular Wrapper.

B<Parameters:>

=over

=item $path

the path information

=back

=item setRequestedSessionCookie($flag)

Set a flag indicating whether or not the requested session ID for this
Request came in through a cookie. This is normally called by the
Connector when it parses the request headers.

B<Parameters:>

=over

=item $flag

a boolean value

=back

=item setRequestedSessionId($id)

Set the requested session ID for this Request. This is normally called
by the Connector when it parses the request headers.

B<Parameters:>

=over

=item $id

the session id

=back

=item setRequestedSessionURL($flag)

Set a flag indicating whether or not the requested session ID for this
Request came in through the request URL. This is normally called by
the Connector when it parses the request headers.

B<Parameters:>

=over

=item $flag

a boolean value

=back

=item setRequestURI($uri)

Set the unparsed request URI for this Request. This is normally called
by the Connector when it parses the request headers.

B<Parameters:>

=over

=item $uri

the request URI

=back

=item setServletPath($path)

Set the servlet path for this Request. This is normally called when
the associated Application is mapping the Request to a particular
Wrapper.

B<Parameters:>

=over

=item $path

the servlet path

=back

=item setSession($session)

Set the internal Session associated with this Request.

B<Parameters:>

=over

=item $session

The B<Wombat::Core::Session> to set

=back

=item setUserPrincipal($principal)

Set the principal that has been authenticated for this Request. This
value is also used to calculate the value to be returned by
L<Wombat::Request/getRemoteUser()>.

B<Parameters:>

=over

=item $principal

the user principal

=back

=back

=head1 SEE ALSO

L<Servlet::Http::Cookie>,
L<Servlet::Http::HttpServletRequest>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
