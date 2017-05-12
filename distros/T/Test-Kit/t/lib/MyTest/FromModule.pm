package MyTest::FromModule;

use strict;
use warnings;

use MyTest::Basic;

sub from_module_ok {
    ok(1, 'from_module_ok() works');
}

sub from_module_done_testing {
    done_testing();
}

1;
