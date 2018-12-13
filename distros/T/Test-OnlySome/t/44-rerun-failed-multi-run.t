#!perl
# t/44-rerun-failed-multi-run.t: Test the App::Prove plugin.
# Runs t/rerunfailed.test with prove -PTest::OnlySomeP multiple times.

package t44;

use rlib 'lib';
use DTest;
use App::Prove;
use Best [ [qw(YAML::XS YAML)], qw(LoadFile) ];

use Exporter::Renaming;
use Test2::Tools::Compare Renaming => [ like => 'struct_like' ];
no Exporter::Renaming;

use Data::Dumper;
use Capture::Tiny qw(capture);

main();

sub main {
    my $test_fn = localpath 'rerunfailed.test';   # the test file to run
    my $results_fn = localpath 'rerunfailed.out';
    unlink $results_fn if -e $results_fn;

    # Run it multiple times, keeping the result file the same.
    for (1..4) {
        run_prove($test_fn, $results_fn);
        check_results($test_fn, $results_fn, $_);
    }

    done_testing();
} #main()

#########################################################################

sub run_prove {
    my $test_fn = shift;
    my $results_fn = shift;

    diag "vvvvvvvvvvv Running tests in $test_fn under App::Prove";
    my $app = App::Prove->new;

    $app->process_args(
        qw(--norc --state=all),  # Isolate us from the environment
        qw(-l),                     # DTest relies on Test::OnlySome::PathCapsule
        qw(-v),                     # Show the skips
        $test_fn,
        '-PTest::OnlySomeP=filename,' . $results_fn
    );

    # prove(1) gets confused by the mixed output from this script and from
    # the inner App::Prove.  Therefore, capture it.
    my ($stdout, $stderr, @result) = capture {
        $app->run;
    };

    diag "  Result was ", join ", ", @result;
    diag "  STDOUT:";
    diag $stdout;
    diag "  STDERR";
    diag $stderr;
    diag "^^^^^^^^^^^ End of output from running tests in $test_fn under App::Prove";
} #run_prove()

sub check_results {
    my $test_fn = shift;
    my $results_fn = shift;
    my $time = shift;
    ok(-e $results_fn, "Output file exists");

    my $results = LoadFile $results_fn;
    ok(ref $results eq 'HASH', "Result file is valid YAML");
    ok($results->{$test_fn}, "Result file has an entry for $test_fn");

    # Check the specifics
    my @expected = (
        { # $time == 1
            skipped => [],
            passed => [1, 4],
            actual_passed => [1,4],
            failed => [2, 3],
            actual_failed => [2, 3],
        },
        { # $time == 2
            skipped => [1, 4],
            failed => [2, 3],
            actual_failed => [2, 3],
        },
    );

    #diag Dumper($results->{$test_fn});
    struct_like($results->{$test_fn},
        $expected[($time-1 <= $#expected) ? ($time-1) : $#expected],
            # Expect idempotency
        "Results on pass $time are as we expect");
} #check_results()

