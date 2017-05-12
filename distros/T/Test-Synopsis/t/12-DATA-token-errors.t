use Test::Builder::Tester tests => 1;
use Test::More;
use Test::Synopsis;

# Test whether we indeed can detect errors in SYNOPSIS codes

test_out('not ok 1 - t/lib/Test12DATAInPodWithError.pm');
test_diag(q{  Failed test 't/lib/Test12DATAInPodWithError.pm'},
    q{  at t/12-DATA-token-errors.t line } . line_num(+9) . q{.},
    q{Global symbol "$x" requires explicit package name}
    . ( ($^V and $^V gt 5.21.3)
        ? ' (did you forget to declare "my $x"?)'
        : ''
    )
    . q{ at t/lib/Test12DATAInPodWithError.pm line 24.},
);
synopsis_ok("t/lib/Test12DATAInPodWithError.pm");
test_test("synopsis fail works");
