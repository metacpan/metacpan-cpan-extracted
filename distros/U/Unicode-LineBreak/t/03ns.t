use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 2 }

dotest('ja-k', 'ja-k', ColumnsMax => 72);
dotest('ja-k', 'ja-k.ns', LBClass => [KANA_NONSTARTERS() => LB_ID()],
       ColumnsMax => 72);
## obsoleted option.
#dotest('ja-k', 'ja-k.ns', LBClass => [[0x3041..0x30A0] => LB_NS()],
#       TailorLB => [KANA_NONSTARTERS() => LB_ID()],
#       ColumnsMax => 72);

1;

