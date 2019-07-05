use Test2::Tools::Basic;
use Test2::Aggregate;
use Test::Output;

eval "use Time::HiRes";
plan skip_all => "Time::HiRes required for stats_output option" if $@;

plan(8);

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
    stats_output => '/tmp/tmp'
);

