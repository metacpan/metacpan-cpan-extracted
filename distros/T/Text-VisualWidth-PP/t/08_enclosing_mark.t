use strict;
use warnings;
use utf8;
use Test::More;

BEGIN { use_ok('Text::VisualWidth::PP') };

is( Text::VisualWidth::PP::width("\N{U+20DD}") => 0, 'U+20DD COMBINING ENCLOSING CIRCLE');
is( Text::VisualWidth::PP::width("\N{U+20DE}") => 0, 'U+20DE COMBINING ENCLOSING SQUARE');
is( Text::VisualWidth::PP::width("\N{U+20DF}") => 0, 'U+20DF COMBINING ENCLOSING DIAMOND');
is( Text::VisualWidth::PP::width("\N{U+20E0}") => 0, 'U+20E0 COMBINING ENCLOSING CIRCLE BACKSLASH');
is( Text::VisualWidth::PP::width("\N{U+20E2}") => 0, 'U+20E2 COMBINING ENCLOSING SCREEN');

done_testing;
