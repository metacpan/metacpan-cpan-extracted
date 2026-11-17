package Text::UnicodeStyle::Bold;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D400,
        lower => 0x1D41A,
        digit => 0x1D7CE,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::Bold - mathematical bold Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
