#use strict;
use warnings;
use lib 't/lib';

# TestKitWithStrict - test kits can include pragmata such as strict

use MyTest::TestKitWithStrict;

ok 1, "ok() exists";

eval '$x = 1;';
ok $@, 'strict mode enabled';

done_testing();
