use strict;
use warnings;
use Test::More tests => 1;

use lib 't/lib';

use lib::xi 'extlib';

use Foo;

is(Foo->bar, 'ok');

