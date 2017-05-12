# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpSessionAttributesListener;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpSessionAttributesListener - session listener interface

=head1 SYNOPSIS

  $listener->attributeAdded($event);

  $listener->attributeRemoved($event);

  $listener->attributeReplaced($event);

=head1 DESCRIPTION

This listener interface can be implemented in order to get
notifications of changes made to sessions within this web application.

=head1 METHODS

=over

=item attributeAdded($event)

Notification that an attribute has been added to a session.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionBindingEvent>

=back

=item attributeRemoved($event)

Notification that an attribute has been removed from a session.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionBindingEvent>

=back

=item attributeReplaced($event)

Notification that an attribute has been replaced in a session.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::Http::HttpSessionBindingEvent>

=back

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Servlet::Http::HttpSessionEvent>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
