use Test2::V0;
use Test2::Aggregate;
use Test::Output;
use Time::HiRes;

my $root   = (grep {/^\.$/i} @INC) ? undef : './';
my $timest = time();
my $pattrn = 'stats.t.*txt';
my $tmpdir = File::Temp->newdir;

plan skip_all => "Cannot create temp directory" unless -e $tmpdir;
plan(20);

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

stdout_like(sub {
        Test2::Aggregate::run_tests(
            dirs         => ['xt/aggregate'],
            root         => $root,
            stats_output => '-',
            pass_only    => 1
        )
    },
    qr/^(?:\S*\n)+$/,
    "Valid stats output for pass_only"
);

{
    local $ENV{AGGREGATE_TEST_WARN} = 1;
    my $out;
    warnings {
        intercept {
            $out = stdout_from(sub {
                Test2::Aggregate::run_tests(
                    dirs          => ['xt/aggregate'],
                    root          => $root,
                    sort          => 1,
                    stats_output  => '-',
                    pass_only     => 1,
                    test_warnings => 1
                )
            });
        };
    };
    is($out, "xt/aggregate/check_plan.t\n", "pass_only omits tests with warnings");
}

{
    require Cwd;
    my $cwd   = Cwd::getcwd();
    my $empty = File::Temp->newdir;
    my $test  = "$cwd/xt/aggregate/check_plan.t";
    chdir $empty or die "Can't chdir $empty: $!";
    my $out;
    intercept {
        $out = stdout_from(sub {
            Test2::Aggregate::run_tests(dirs => [$test], stats_output => '-')
        });
    };
    chdir $cwd or die "Can't chdir $cwd: $!";
    like($out, qr/TOTAL TIME/, "Stats written to STDOUT");
    ok(!-e "$empty/-", "No '-' directory created for STDOUT stats");
}

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    root         => $root,
    stats_output => $tmpdir
);

like(find($tmpdir, $pattrn), [qr/$pattrn/], "Found stats file");

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    root         => $root,
    repeat       => 2,
    stats_output => "$tmpdir/tmp1$timest"
);

like(find( "$tmpdir/tmp1$timest", '.*'), [qr/$pattrn/], "Found stats file in subdir");

sub find {
    my $dir     = shift;
    my $pattern = shift;

    opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
    my @files = grep { /$pattern/ && -f "$dir/$_" } readdir($dh);
    closedir $dh;
    return \@files;
}
