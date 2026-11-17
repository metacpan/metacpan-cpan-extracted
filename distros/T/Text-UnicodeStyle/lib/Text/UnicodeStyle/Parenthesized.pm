package Text::UnicodeStyle::Parenthesized;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1F110,
        lower => 0x249C,
        digit => 0x2473,
        fix => {
            '0' => 0x30,
        },
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Parenthesized - parenthesized Latin letters and digits

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
