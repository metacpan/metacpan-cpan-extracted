package Text::UnicodeStyle::Fraktur;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D504,
        lower => 0x1D51E,
        fix => {
            C => 0x212D,
            H => 0x210C,
            I => 0x2111,
            R => 0x211C,
            Z => 0x2128,
        },
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Fraktur - mathematical fraktur Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
