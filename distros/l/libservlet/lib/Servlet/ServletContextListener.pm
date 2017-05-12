# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletContextListener;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletContextListener - context listener interface

=head1 SYNOPSIS

  $listener->contextInitialized($event)

  $listener->contextDestroyed($event);

=head1 DESCRIPTION

Implementations of this interface receive notifications about changes
to the servlet context of the web application they are a part of. To
receive notification events, the implementation class must be
configured in the deployment descriptor for the web application.

=head1 METHODS

For each of the following methods, the event passed to the method is
of type B<Servlet::ServletContextEvent>.

=over

=item contextDestroyed($event)

Notification that the servlet context is about to be shut down.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::ContextEvent>

=back

=item contextInitialized($event)

Notification that the web application is ready to process requests.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::ContextEvent>

=back

=back

=head1 SEE ALSO

L<Servlet::ServletContext>,
L<Servlet::ContextEvent>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
