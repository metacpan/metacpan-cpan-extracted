use Test2::V0;

ok($ENV{AGGREGATE_TESTS}, 'Running under aggregated environment');
ok(!$ENV{AGGREGATE_TEST_FAIL}, 'Not asked to fail');

warn "AGGREGATE_TEST_WARN\n" if $ENV{AGGREGATE_TEST_WARN};

eval 'sub test_package { print "test redefines"; return; }'
    if $ENV{AGGREGATE_TEST_PACKAGE};

done_testing;