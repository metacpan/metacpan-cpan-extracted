use Test2::V0;
use Test2::Aggregate;

plan(3);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

my $stats = Test2::Aggregate::run_tests(
    dirs         => ['xt/failing'],
    root         => $root,
    allow_errors => 1
);

is(scalar(keys %$stats), 1, 'Only 1 subtest ran');

is(
    intercept {
        Test2::Aggregate::run_tests(
            dirs => ['xt/failing'],
            root => $root
        )
    },
    array {
        fail_events Subtest => sub {
            call pass => 0;
            call name => match(qr'Running test .*failing/error.t');
        };
        end;
    },
    "Failure running test with default settings"
);
