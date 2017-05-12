#!perl -T

use Test::More;
use lib qw(t/lib/);
use_ok('UtilDefaultKinds' => -all);

ok(defined &uniq);
ok(defined &isweak);
ok(defined &camelize);

done_testing;
