package Text::UnicodeStyle::Script;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D49C,
        lower => 0x1D4B6,
        fix => {
            B => 0x212C,
            E => 0x2130,
            F => 0x2131,
            H => 0x210B,
            I => 0x2110,
            L => 0x2112,
            M => 0x2133,
            R => 0x211B,
            e => 0x212F,
            g => 0x210A,
            o => 0x2134,
        },
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Script - mathematical script Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
