use Test2::V0;
use Test2::Aggregate;
use Test::Output;
use Time::HiRes;

plan(10);

my $root = (grep {/^\.$/i} @INC) ? undef : './';
foreach my $extend (0 .. 1) {
    stdout_like(sub {
            Test2::Aggregate::run_tests(
                dirs         => ['xt/aggregate'],
                root         => $root,
                extend_stats => $extend,
                stats_output => '-'
            )
        },
        qr/TOTAL TIME: [0-9.]+ sec/,
        "Valid stats output for extended = $extend"
    );
}

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    root         => $root,
    stats_output => '/tmp'
);

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    root         => $root,
    stats_output => '/tmp/tmp'.time()
);

