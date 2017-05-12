use strict;
use warnings;
use Test::More tests => 1;
use Text::Levenshtein::Damerau::XS;

my @a;
$a[48] = 1;
$a[49] = 2;
$a[50] = 1;

my @b;
$b[48] = 2;
$b[49] = 1;
$b[50] = 1;

warn("\n\nBelow Uninit warnings are intentional\n\n");
is( Text::Levenshtein::Damerau::XS::cxs_edistance(\@a,\@b,0), 1, 'test csx_edistance NULL bug');
warn("\n\nAbove Uninit warnings were intentional\n\n");