# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletContextEvent;

use base qw(Servlet::Util::Event);
use strict;
use warnings;

sub getServletContext {
    my $self = shift;

    return $self->getSource();
}

1;
__END__

=pod

=head1 NAME

Servlet::ServletContextEvent - servlet context event class

=head1 SYNOPSIS

  my $event = Servlet::ServletContextEvent->new($context);

  my $context = $event->getServletContext();
  # or
  my $context = $event->getSource();

=head1 DESCRIPTION

This is an event class for notifications about changes to the servlet
context of a web application.

=head1 CONSTRUCTOR

=over

=item new($context)

Construct an instance for the given context.

B<Parameters:>

=over

=item I<$context>

the servlet context that is the source of the event

=back

=back

=head1 METHODS

=over

=item getServletContext()

Returns the B<Servlet::ServletContext> object that is the source of
the event.

=item getSource()

Returns the B<Servlet::ServletContext> object that is the source of
the event.

=back

=head1 SEE ALSO

L<Servlet::ServletContext>,
L<Servlet::ServletContextAttributeListener>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
