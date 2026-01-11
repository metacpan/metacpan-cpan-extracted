package WWW::Picnic::Result::SearchResult;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Picnic product search result item

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


has display_price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('display_price') },
);


has price => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('price') },
);


has image_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('image_id') },
);


has unit_quantity => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('unit_quantity') },
);


has max_count => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('max_count') },
);


has decorators => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('decorators') || [] },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::SearchResult - Picnic product search result item

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    my $results = $picnic->search('apple');
    for my $item ($results->all_items) {
        say $item->name;
        say "Price: ", $item->display_price;
    }

=head1 DESCRIPTION

Represents a single item from search results. Contains basic product
information suitable for display in search result lists.

=head2 id

Product identifier.

=head2 name

Product name.

=head2 display_price

Formatted price string for display.

=head2 price

Price in cents.

=head2 image_id

Identifier for the product image.

=head2 unit_quantity

Quantity/unit description (e.g., "500g", "1L").

=head2 max_count

Maximum quantity that can be ordered.

=head2 decorators

Arrayref of decorators (badges, labels, etc.) for UI display.

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
