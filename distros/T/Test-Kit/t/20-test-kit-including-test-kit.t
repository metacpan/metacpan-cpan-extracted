use strict;
use warnings;
use lib 't/lib';

# TestKitIncludingTestKit - test kits can be composed together too!

use MyTest::TestKitIncludingTestKit;

ok 1, "ok() exists";

foo "foo() - a renamed pass() - exists";

warnings_like {
    warn "foo";
} qr/foo/, "warnings_like() exists";

equal 2, 2, "equal() - a renamed is() - exists";

done_testing();
