package Pod::Elemental::Element::Pod5::Ordinary;
# ABSTRACT: a Pod5 ordinary text paragraph
$Pod::Elemental::Element::Pod5::Ordinary::VERSION = '0.103004';
use Moose;
extends 'Pod::Elemental::Element::Generic::Text';
with    'Pod::Elemental::Autoblank';
with    'Pod::Elemental::Autochomp';

# BEGIN Autochomp Replacement
use Pod::Elemental::Types qw(ChompedString);
has '+content' => (coerce => 1, isa => ChompedString);
# END   Autochomp Replacement

#pod =head1 OVERVIEW
#pod
#pod A Pod5::Ordinary element represents a plain old paragraph of text found in a
#pod Pod document that's gone through the Pod5 translator.
#pod
#pod =cut

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Pod5::Ordinary - a Pod5 ordinary text paragraph

=head1 VERSION

version 0.103004

=head1 OVERVIEW

A Pod5::Ordinary element represents a plain old paragraph of text found in a
Pod document that's gone through the Pod5 translator.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
