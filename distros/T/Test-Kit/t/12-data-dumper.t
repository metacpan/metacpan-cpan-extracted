use strict;
use warnings;
use lib 't/lib';

# Data Dumper - test that a non-Test module can be included

use MyTest::DataDumper;

ok(1, "ok() exists");

warning_is {
    local $Data::Dumper::Indent = 0;
    warn Dumper([ 1, 2, 3 ]);
} '$VAR1 = [1,2,3];', 'Dumper() exists';

done_testing();
