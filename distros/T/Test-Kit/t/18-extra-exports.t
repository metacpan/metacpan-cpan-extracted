use strict;
use warnings;
use lib 't/lib';

# Extra Exports - test that custon subroutines can be exported

use MyTest::ExtraExports;

ok(1, "ok() exists");

ten_passes();

done_testing();
