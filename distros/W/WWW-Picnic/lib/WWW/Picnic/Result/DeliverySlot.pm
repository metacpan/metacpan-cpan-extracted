package WWW::Picnic::Result::DeliverySlot;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Picnic delivery time slot

use Moo;

extends 'WWW::Picnic::Result';


has slot_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('slot_id') },
);


has hub_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('hub_id') },
);


has fc_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('fc_id') },
);


has window_start => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('window_start') },
);


has window_end => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('window_end') },
);


has cut_off_time => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('cut_off_time') },
);


has is_available => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('is_available') },
);


has unavailability_reason => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('unavailability_reason') },
);


has minimum_order_value => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('minimum_order_value') },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::DeliverySlot - Picnic delivery time slot

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    my $slots = $picnic->get_delivery_slots;
    for my $slot (@{ $slots->delivery_slots }) {
        say $slot->window_start, " - ", $slot->window_end;
        say "Available: ", $slot->is_available ? "yes" : "no";
    }

=head1 DESCRIPTION

Represents an available delivery time slot with start/end times,
availability status, and minimum order requirements.

=head2 slot_id

Unique identifier for this delivery slot.

=head2 hub_id

Identifier of the delivery hub.

=head2 fc_id

Identifier of the fulfillment center.

=head2 window_start

Start time of the delivery window (ISO 8601 timestamp).

=head2 window_end

End time of the delivery window (ISO 8601 timestamp).

=head2 cut_off_time

Latest time to place an order for this slot (ISO 8601 timestamp).

=head2 is_available

Boolean indicating if this slot can be selected.

=head2 unavailability_reason

Reason why slot is unavailable, if C<is_available> is false.

=head2 minimum_order_value

Minimum order value in cents required for this slot.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-picnic/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
