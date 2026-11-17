package Text::UnicodeStyle::Fullwidth;
use strict;
use warnings;

sub table {
    return {
        upper => 0xFF21,
        lower => 0xFF41,
        digit => 0xFF10,
        punct => 0xFEE0,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Fullwidth - fullwidth forms of ASCII letters, digits and punctuation

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
