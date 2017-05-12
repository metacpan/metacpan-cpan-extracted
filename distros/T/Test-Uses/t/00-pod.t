use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => 'Author test.  Set environment variable TEST_AUTHOR to a true value to run.'
        unless $ENV{TEST_AUTHOR};
}

use Test::Pod 1.14;

my @modules = all_pod_files('lib');

foreach my $module (@modules) {
    pod_file_ok( $module );
}

done_testing();

1;