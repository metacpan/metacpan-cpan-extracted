package MyModule1;

use strict;
use Test;

no define FOO =>;
no define BAR =>;
no define BAZ =>;

ok(FOO, 1);
ok(BAR, 0);
ok(BAZ, undef);

sub test {
  return FOO + BAZ + BAR;
}

1;