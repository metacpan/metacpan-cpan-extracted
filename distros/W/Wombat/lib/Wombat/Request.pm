# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Request;

use base qw(Servlet::ServletRequest);

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::Request - internal request interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface extends B<Servlet::ServletRequest> to provide
fields and methods accessible only to the container.

=head1 ACCESSOR METHODS

=over

=item getApplication()

Return the Application within which this Request is being processed.

=item setApplication($application)

Set the Application within which this Request is being processed. This
must be called as soon as the appropriate Application is identified,
because it enables parsing of the request URI.

B<Parameters:>

=over

=item $application

the B<Wombat::Application> within which the Request is being processed

=back

=item getAuthorization()

Return the authorization credentials sent with this Request.

=item setAuthorization($authorization)

Sets the authorization credentials sent with this Request.

B<Parameters:>

=over

=item $authorization

the authorization credentials

=back

=item getConnector()

Return the Connector through which this Request was received.

=item setConnector($connector)

Set the Connector through which this request was received.

B<Parameters:>

=over

=item $connector

the B<Wombat::Connector> that received the request

=back

=item getHandle()

Return the input handle associated with this Request. Usually the
Socket and Handle for the Request are the same object, but this is not
required.

=item setHandle($handle)

Set the input handle ssociated with this Request.

B<Parameters:>

=over

=item $handle

the B<IO::Handle> associated with this Request

=back

=item getRequest()

Return the ServletRequest which acts as a facade for this Request to
servlet applications.

=item getResponse()

Return the Response with which this Request is associated.

=item setResponse($response)

Set the Response with which this Request is associated.

B<Parameters:>

=over

=item $response

the B<Wombat::Response> with which this Request is associated

=back

=item getSocket()

Return the Socket (if any) through which this Request was
received. This should B<only> be used to access underlying state
information about the Socket, such as the SSL information of a
B<IO::Socket::SSL>.

=item setSocket($socket)

Set the Socket (if any) through which this Request was received.

B<Parameters:>

=over

=item $socket

the B<IO::Socket> through which this Request was received

=back

=item getWrapper()

Returns the Wrapper within which this Request is being processed.

=item setWrapper($wrapper)

Set the Wrapper within which this Request is being processed. This
must be called as soon as the appropriate Wrapper is identified, and
before the Request is ultimately passed to an application servlet.

B<Parameters:>

=over

=item $wrapper

the B<Wombat::Wrapper> associated with this Request

=back

=back

=head1 PUBLIC METHODS

=over

=item addLocale($loc)

Add a locale to the set of preferred Locales for this Request.

B<Parameters:>

=over

=item $loc

the locale to add

=back

=item addParameter($name, @values)

Add a named parameter with one or more values to this Request.

B<Parameters:>

=over

=item $name

the name of the parameter to add

=item @values

a list of one or more parameter values, scalar or C<undef>

=back

=item clearLocales()

Clear the list of locales for this Request.

=item clearParameters()

Clear the set of parameters for this Request.

=item createInputHandle()

Create and return a B<Servlet::ServletInputHandle> to read the content
associated with this Request.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=item finishRequest()

Perform whatever actions are required to flush and close the input
handle or reader.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=item setContentLength($length)

Set the length, in bytes, of the request body provided by the input
handle.

B<Parameters:>

=over

=item $length

the content length in bytes

=back

=item setContentType($type)

Set the MIME type of the body of the body of the request.

B<Parameters:>

=over

=item $type

the MIME type

=back

=item setProtocol($protocol)

Set the name and version of the protocol used for the request in the
form I<protocol/majorVersion.minorVersion>.

B<Parameters:>

=over

=item $protocol

the name and version of the protocol

=back

=item setRemoteAddr($remote)

Set the remote IP address associated with this Request. This value
will be used to resolve the name of the remote host if necessary.

B<Parameters:>

=over

=item $remote

the remote IP address

=back

=item setScheme($scheme)

Set the name of the scheme used to make this request, for example
I<http>, I<https>, or I<ftp>.

B<Parameters:>

=over

=item $scheme

the name of the scheme

=back

=item setSecure($secure)

Set a value indicating whether or not the request was made using a
secure channel.

B<Parameters:>

=over

=item $secure

a boolean value

=back

=item setServerName($name)

Set the host name of the server which received this request.

B<Parameters:>

=over

=item $name

the host name

=back

=item setServerPort($port)

Set the port number on which this request was received.

B<Parameters:>

=over

=item $port

the port number

=back

=item recycle()

Release all object references and initialize instances variables in
preparation for use or reuse of this object.

=back

=head1 SEE ALSO

L<IO::Handle>,
L<IO::Socket>,
L<Servlet::ServletRequest>,
L<Servlet::ServletServletInputHandle>,
L<Servlet::Util::Exception>,
L<Wombat::Application>,
L<Wombat::Connector>,
L<Wombat::Response>,
L<Wombat::Wrapper>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
