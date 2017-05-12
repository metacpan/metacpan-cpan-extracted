# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Servlet;

1;
__END__

=pod

=head1 NAME

Servlet::Servlet - servlet interface

=head1 SYNOPSIS

  $servlet->getServletInfo();

  $servlet->init($config);

  # later

  $servlet->service($request, $response);

  my $config = $servlet->getServletConfig();

  # finally

  $servlet->destroy();

=head1 DESCRIPTION

A servlet is a Perl component that runs within a servlet
container. Servlets receive and respond to requests from Web clients,
usually across HTTP.

To implement this interface, you can write a generic servlet that
extends B<Servlet::GenericServlet> or an HTTP servlet that extends
B<Servlet::Http::HttpServlet>.

This interface deinfes methods to initialize a servlet, to service
requests, and to remove a servlet from the server. These are known as
life-cycle methods and are called in the following sequence:

=over

=item 1

The servlet is constructed, then initialized with C<init()>.

=item 2

Any calls from clients to C<service()> are handled.

=item 3

The servlet is taken out of service, then destroyed with C<destroy()>.

=back

In addition to the life-cycle methods, this interface provides the
getServletConfig method, which the servlet can use to get any startup
information, and C<getServletInfo()>, which allows the servlet to
return basic information about itself, such as author, version and
copyright.

=head1 METHODS

=over

=item destroy()

Called by the servlet container to indicate to a servlet that the
servlet is being taken out of service. This method is only called once
all threads within the servlet's C<service()> method have exited or
after a timeout period has passed. After the servlet container calls
this method, it will not call C<service()> again on this servlet.

This method gives the servlet an opportunity to clean up any resources
that are being held (for example, memory, file handles, threads) and
make sure that any persistent state is synchronized with the servlet's
current state in memory.

=item getServletConfig()

Returns a B<Servlet::ServletConfig> object which contains
initialization and startup parameters for this servlet. The object
returned is the one passed to the C<init()> method.

Implementations of this interface are responsible for storing the
object so that this method can return it. The
B<Servlet::GenericServlet> class, which implements this interface,
already does this.

=item getServletInfo()

Returns information about the servlet, such as author, version, and
copyright.

The string that this method returns should be plain text and not
markup of any kind (such as HTML, XML etc).

=item init($config)

Called by the servlet container to indicate to a servlet that the
servlet is being placed into service.

The servlet container calls the C<init()> method exactly once after
instantiating the servlet. The C<init()> method must complete
successfully before the servlet can receive any requests.

The servlet container cannot place the servlet into service if C<init()>.

=over

=item 1

Throws a B<Servlet::ServletException>

=item 2

Does not return within a time defined by the servlet container

=back

B<Parameters:>

=over

=item I<$config>

a B<Servlet::ServletConfig> object containing the servlet's
configuration and initialization parameters

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if an exception has occurred that interferes with the servlet's normal
operation

=back

=item service($request, $response)

Called by the servlet container to allow the servlet to respond to a
request.

This method is only called after the servlet's C<init()> method has
completed successfully.

Servlets may run inside multithreaded servlet containers that can
handle multiple requests concurrently. Developers must be aware to
synchronize ac cess to any shared resources such as files, network
connections, and as well the servlet's class and instance
variables.

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

if an exception occurs that interferes with the servlet's normal
operation

=back

=back

=head1 SEE ALSO

L<Servlet::GenericServlet>,
L<Servlet::ServletConfig>,
L<Servlet::ServletException>,
L<Servlet::ServletRequest>,
L<Servlet::ServletResponse>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
