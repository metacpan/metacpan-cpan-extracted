package Text::UnicodeStyle::SansSerif;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D5A0,
        lower => 0x1D5BA,
        digit => 0x1D7E2,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::SansSerif - mathematical sans-serif Latin letters and digits

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
