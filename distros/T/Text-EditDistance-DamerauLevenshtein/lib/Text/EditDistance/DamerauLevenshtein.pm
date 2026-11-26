package Text::EditDistance::DamerauLevenshtein 0.03;
use v5.12;
use warnings;
use XSLoader ();
use Exporter qw(import);

our @EXPORT_OK = qw( dl_distance );

XSLoader::load;

1
__END__

=encoding utf-8

=head1 NAME

Text::EditDistance::DamerauLevenshtein - Damerau-Levenshtein edit distance

=head1 SYNOPSIS

=for highlighter language=perl

    use Text::EditDistance::DamerauLevenshtein qw(dl_distance);

    my $distance = dl_distance('flour', 'fluor');
    # 1

=head1 DESCRIPTION

The Damerau-Levenshtein edit distance between two strings is the minimum number
of operations required to transform one string into the other. The allowed
operations are:

=over

=item insertion

adding a single character anywhere in the string

=item deletion

removing any single character from the string

=item substitution

changing any single character into some other character

=item transposition

swapping any two adjacent characters

=back

(The related Levenshtein distance does not include transposition operations.)

This module provides code to compute the Damerau-Levenshtein distance in a
reasonably efficient manner.

=head2 Functions

=over

=item dl_distance FROM, TO

Computes and returns the Damerau-Levenshtein edit distance between between the
I<FROM> and I<TO> strings. As usual with Perl, "characters" are taken to be
(extended) Unicode code points: The distance between C<xyz> and C<x€z> is 1.

This function may fail by setting C<$!> and returning C<undef> in the following
cases (see L<Errno>):

=over

=item C<EILSEQ>

One of the arguments is in an inconsistent state and the string data cannot be
decoded. Normally this should not happen, but certain low-level Perl functions
can be (ab-)used to create scalars containing invalid data.

=item C<ENOMEM>

The function was unable to allocate memory for its data structures. You're
unlikely to see this unless your strings are truly gigantic.

=back

=back

=begin :README

=head1 INSTALLATION

To install this module, run the following commands:

=for highlighter language=sh

    perl Makefile.PL
    make
    make test
    make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Text::EditDistance::DamerauLevenshtein

You can also look for information at:

=over

=item *

MetaCPAN: L<https://metacpan.org/pod/Text::EditDistance::DamerauLevenshtein>

=item *

The source repository on Codeberg:
L<https://codeberg.org/mauke/Text-EditDistance-DamerauLevenshtein>

=item *

The module's bug tracker: L<https://codeberg.org/mauke/Text-EditDistance-DamerauLevenshtein/issues>

=back

=end :README

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026 Lukas Mai.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License (version 3) as published by
the Free Software Foundation.

See L<https://www.gnu.org/licenses/agpl-3.0.html#license-text> for more
information.
