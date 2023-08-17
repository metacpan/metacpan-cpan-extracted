package Pod::Elemental::Element::Generic::Text 0.103006;
# ABSTRACT: a Pod text or verbatim element

use Moose;
with 'Pod::Elemental::Flat';

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod Generic::Text elements represent text paragraphs found in raw Pod.  They are
#pod likely to be fed to a Pod5 translator and converted to ordinary, verbatim, or
#pod data paragraphs in that dialect.  Otherwise, Generic::Text paragraphs are
#pod simple flat paragraphs.
#pod
#pod =cut

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Generic::Text - a Pod text or verbatim element

=head1 VERSION

version 0.103006

=head1 OVERVIEW

Generic::Text elements represent text paragraphs found in raw Pod.  They are
likely to be fed to a Pod5 translator and converted to ordinary, verbatim, or
data paragraphs in that dialect.  Otherwise, Generic::Text paragraphs are
simple flat paragraphs.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
