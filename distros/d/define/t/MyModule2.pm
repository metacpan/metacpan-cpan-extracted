package MyModule2;

use strict;
use Test;

no define;

ok(FOO, 1);
ok(BAR, 0);

sub new {
  bless { }, shift;
}

use define GOO => __PACKAGE__->new;

1;