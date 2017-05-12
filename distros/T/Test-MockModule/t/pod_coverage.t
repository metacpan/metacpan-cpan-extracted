use warnings;
use strict;

use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing pod coverage" if $@;
all_pod_coverage_ok({also_private => [qr/^TRACE(?:F|_HERE)?|DUMP$/]});
