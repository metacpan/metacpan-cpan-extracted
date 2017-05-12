use strict;
use warnings;
use lib 't/lib';

# To Do Var - ensure that Test::More's $TODO variable is exported

use MyTest::Basic;

ok(1, "ok() exists");

TODO: {
    local $TODO = "this test is to do";
    is 1, 2, "in the future one should equal 2 or something";
}

done_testing();
