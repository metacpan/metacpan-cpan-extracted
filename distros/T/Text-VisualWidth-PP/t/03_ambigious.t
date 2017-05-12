use strict;
use warnings;
use utf8;
use Test::More;
use Unicode::EastAsianWidth;
use Text::VisualWidth::PP;

# HYPHEN, an ambiguous-width character
my $AMBIGIOUSCHAR = "\x{2010}";

is(Text::VisualWidth::PP::width($AMBIGIOUSCHAR), 1);
$Text::VisualWidth::PP::EastAsian = 1;
is(Text::VisualWidth::PP::width($AMBIGIOUSCHAR), 2);

done_testing;

