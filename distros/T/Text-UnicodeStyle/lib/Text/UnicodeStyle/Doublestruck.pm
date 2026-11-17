package Text::UnicodeStyle::Doublestruck;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D538,
        lower => 0x1D552,
        digit => 0x1D7D8,
        fix => {
            C => 0x2102,
            H => 0x210D,
            N => 0x2115,
            P => 0x2119,
            Q => 0x211A,
            R => 0x211D,
            Z => 0x2124,
        },
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Doublestruck - mathematical double-struck Latin letters and digits

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
