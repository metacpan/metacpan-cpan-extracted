# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpSessionListener;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpSessionListener - session listener interface

=head1 SYNOPSIS

  $listener->sessionCreated($event);

  $listener->sessionDestroyed($event);

=head1 DESCRIPTION

Objects that implement this interface are notified of changes to the
list of active sessions in a web application. To receive notification
events, the implementation class must be configured in the deployment
descriptor for the web application.

=head1 METHODS

=over

=item sessoinCreated($event)

Notificatio that a session was created.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionEvent>

=back

=item valueUnbound($event)

Notification that a session was invalidated.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionEvent>

=back

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Servlet::Http::HttpSessionEvent>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
