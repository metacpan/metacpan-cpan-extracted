use strict;
use warnings;
use utf8;
use Test::More;
BEGIN { $Unicode::EastAsianWidth::EastAsian = 1; }
use Unicode::EastAsianWidth;
BEGIN { $Unicode::EastAsianWidth::EastAsian = 1; }
use Text::VisualWidth::PP;

# T::VW::PP thinks ambigous char is full width when $U::EAW::EastAsian is true.

# HYPHEN, an ambiguous-width character
my $AMBIGIOUSCHAR = "\x{2010}";

is(Text::VisualWidth::PP::width($AMBIGIOUSCHAR), 2);

my $AMBIGIOUSSTR = "\x{2010}" x 4;

is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 2), "\x{2010}");
is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 3), "\x{2010}");
is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 4), "\x{2010}" x 2);

done_testing;

