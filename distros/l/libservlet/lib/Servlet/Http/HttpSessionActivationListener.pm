# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpSessionActivationListener;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpSessionActivationListener - session listener interface

=head1 SYNOPSIS

  $listener->sessionDidActivated($event);

  $listener->sessionWillPassivate($event);

=head1 DESCRIPTION

Objects that are bound to a session may listen to container events
notifying them that sessions will be passivated or activated. A
container that migrates sessions between interpreters or persists
sessions is required to notify all attributes bound to sessions
implementing this interface.

=head1 METHODS

=over

=item sessionDidActivate($event)

Notification that the session has just been activated.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionEvent>

=back

=item sessionWillPassivate($event)

Notification that the session is about to be passivated.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionEvent>

=back

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Servlet::Http::HttpSessionEvent>,

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
