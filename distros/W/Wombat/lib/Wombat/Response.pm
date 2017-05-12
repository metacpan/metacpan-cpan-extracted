# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Response;

use base qw(Servlet::ServletResponse);

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::Response - internal response interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface extends B<Servlet::ServletResponse> to provide
fields and methods accessible only to the container.

=head1 ACCESSOR METHODS

=over

=item getApplication()

Return the Application within which this Response is being generated.

=item setApplication($application)

Set the Application within which this Response is being generated. This
must be called as soon as the appropriate Application is identified.

B<Parameters:>

=over

=item $application

the B<Wombat::Application> within which the Response is being generated

=back

=item getConnector()

Return the Connector through which this Response is returned.

=item setConnector($connector)

Set the Connector through which this response is returned.

B<Parameters:>

=over

=item $connector

the B<Wombat::Connector> that will return the response

=back

=item getContentCount()

Return the number of bytes actually written to the output stream.

=item isError()

Return a flag indicating whether or not this is an error response.

=item setError($flag)

Set a flag indicating whether or not this is an error response.

B<Parameters:>

=over

=item $flag

a boolean value indicating whether or not this is an error response

=back

=item isIncluded()

Return a flag indicating whether or not this Response is being
processed as an include.

=item setIncluded($flag)

Set a flag indicating whether or not this Response is being processed
as an include.

B<Parameters:>

=over

=item $flag

a boolean value indicating whether or not this response is included

=back

=item getHandle()

Return the output handle associated with this Response.

=item setHandle($handle)

Set the input handle associated with this Response.

B<Parameters:>

=over

=item $handle

the B<IO::Handle> associated with this Response

=back

=item getRequest()

Return the Request with which this Response is associated.

=item setRequest($request)

Set the Request with which this Response is associated.

B<Parameters:>

=over

=item $request

the B<Wombat::Request> with which this response is associated

=back

=item getResponse()

Return the ServletResponse which acts as a facade for this Response to
servlet applications.

=back

=head1 PUBLIC METHODS

=over

=item createOutputHandle()

Create and return a B<Servlet::ServletOutputHandle> to write the content
associated with this Response.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=item finishResponse()

Perform whatever actions are required to flush and close the output
handle or writer.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=item getContentLength()

Return the content length, in bytes, that was set or calculated for
this Response.

=item getContentType()

Return the MIME type that was set or calculated for this response.

=item recycle()

Release all object references and initialize instances variables in
preparation for use or reuse of this object.

=back

=head1 SEE ALSO

L<IO::Handle>,
L<Servlet::ServletResponse>,
L<Servlet::ServletServletOutputHandle>,
L<Servlet::Util::Exception>,
L<Wombat::Application>,
L<Wombat::Connector>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
