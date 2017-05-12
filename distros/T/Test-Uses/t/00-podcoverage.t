use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'Author test.  Set environment variable TEST_AUTHOR to a true value to run.'
        unless $ENV{TEST_AUTHOR};
}

use Pod::Coverage 0.19;
use Test::Pod::Coverage 1.04;

my @modules = all_modules('lib');

foreach my $module (@modules) {
    pod_coverage_ok( $module, {also_private => ['BUILD']} );
}

done_testing();

1;