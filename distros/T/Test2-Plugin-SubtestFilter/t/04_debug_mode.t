use Test2::V0;

use lib 't/lib';
use TestHelper;

my $test_file = 't/examples/basic.t';

subtest 'SUBTEST_FILTER_DEBUG=0 (default) - skipped tests do not show skip message' => sub {
    my $stdout = run_test_file($test_file, 'foo', 0);

    # Executed tests should appear
    like($stdout, match_executed('foo'), 'foo is executed');
    like($stdout, match_executed('foo > nested arithmetic'), 'foo > nested arithmetic is executed');
    like($stdout, match_executed('foo > nested string'), 'foo > nested string is executed');

    # Skipped tests should NOT show skip message when DEBUG is off
    unlike($stdout, match_skipped('bar'), 'bar does not show skip message');
    unlike($stdout, match_skipped('baz'), 'baz does not show message');
};

subtest 'SUBTEST_FILTER_DEBUG=1 - skipped tests show skip message' => sub {
    my $stdout = run_test_file($test_file, 'foo', 1);

    # Executed tests should appear
    like($stdout, match_executed('foo'), 'foo is executed');
    like($stdout, match_executed('foo > nested arithmetic'), 'foo > nested arithmetic is executed');
    like($stdout, match_executed('foo > nested string'), 'foo > nested string is executed');

    # Skipped tests SHOULD show skip message when DEBUG is on
    like($stdout, match_skipped('bar'), 'bar shows skip message');
    like($stdout, match_skipped('baz'), 'baz shows skip message');
};

done_testing;
