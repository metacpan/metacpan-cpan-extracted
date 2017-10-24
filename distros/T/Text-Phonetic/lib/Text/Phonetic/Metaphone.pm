# ============================================================================
package Text::Phonetic::Metaphone;
# ============================================================================
use utf8;

use Moo;
extends qw(Text::Phonetic);

has 'max_length'=> (
    is              => 'rw',
    isa             => sub {
        die 'max_length must be an int' unless shift =~ /\d/
    },
    documentation   => q[Limit the length of the encoded string],
    default         => 0,
);

our $VERSION = $Text::Phonetic::VERSION;

sub _predicates {
    return 'Text::Metaphone';
}

sub _do_encode {
    my ($self,$string) = @_;

    return Text::Metaphone::Metaphone($string,$self->max_length);
}

1;

=encoding utf8

=pod

=head1 NAME

Text::Phonetic::Metaphone - Metaphone algorithm

=head1 DESCRIPTION

Metaphone was developed by Lawrence Philips as a response to deficiencies in
the Soundex algorithm. It is more accurate than Soundex because it uses a
larger set of rules for English pronunciation. (Wikipedia, 2007)

This module is a thin wrapper around L<Text::Metaphone>.

The parameter C<max_length> can be set to limit the length of the encoded
string.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

Text::Phonetic::Metaphone is Copyright (c) 2006,2007 Maroš. Kollár.
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Description of the algorithm can be found at
L<http://en.wikipedia.org/wiki/Metaphone>

L<Text::Metaphone>

=cut
