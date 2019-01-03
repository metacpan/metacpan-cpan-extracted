package Pod::Elemental::Objectifier;
# ABSTRACT: it turns a Pod::Eventual event stream into objects
$Pod::Elemental::Objectifier::VERSION = '0.103004';
use Moose;

#pod =head1 OVERVIEW
#pod
#pod An objectifier is responsible for taking the events produced by
#pod L<Pod::Eventual|Pod::Eventual> and converting them into objects that perform
#pod the Pod::Elemental::Paragraph role.
#pod
#pod In general, it does this by producing a sequence of element objects in the
#pod Pod::Elemental::Element::Generic namespace.
#pod
#pod =cut

use namespace::autoclean;

use Pod::Elemental::Element::Generic::Blank;
use Pod::Elemental::Element::Generic::Command;
use Pod::Elemental::Element::Generic::Nonpod;
use Pod::Elemental::Element::Generic::Text;

#pod =method objectify_events
#pod
#pod   my $elements = $objectifier->objectify_events(\@events);
#pod
#pod Given an arrayref of Pod events, this method returns an arrayref of objects
#pod formed from the event stream.
#pod
#pod =cut

sub objectify_events {
  my ($self, $events) = @_;
  return [ map {
    Carp::croak("not a valid event") unless ref $_;

    my $class = $self->element_class_for_event($_);

    my %guts = (
      content    => $_->{content},
      start_line => $_->{start_line},

      ($_->{type} eq 'command' ? (command => $_->{command}) : ()),
    );

    $class->new(\%guts);
  } @$events ];
}


#pod =method element_class_for_event
#pod
#pod This method returns the name of the class to be used for the given event.
#pod
#pod =cut

sub __class_for {
  return {
    blank    => 'Pod::Elemental::Element::Generic::Blank',
    command  => 'Pod::Elemental::Element::Generic::Command',
    nonpod   => 'Pod::Elemental::Element::Generic::Nonpod',
    text     => 'Pod::Elemental::Element::Generic::Text',
  };
}

sub element_class_for_event {
  my ($self, $event) = @_;
  my $t = $event->{type};
  my $class_for = $self->__class_for;

  Carp::croak "unknown event type: $t" unless exists $class_for->{ $t };

  return $class_for->{ $t };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Objectifier - it turns a Pod::Eventual event stream into objects

=head1 VERSION

version 0.103004

=head1 OVERVIEW

An objectifier is responsible for taking the events produced by
L<Pod::Eventual|Pod::Eventual> and converting them into objects that perform
the Pod::Elemental::Paragraph role.

In general, it does this by producing a sequence of element objects in the
Pod::Elemental::Element::Generic namespace.

=head1 METHODS

=head2 objectify_events

  my $elements = $objectifier->objectify_events(\@events);

Given an arrayref of Pod events, this method returns an arrayref of objects
formed from the event stream.

=head2 element_class_for_event

This method returns the name of the class to be used for the given event.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
