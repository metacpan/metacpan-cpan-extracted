# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Valve;

$VERSION = 0;

1;

__END__

=pod

=head1 NAME

Wombat::Valve - internal valve interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface specifies a component that assists in processing
requests for a particular Container. A series of Valves is generally
associated with each other via a Pipeline.

A Valve B<MAY> perform the following actions, in the specified order:

=over

=item 1

Examine and/or modify the properties of the specified Request and
Response.

=item 2

Examine the properties of the specified Request, completely generate
the corresponding Response, and return control to the caller.

=item 3

Examine the properties of the specified Request and Response, wrap
either or both of these objects to supplement their functionality, and
pass them on.

=item 4

If the corresponding Response was not generated (and control was not
returned), call the next Valve in the Pipeline by calling
C<invokeNext()> on the Valve's Container.

=item 5

Examine, but not modify, the properties of the resulting Response
(which was created by a subsequently invoked Valve or Container).

=back

A Valve B<MUST NOT> do any of the following things:

=over

=item 1

Change request properties that have already been used to direct the
flow of processing control for this request.

=item 2

Create a completed Response B<AND> pass this Request and Response on
to the next Valve in the Pipeline.

=item 3

Consume bytes from the input handle associated with the Request,
unless it is completely generating the Response or wrapping the
Request before passing it on.

=item 4

Modify the HTTP headers included with the Response after
C<invokeNext()> has returned.

=item 5

Perform any actions on the output handle associated with the specified
Response after C<invokeNext()> has returned.

=back

=head1 PUBLIC METHODS

=over

=item invoke ($request, $response, $context)

Perform request processing as required by this Valve.

B<Parameters>

=over

=item $request

the B<Wombat::Request> to be processed

=item $response

the B<Wombat::Response> to be created

=item $context

the B<Wombat::ValveContext> allowing access to the next Valve in the
Pipeline being processed

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if a servlet error occurs or is thrown by a subsequently invoked
Valve, Filter or Servlet

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Container>,
L<Wombat::Exception>,
L<Wombat::Pipeline>,
L<Wombat::Request>,
L<Wombat::Response>,
L<Wombat::ValveContext>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
