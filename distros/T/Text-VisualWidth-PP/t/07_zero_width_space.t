use strict;
use warnings;
use utf8;
use Test::More tests => 6;
BEGIN { use_ok('Text::VisualWidth::PP') };

is( Text::VisualWidth::PP::width("\N{U+200B}") => 0, 'U+200B ZERO WIDTH SPACE');
is( Text::VisualWidth::PP::width("\N{U+200C}") => 0, 'U+200C ZERO WIDTH NON-JOINER');
is( Text::VisualWidth::PP::width("\N{U+200D}") => 0, 'U+200D ZERO WIDTH JOINER');
is( Text::VisualWidth::PP::width("\N{U+0301}") => 0, 'U+0301 COMBINING ACUTE ACCENT');
is( Text::VisualWidth::PP::width("\N{U+FEFF}") => 0, 'U+FEFF ZERO WIDTH NO-BREAK SPACE');
