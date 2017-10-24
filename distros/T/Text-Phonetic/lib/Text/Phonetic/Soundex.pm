# ============================================================================
package Text::Phonetic::Soundex;
# ============================================================================
use utf8;

use Moo;
extends qw(Text::Phonetic);

has 'nara'=> (
    is              => 'rw',
    documentation   => q[Use the soundex variant maintained by the National Archives and Records Administration (NARA)],
    default         => 0,
);

has 'nocode'=> (
    is              => 'rw',
    documentation   => q[Redefine the value that will be returned if the input string contains no identifiable sounds within it],
    predicate       => 'has_nocode',
);

our $VERSION = $Text::Phonetic::VERSION;

sub _predicates {
    return 'Text::Soundex';
}

sub _do_encode {
    my ($self,$string) = @_;

    if ($self->has_nocode) {
        $Text::Soundex::nocode = $self->nocode;
    }

    if ($self->nara) {
        return Text::Soundex::soundex_nara($string);
    } else {
        return Text::Soundex::soundex($string);
    }
}

1;

=encoding utf8

=pod

=head1 NAME

Text::Phonetic::Soundex - Soundex algorithm

=head1 DESCRIPTION

Soundex is a phonetic algorithm for indexing names by sound, as pronounced in
English. Soundex is the most widely known of all phonetic algorithms.
Improvements to Soundex are the basis for many modern phonetic algorithms.
(Wikipedia, 2007)

If the parameter C<nara> is set to a true value, a variant of the soundex
algorithm maintained by the National Archives and Records Administration
(NARA) will be used.

If the parameter C<nocode> redefines the value that will be returned if the
input string contains no identifiable sounds within it.

This module is a thin wrapper around L<Text::Soundex>.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

Text::Phonetic::Soundex is Copyright (c) 2006,2007 Maroš. Kollár.
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Description of the algorithm can be found at
L<http://en.wikipedia.org/wiki/Soundex>

L<Text::Soundex>

=cut
