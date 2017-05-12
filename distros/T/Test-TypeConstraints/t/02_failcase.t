use strict;
use warnings;
use Test::Tester;
use Test::More;
use Test::TypeConstraints qw(type_isa);

check_test(sub {
    type_isa([1, 2, "abc"], "ArrayRef[Int]", "fail test case");
}, +{
    ok => 0,
    name => "fail test case",
    diag => <<'END_OF_DIAG',
type: "ArrayRef[Int]" expected. but got $VAR1 = [
          1,
          2,
          'abc'
        ];
END_OF_DIAG
});

done_testing;
