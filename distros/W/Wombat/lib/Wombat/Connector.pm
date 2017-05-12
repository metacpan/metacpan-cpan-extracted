# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::Connector - internal connector interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface specifies a component that receives requests from and
returns responses to a client application. A Connector performs the
following general logic:

=over

=item 1

Receive a request from the client application

=item 2

Create appropriate Request and Response instances and populate their
fields based on the contents of the request.

=over

=item 1

For all Requests, the I<connector>, I<handle>, I<protocol>,
I<remoteAddr>, I<response>, I<scheme>, I<secure>, I<serverName>, and
I<serverPort> B<MUST> be set. The I<contentLength>, I<contentType> and
I<socket> fields are also generally set.

=item 2

For HttpRequests, the I<method>, I<queryString>,
I<requestedSessionCookie>, I<requestedSessionId>,
I<requestedSessionURL>, and I<requestURI> fields B<MUST> be
set. Additionally, the various I<addXXX> methods B<MUST> be called to
record the presence of cookies, headers and locales in the original
request.

=item 3

For all Responses, the I<connector>, I<handle> and I<request> fields
B<MUST> be set.

=item 4

No additional fields must be set for HttpResponses.

=back

=item 3

Identify an appropriate Container to use for processing this
request. For a standalone Wombat installation, this will probably be a
(singleton) Engine. For a Connector attaching Wombat to a web server,
this step could take advantage of parsing already performed within the
web server to identify the Application, and perhaps even the Wrapper,
to utilize in satisfying this Request.

=item 4

Call C<invoke()> on the selected Container, passing the initialized
Request and Response instances as arguments.

=item 5

Return any response created by the Container to the client, or return
an appropriate error message if an exception of any type was thrown.

=back

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container used for processing Requests received by this
Connector.

=item setContainer($container)

Set the Container used for processing Requests received by this
Connector.

B<Parameters:>

=over

=item $container

the B<Wombat::Container> used for processing Requests

=back

=item getName()

Return the display name of this Connector.

=item getScheme()

Return the scheme that will be assigned to Requests recieved through
this Connector. Default value is I<http>.

=item setScheme($scheme)

Set the scheme that will be assigned to Requests received through this
Connector.

B<Parameters:>

=over

=item $scheme

the scheme

=back

=item getSecure()

Return the secure connection flag that will be assigned to Requests
received through this Connector. Default value is false.

=item setSecure($secure)

Set the secure connection flag that will be assigned to Requests
received through this Connector.

B<Parameters:>

=over

=item $secure

the boolean secure connection flag

=back

=back

=head1 PUBLIC METHODS

=over

=item await()

Begin listening for requests. Depending upon the implementations, this
method may return immediately (for Connectors that execute
asynchrously, eg Apache) or may block (eg Http Connector).

=item createRequest()

Create and return a Request object suitable for specifying the
contents of a request to the responsible Container.

=item createResponse()

Create and return a Response object suitable for receiving the
contents of a response from the responsible Container.

=back

=head1 SEE ALSO

L<Wombat::Application>,
L<Wombat::Container>,
L<Wombat::Engine>,
L<Wombat::HttpRequest>,
L<Wombat::HttpResponse>,
L<Wombat::Request>,
L<Wombat::Response>,
L<Wombat::Wrapper>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
