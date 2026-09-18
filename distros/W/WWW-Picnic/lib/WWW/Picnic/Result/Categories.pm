package WWW::Picnic::Result::Categories;
# ABSTRACT: Collection of Picnic store categories
our $VERSION = '0.101';
use Moo;

extends 'WWW::Picnic::Result';


has catalog => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('catalog') || [] },
);


sub all_categories {
  my ( $self ) = @_;
  return @{ $self->catalog };
}


sub total_count {
  my ( $self ) = @_;
  return scalar @{ $self->catalog };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::Categories - Collection of Picnic store categories

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $categories = $picnic->get_categories;
    say "Found ", $categories->total_count, " categories";

    for my $category ($categories->all_categories) {
        say $category->{name};
    }

=head1 DESCRIPTION

Container for the product categories returned by the store landing
(C<my_store>) endpoint. Provides access to the list of category entries.

=head2 catalog

Arrayref of category entries from the store landing response.

=head2 all_categories

Returns list of all category entries (as opposed to arrayref).

=head2 total_count

Returns total number of categories.

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
