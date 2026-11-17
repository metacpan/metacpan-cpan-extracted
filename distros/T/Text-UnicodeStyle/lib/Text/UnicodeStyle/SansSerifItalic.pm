package Text::UnicodeStyle::SansSerifItalic;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D608,
        lower => 0x1D622,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::SansSerifItalic - mathematical sans-serif italic Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
