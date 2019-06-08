use Test2::Tools::Basic;
 
plan(4);

ok 1, "$0 test 1";
ok 1, "$0 test 2";

SKIP: {
    skip "checking plan ($0 test 3)", 1;
    ok 1;
}

subtest 'Subtest' => sub {
    ok 1, "$0 test 4";
}
