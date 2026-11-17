package Text::UnicodeStyle::Circled;
use strict;
use warnings;

sub table {
    return {
        upper => 0x24B6,
        lower => 0x24D0,
        digit => 0x245F,
        fix => {
            '0' => 0x24EA,
        },
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Circled - circled Latin letters and digits

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
