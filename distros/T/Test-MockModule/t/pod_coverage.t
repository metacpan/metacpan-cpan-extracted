use warnings;
use strict;

use Test::More;

eval { require Test::Pod::Coverage; Test::Pod::Coverage->import(1.00); 1 }
    or plan skip_all => "Test::Pod::Coverage 1.00 required for testing pod coverage";
all_pod_coverage_ok({also_private => [qr/^TRACE(?:F|_HERE)?|DUMP$/]});
