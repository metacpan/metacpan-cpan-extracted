# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpSessionBindingEvent;

use base qw(Servlet::Http::HttpSessionEvent);
use fields qw(name value);
use strict;
use warnings;

sub new {
    my $self = shift;
    my $session = shift;
    my $name = shift;
    my $value = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new($session);

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

Servlet::Http::HttpSessionBindingEvent - session binding event class

=head1 SYNOPSIS

  my $event =
      Servlet::Http::HttpSessionEvent->new($session, $attribute, $value);

  my $name = $event->getName();
  my $value = $event->getValue();

  my $session = $event->getSession();
  # or
  my $session = $event->getSource();

=head1 DESCRIPTION

This class represents event notifications for changes to session
attributes. The event is either sent to an object that implements
B<Servlet::Http::HttpSessionBindingListener> when it is bound or
unbound from a session, or to a
B<Servlet::Http::HttpSessionAttributesListener> that has been
configured in the deployment descriptor when any attribute is bound,
unbound or replaced in a session.

=head1 CONSTRUCTOR

=over

=item new($session, $name, [$value])

Constructs an event that notifies an object that it has been bound to
or unbound from a session. To receive the event, the object must
implement B<Servlet::Http::HttpSessionBindingListener>.

B<Parameters:>

=over

=item I<$session>

the B<Servlet::Http::HttpSession> instance to which the object is
bound or unbound

=item I<$name>

the name with which the object is bound or unbound

=back

=item I<$object>

the scalar or reference that is bound or unbound

=back

=head1 METHODS

=over

=item getName()

Returns the name with which the object is bound to or unbound from the
session.

=item getSession()

Returns the B<Servlet::Http::HttpSession> that is the source of this event.

=item getSource()

Returns the B<Servlet::Http::HttpSession> that is the source of this event.

=item getValue()

Returns the value of the attribute being added, removed or
replaced. If the attribute was added (or bound), this is the value of
the attribute. If the attribute was removed (or unbound), this is the
value of the removed attribute. If the attribute was replaced, this is
the old value of the attribute.

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Servlet::Http::HttpSessionEvent>,
L<Servlet::Http::HttpSessionAttributesListener>,
L<Servlet::Http::HttpSessionBindingListener>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
