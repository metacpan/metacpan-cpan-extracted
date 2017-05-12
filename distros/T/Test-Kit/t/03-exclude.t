use strict;
use warnings;
use lib 't/lib';

# Exclude - test that the exclude feature works

use MyTest::Exclude;

ok(1, "ok() exists");
is(1, 1, "is() exists");
like("foo", qr/^foo$/, "like() exists");

eval q{pass()};
like($@, qr/Undefined subroutine/, "pass() doesn't exist");

eval q{fail()};
like($@, qr/Undefined subroutine/, "fail() doesn't exist");

done_testing();
