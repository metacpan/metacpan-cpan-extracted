package Text::UnicodeStyle::SansSerifBold;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D5D4,
        lower => 0x1D5EE,
        digit => 0x1D7EC,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::SansSerifBold - mathematical sans-serif bold Latin letters and digits

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
