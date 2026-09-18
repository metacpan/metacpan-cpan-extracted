package WWW::Picnic::Result::DeliverySlots;
# ABSTRACT: Collection of Picnic delivery slots
our $VERSION = '0.101';
use Moo;

extends 'WWW::Picnic::Result';

use WWW::Picnic::Result::DeliverySlot;


has delivery_slots => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $slots = $self->_get('delivery_slots') || [];
    return [ map { WWW::Picnic::Result::DeliverySlot->new($_) } @$slots ];
  },
);


sub all_slots {
  my ( $self ) = @_;
  return @{ $self->delivery_slots };
}


sub available_slots {
  my ( $self ) = @_;
  return grep { $_->is_available } $self->all_slots;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::DeliverySlots - Collection of Picnic delivery slots

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $result = $picnic->get_delivery_slots;
    for my $slot ($result->all_slots) {
        next unless $slot->is_available;
        say $slot->window_start, " - ", $slot->window_end;
    }

=head1 DESCRIPTION

Container for delivery slot results from the API. Provides access to
the list of available delivery time slots.

=head2 delivery_slots

Arrayref of L<WWW::Picnic::Result::DeliverySlot> objects.

=head2 all_slots

Returns list of all delivery slots (as opposed to arrayref).

=head2 available_slots

Returns list of only available delivery slots.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-picnic/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
