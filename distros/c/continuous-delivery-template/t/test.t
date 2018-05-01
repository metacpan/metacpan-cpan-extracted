use strict;
use Test;

BEGIN {
  plan tests => 1
}

use continuous::delivery::template;

ok( continuous::delivery::template->hello(), qr/^Hello!/ );
