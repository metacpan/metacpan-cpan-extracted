package Text::UnicodeStyle::BoldItalic;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D468,
        lower => 0x1D482,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::BoldItalic - mathematical bold italic Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
