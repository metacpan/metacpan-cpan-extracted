package WWW::Picnic::Result::Cart;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Picnic shopping cart / order

use Moo;

extends 'WWW::Picnic::Result';


has id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('id') },
);


has type => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('type') },
);


has status => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('status') },
);


has items => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('items') || [] },
);


has total_count => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('total_count') || 0 },
);


has total_price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('total_price') || 0 },
);


has checkout_total_price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('checkout_total_price') || 0 },
);


has delivery_slots => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('delivery_slots') || [] },
);


has selected_slot => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('selected_slot') },
);


has deposit_breakdown => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('deposit_breakdown') || [] },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::Cart - Picnic shopping cart / order

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    my $cart = $picnic->get_cart;
    say "Total: ", $cart->total_price / 100, " EUR";
    say "Items: ", $cart->total_count;

    for my $item (@{ $cart->items }) {
        say $item->{name}, " x ", $item->{count};
    }

=head1 DESCRIPTION

Represents a Picnic shopping cart (which is also an order). Contains
items, pricing, and delivery slot information.

=head2 id

Cart identifier, typically C<shopping_cart>.

=head2 type

Cart type, typically C<ORDER>.

=head2 status

Current status of the cart/order.

=head2 items

Arrayref of order lines/items in the cart. Each item contains product
details, quantity, and pricing.

=head2 total_count

Total number of items in the cart.

=head2 total_price

Total price in cents. Divide by 100 to get the price in EUR.

=head2 checkout_total_price

Total price at checkout in cents, may include delivery fees.

=head2 delivery_slots

Arrayref of available delivery slots for this cart.

=head2 selected_slot

Currently selected delivery slot, if any.

=head2 deposit_breakdown

Arrayref of deposit charges (bottles, crates, etc.).

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
