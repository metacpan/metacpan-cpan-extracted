BEGIN {
    use Test2::V0;
    use Test::Output;
    use Time::HiRes;

    *CORE::GLOBAL::caller = sub { return () };
}

use File::Temp ();
use Test2::Aggregate;

plan(3);

my $root   = (grep {/^\.$/i} @INC) ? undef : './';
my $tmpdir = File::Temp->newdir;
my $stats  = "$tmpdir/stats";

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    root         => $root,
    stats_output => $stats
);

like(find( $stats, '.*'), [qr/aggregate.*txt/], "Found stats file");

sub find {
    my $dir     = shift;
    my $pattern = shift;

    opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
    my @files = grep { /$pattern/ && -f "$dir/$_" } readdir($dh);
    closedir $dh;
    return \@files;
}
