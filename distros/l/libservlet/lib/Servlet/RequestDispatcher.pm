# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::RequestDispatcher;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::RequestDispatcher - request dispatcher interface

=head1 SYNOPSIS

  $dispatcher->forward($request, $response);

  $dispatcher->include($request, $response);

=head1 DESCRIPTION

A request dispatcher receives requests from the client and sends them
to any resource (such as a servlet or HTML file) on the server. The
servlet container creates the B<Servlet::RequestDispatcher> object,
which is used as a wrapper around a server resource located at a given
path or by a particular name.

This interface is intended to wrap servlets, but a servlet container
can create dispatcher objects to wrap any type of resource.

=head1 METHODS

=over

=item forward($request, $response)

Forwards a request from a servlet to another resource on the
server. This method allows one servlet to do preliminary processing of
a request and another resource to generate the response.

For an object obtained via C<getRequestDispatcher()>, the
B<Servlet::ServletRequest> object has its path elements and parameters
adjusted to match the path of the target resource.

This method should be called before the response has been committed to
the client (before response body output has been flushed). If the
response already has been committed, this method throws a
B<Servlet::Util::IllegalStateException>. Uncommitted output in the
response buffer is automatically cleared before the forward.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::ServletRequest> object that contains the client's
request

=item I<$response>

the B<Servlet::ServletResponse> object that contains the servlet's
response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the target resource throws this exception

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=item include($request, $response)

Includes the content of a resource in the response. In essence, this
method enables programmatic server-side includes.

The B<Servlet::ServletResponse> object's path elements and parameters
remain unchanged from the caller's. The included servlet cannot change
the response status code or set headers; any attempt to make a change
is ignored.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::ServletRequest> object that contains the client's
request

=item I<$response>

the B<Servlet::ServletResponse> object that contains the servlet's
response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the target resource throws this exception

=back

=back

=head1 SEE ALSO

L<Servlet::ServletException>,
L<Servlet::ServletRequest>,
L<Servlet::ServletResponse>,
L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
