use strict;
use warnings;

use Test::More 0.88;

pass 'here is a passing test, to keep plan happy';

BEGIN { $ENV{FOO} = $ENV{BAR} = 0 };
use if $ENV{FOO} || $ENV{BAR}, 'Test::Warnings';

use if "$]" >= '5.008', lib => 't/lib';
use if "$]" >= '5.008', 'SilenceStderr';

warn 'this is not a fatal warning, because Test::Warnings is not loaded';

done_testing;
