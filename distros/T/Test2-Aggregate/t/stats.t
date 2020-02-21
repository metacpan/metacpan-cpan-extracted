use Test2::V0;
use Test2::Aggregate;
use Test::Output;
use Time::HiRes;

my $root   = (grep {/^\.$/i} @INC) ? undef : './';
my $timest = time();
my $pattrn = 'stats.t.*txt';
my $tmpdir = File::Temp->newdir;

plan skip_all => "Cannot create temp directory" unless -e $tmpdir;
plan(12);

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
    stats_output => $tmpdir
);

like(find($tmpdir, $pattrn), [qr/$pattrn/], "Found stats file");

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    root         => $root,
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
