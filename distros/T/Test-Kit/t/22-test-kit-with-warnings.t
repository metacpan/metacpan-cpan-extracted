use strict;
#use warnings;
use lib 't/lib';

# TestKitWithWarnings - test kits can include pragmata such as warnings

use MyTest::TestKitWithWarnings;
use Test::Warn;

ok 1, "ok() exists";

warning_like {
    my $a = "a" + 1;
} qr/Argument "a" isn't numeric in addition/, 'warnings enabled';

done_testing();
