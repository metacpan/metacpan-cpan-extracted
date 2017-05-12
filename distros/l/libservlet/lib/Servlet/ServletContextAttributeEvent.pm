# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletContextAttributeEvent;

use base qw(Servlet::ServletContextEvent);
use fields qw(name value);
use strict;
use warnings;

sub new {
    my $self = shift;
    my $source = shift;
    my $name = shift;
    my $value = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new($source);

    $self->{name} = $name;
    $self->{value} = $value;

    return $self;
}

sub getName {
    my $self = shift;

    return $self->{name};
}

sub getValue {
    my $self = shift;

    return $self->{value};
}

1;
__END__

=pod

=head1 NAME

Servlet::ServletContextAttributeEvent - servlet context attribute event class

=head1 SYNOPSIS

  my $event = Servlet::ServletContextAttributeEvent->new($context, $name,
                                                         $value);

  my $name = $event->getName();
  my $object = $event->getValue();

  my $context = $event->getServletContext();
  # or
  my $context = $event->getSource();

=head1 DESCRIPTION

This is an event class for notifications about changes to the
attributes of the servlet context of a web application.

=head1 CONSTRUCTOR

=over

=item new($context, $name, $value)

Construct an instance for the given context, attribute name and
attribute value.

B<Parameters:>

=over

=item I<$context>

the servlet context that is the source of the event

=item I<$name>

the name of the affected servlet context attribute

=item I<$value>

the value of the affected servlet context attribute

=back

=back

=head1 METHODS

=over

=item getName()

Returns the name of the affected servlet context attribute.

=item getServletContext()

Returns the B<Servlet::ServletContext> object that is the source of
the event.

=item getSource()

Returns the B<Servlet::ServletContext> object that is the source of
the event.

=item getValue()

Returns the value of the affected servlet context attribute. If the
attribute was added, this is the value of the attribute. If the
attribute was removed, this is the value of the removed attribute. If
the attribute was replaced, this is the old value of the attribute.

=back

=head1 SEE ALSO

L<Servlet::ServletContext>,
L<Servlet::ServletContextAttributeListener>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
