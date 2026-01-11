package WWW::Picnic::Result::Article;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Detailed Picnic product/article information

use Moo;

extends 'WWW::Picnic::Result';


has id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('id') },
);


has name => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('name') },
);


has description => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('description') },
);


has type => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('type') },
);


has images => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('images') || [] },
);


has image_ids => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('image_ids') || [] },
);


has price_info => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('price_info') || {} },
);


sub price {
  my ( $self ) = @_;
  return $self->price_info->{price};
}


sub original_price {
  my ( $self ) = @_;
  return $self->price_info->{original_price};
}


sub deposit {
  my ( $self ) = @_;
  return $self->price_info->{deposit};
}


has unit_quantity => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('unit_quantity') },
);


has max_order_quantity => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('max_order_quantity') },
);


has labels => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('labels') || [] },
);


has allergies => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('allergies') || {} },
);


has highlights => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('highlights') || [] },
);


has perishable => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('perishable') },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::Article - Detailed Picnic product/article information

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    my $article = $picnic->get_article($product_id);
    say $article->name;
    say $article->description;
    say "Price: ", $article->price / 100, " EUR";

=head1 DESCRIPTION

Represents detailed product information including description,
nutritional info, allergens, and pricing details.

=head2 id

Product identifier.

=head2 name

Product name.

=head2 description

Full product description.

=head2 type

Product type.

=head2 images

Arrayref of image identifiers.

=head2 image_ids

Arrayref of image IDs.

=head2 price_info

Hashref containing pricing details: C<price>, C<original_price>,
C<deposit>, C<base_price_text>.

=head2 price

Returns the current price in cents.

=head2 original_price

Returns the original price in cents (before discount).

=head2 deposit

Returns deposit amount in cents, if any.

=head2 unit_quantity

Quantity/unit description (e.g., "500g", "1L").

=head2 max_order_quantity

Maximum quantity that can be ordered at once.

=head2 labels

Arrayref of product labels (organic, vegan, etc.).

=head2 allergies

Hashref containing allergy information: C<allergy_contains> (arrayref)
and C<allergy_text>.

=head2 highlights

Arrayref of product highlights/features.

=head2 perishable

Boolean indicating if product is perishable.

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
