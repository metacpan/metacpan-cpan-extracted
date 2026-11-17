package Text::UnicodeStyle::Italic;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D434,
        lower => 0x1D44E,
        fix => {
            h => 0x210E,
        },
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Italic - mathematical italic Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
