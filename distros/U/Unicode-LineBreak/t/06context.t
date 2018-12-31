use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 2 }

dotest('fr', 'fr.ea', Context => 'EASTASIAN');
dotest('fr', 'fr', Context => 'EASTASIAN',
       EAWidth => [AMBIGUOUS_ALPHABETICS() => EA_N()]);
## obsoleted option.
#dotest('fr', 'fr', Context => 'EASTASIAN',
#       EAWidth => [[0x0041..0x005A, 0x0061..0x007A] => EA_A()],
#       TailorEA => [AMBIGUOUS_ALPHABETICS() => EA_N()]);

1;

