package Pod::Elemental::Element::Pod5::Data;
# ABSTRACT: a Pod data paragraph
$Pod::Elemental::Element::Pod5::Data::VERSION = '0.103004';
use Moose;
extends 'Pod::Elemental::Element::Generic::Text';

#pod =head1 OVERVIEW
#pod
#pod Pod5::Data paragraphs represent the content of
#pod L<Pod5::Region|Pod::Elemental::Element::Pod5::Region> paragraphs when the
#pod region is not a Pod-like region.  These regions should generally have a single
#pod data element contained in them.
#pod
#pod =cut

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Pod5::Data - a Pod data paragraph

=head1 VERSION

version 0.103004

=head1 OVERVIEW

Pod5::Data paragraphs represent the content of
L<Pod5::Region|Pod::Elemental::Element::Pod5::Region> paragraphs when the
region is not a Pod-like region.  These regions should generally have a single
data element contained in them.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
