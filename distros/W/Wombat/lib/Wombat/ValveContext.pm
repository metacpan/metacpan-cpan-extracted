# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::ValveContext;

$VERSION = 0;

1;

__END__

=pod

=head1 NAME

Wombat::ValveContext - internal valve connection interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface specifies a component that allows a Valve to trigger
the execution of the next Valve in a Pipeline without having to know
anything about internal implementation mechanisms. An instance of a
class implementing this interface is passed as a parameter to
C<invoke()> for each executed Valve.

=head1 PUBLIC METHODS

=over

=item invokeNext ($request, $response)

Cause C<invoke()> to be called on the next Valve in the Pipeline that
is currently being processed, passing on the specified Request and
Response objects plus this ValveContext instance. Exceptions thrown by
a subsequently executed Valve, Filter or Servlet will be passed on to
the caller.

If there are no more Valves to be executed, an appropriate
ServletException will be thrown by this ValveContext.

B<Parameters>

=over

=item $request

the B<Wombat::Request> to be processed

=item $response

the B<Wombat::Response> to be created

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if a servlet error occurs or is thrown by a subsequently invoked
Valve, Filter or Servlet, or if there are no further Valves configured
in the Pipeline currently being processed

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Exception>,
L<Wombat::Pipeline>,
L<Wombat::Request>,
L<Wombat::Response>,
L<Wombat::Valve>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
