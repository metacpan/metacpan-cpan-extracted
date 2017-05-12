use strict;
use Test::More tests => 2;
BEGIN { use_ok('thanks') };

ok(strict->can('unimport'));
