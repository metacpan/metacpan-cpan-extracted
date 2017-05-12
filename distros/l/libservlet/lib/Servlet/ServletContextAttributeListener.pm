# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletContextAttributeListener;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletContextAttributeListener - context attribute listener interface

=head1 SYNOPSIS

  $listener->attributeAdded($event);

  $listener->attributeReplaced($event)

  $listener->attributeRemoved($event)

=head1 DESCRIPTION

Implementations of this interface receive notifications of changes to
the attribute list on the servlet context of a web application. To
receive notification events, the implementation class must be
configured in the deployment descriptor for the web application.

=head1 METHODS

For each of the following methods, the event passed to the method is
of type B<Servlet::ServletContextAttributeEvent>.

=over

=item attributeAdded($event)

Notification that a new attribute was added to the servlet
context. Called after the attribute is added.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::ContextAttributeEvent>

=back

=item attributeRemoved($event)

Notification that an existing attribute was removed from the servlet
context. Called after the attribute is removed.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::ContextAttributeEvent>

=back

=item attributeReplaceded($event)

Notification that an existing attribute on servlet context was
replaced. Called after the attribute is replaced.

B<Parameters:>

=over

=item I<$event>

an instance of B<Servlet::ContextAttributeEvent>

=back

=back

=head1 SEE ALSO

L<Servlet::ServletContext>,
L<Servlet::ContextAttributeEvent>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
