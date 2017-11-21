use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use Text::VisualPrintf;

# single half-width kana is special
is( Text::VisualPrintf::sprintf( "%s-%2s-%3s", qw"ｱ ｲ ｳ"),  "ｱ- ｲ-  ｳ", 'half %s' );

done_testing;
