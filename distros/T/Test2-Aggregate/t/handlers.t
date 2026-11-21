use Test2::V0;
use Test2::Aggregate;
use Path::Tiny;

# Warning handlers installed by an aggregated test (e.g. on first load of a
# plugin) must remain active for the tests that follow it.

my $dir = Path::Tiny->tempdir;
$dir->child('handler')->mkpath;
$dir->child('handler/a.t')->spew_utf8(
    "use Test2::V0;\n\$SIG{__WARN__} = sub { push \@main::caught, \@_ };\nok(1);\ndone_testing;\n");
$dir->child('handler/b.t')->spew_utf8(
    "use Test2::V0;\nwarn \"from b\\n\";\nok(1);\ndone_testing;\n");

for my $test_warnings (0, 1) {
    our @caught = ();
    local $SIG{__WARN__} = sub {};
    intercept {
        Test2::Aggregate::run_tests(
            dirs          => ["$dir/handler"],
            sort          => 1,
            test_warnings => $test_warnings,
        );
    };
    ok((grep {/from b/} @caught), "handler from earlier test stays active (test_warnings=$test_warnings)");
}

SKIP: {
    # Loading the plugin here would install its handler, so only look for it.
    skip 'Test2::Plugin::NoWarnings unavailable', 2
        unless grep { !ref && -f "$_/Test2/Plugin/NoWarnings.pm" } @INC;

    # NoWarnings installs its handler only on first load, so test this last
    # and keep its handler out of this file by localizing it.
    $dir->child('nowarn')->mkpath;
    $dir->child('nowarn/a.t')->spew_utf8(
        "use Test2::V0;\nuse Test2::Plugin::NoWarnings;\nok(1);\ndone_testing;\n");
    $dir->child('nowarn/b.t')->spew_utf8(
        "use Test2::V0;\nuse Test2::Plugin::NoWarnings;\nwarn \"boom\\n\";\nok(1);\ndone_testing;\n");

    local $SIG{__WARN__} = sub {};
    my $stats;
    intercept {
        $stats = Test2::Aggregate::run_tests(dirs => ["$dir/nowarn"], sort => 1);
    };
    my %pass = map { path($_)->basename => $stats->{$_}{pass_perc} } keys %$stats;
    is($pass{'a.t'}, 100, 'test without warnings passes');
    is($pass{'b.t'}, 0, 'NoWarnings still fails the second test that warns');
}

done_testing;
