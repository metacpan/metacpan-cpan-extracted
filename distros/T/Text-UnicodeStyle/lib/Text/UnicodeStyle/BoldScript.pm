package Text::UnicodeStyle::BoldScript;
use strict;
use warnings;

sub table {
    return {
        upper => 0x1D4D0,
        lower => 0x1D4EA,
    };
}

1;

=head1 NAME

Text::UnicodeStyle::BoldScript - mathematical bold script Latin letters

=head1 DESCRIPTION

Style table for L<Text::UnicodeStyle>: see its documentation for
details on the C<table()> format and the C<stylize()> function.

=head1 SEE ALSO

L<Text::UnicodeStyle>

=cut
