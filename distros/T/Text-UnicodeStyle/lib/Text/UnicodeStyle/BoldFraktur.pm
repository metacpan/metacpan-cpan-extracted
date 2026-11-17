package Text::UnicodeStyle::BoldFraktur;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D56C,
        lower => 0x1D586,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::BoldFraktur - mathematical bold fraktur Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
