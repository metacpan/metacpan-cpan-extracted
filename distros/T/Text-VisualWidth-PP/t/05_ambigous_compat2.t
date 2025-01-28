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

my $AMBIGIOUSSTR = "\x{2010}" x 4;

is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 2), "\x{2010}" x 2);
is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 3), "\x{2010}" x 3);
is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 4), "\x{2010}" x 4);


# Change $T::VW::PP::EastAsian on the fly
$Text::VisualWidth::PP::EastAsian = 1;

is(Text::VisualWidth::PP::width($AMBIGIOUSCHAR), 2);

is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 2), "\x{2010}" x 1);
is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 3), "\x{2010}" x 1);
is(Text::VisualWidth::PP::trim($AMBIGIOUSSTR, 4), "\x{2010}" x 2);

done_testing;

