use strict;
use Test::More;
use Test::Builder::Tester;
use Test::RandomCheck;
use Test::RandomCheck::Generator;

test_out "ok 1";
random_ok { 1 } integer;
test_test "just bang away";

test_out "not ok 1";
test_fail(+1);
random_ok { 8 <= $_[0] && $_[0] <= 128 ? 0 : 1 } integer;
test_test title => "punch out the bug",
          skip_err => 1;

test_out "ok 1";
random_ok { 0 } integer, shots => 0;
test_test "Don't shoot, spend peacefully.";

done_testing;
