# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpSessionBindingListener;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpSessionBindingListener - session binding listener interface

=head1 SYNOPSIS

  $listener->valueBound($event);

  $listener->valueUnbound($event);

=head1 DESCRIPTION

This listener interface causes an object to be notified when it is
bound to or unbound from a session. The object is notified by an
object implementing B<Servlet::Http::HttpSessionBindingEvent>. This
may be as a result of a servlet programmer explicitly unbinding an
attribute from a session or due to a session being invalidated or timing
out.

=head1 METHODS

=over

=item valueBound($event)

Notifies the object that it is being bound to a session.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionBindingEvent>

=back

=item valueUnbound($event)

Notifies the object that it is being unbound from a session.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionBindingEvent>

=back

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Servlet::Http::HttpSessionBindingEvent>,

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
