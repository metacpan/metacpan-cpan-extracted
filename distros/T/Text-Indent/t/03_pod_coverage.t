#
# $Id: 03_pod_coverage.t 4552 2010-09-23 10:40:29Z james $
#

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok(
    {
        also_private => [ qr/^_\w+/, qw|init instance| ]
    },
'all modules have POD covered');

#
# EOF
