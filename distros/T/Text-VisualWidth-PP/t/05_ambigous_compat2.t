use strict;
use warnings;
use utf8;
use Test::More;
use Unicode::EastAsianWidth;
use Text::VisualWidth::PP;

# T::VW::PP thinks ambigous char is half width by *default*.

# HYPHEN, an ambiguous-width character
my $AMBIGIOUSCHAR = "\x{2010}";

is(Text::VisualWidth::PP::width($AMBIGIOUSCHAR), 1);

done_testing;

