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

done_testing;

