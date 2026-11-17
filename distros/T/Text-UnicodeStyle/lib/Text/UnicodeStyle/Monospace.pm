package Text::UnicodeStyle::Monospace;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D670,
        lower => 0x1D68A,
        digit => 0x1D7F6,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Monospace - mathematical monospace Latin letters and digits

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
