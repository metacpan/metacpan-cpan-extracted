use Test::More;
use Test::JSON::Entails;
use Test::Builder::Tester tests => 1;

test_out("ok 1 - empty");
entails { foo => 1 }, { }, "empty";

test_out("not ok 2 - missing");
test_fail(+2);
test_diag("missing /foo");
entails { }, { foo => 1 }, "missing";

test_out("not ok 3 - type");
test_fail(+2);
test_diag("/foo must be scalar, found array");
entails { foo => [ ] }, { foo => 1 }, "type";

test_out("not ok 4 - scalars differ");
test_fail(+2);
test_diag("/foo differ:\n#          got: 'a'\n#     expected: 'b'");
entails { foo => "a" }, { foo => "b" }, "scalars differ";

test_out("ok 5 - deep hash");
entails { foo => { bar => { doz => 1 } } }, 
        { foo => { bar => { doz => 1 } } }, "deep hash";

test_out("not ok 6 - deep hash");
test_fail(+2);
test_diag("/foo/bar/doz must be array, found hash");
entails { foo => { bar => { doz => { } } } }, 
        { foo => { bar => { doz => [ ] } } }, "deep hash";

test_out("ok 7 - deep array");
entails { foo => [ "a", { b => [ 1, 2 ] }, "c" ] }, 
        { foo => [ "a", { b => [ 1 ] } ] }, "deep array";

test_out("not ok 8 - array element missing");
test_fail(+2);
test_diag("/a[2] missing");
entails { a => [ "x"  ] }, 
        { a => [ "x", "y" ] }, "array element missing";

test_out("not ok 9 - array elements differ");
test_fail(+2);
test_diag("/a[1] differ:\n#          got: 'a'\n#     expected: 'b'");
entails { a => [ "a" ] }, 
        { a => [ "b" ] }, "array elements differ";

test_test("simple hash entailments");
