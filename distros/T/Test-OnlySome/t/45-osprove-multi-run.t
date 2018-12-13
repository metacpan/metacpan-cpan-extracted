#!perl
# t/45-osprove-multi-run.t: Test the osprove binary
# Runs t/rerunfailed.test with osprove multiple times.
# Assumes cwd is blib/.. or bin/.. .

package t45;

use rlib 'lib';
use DTest;
use Best [ [qw(YAML::XS YAML)], qw(LoadFile) ];

use Exporter::Renaming;
use Test2::Tools::Compare Renaming => [ like => 'struct_like' ];
no Exporter::Renaming;

use Data::Dumper;
use Capture::Tiny qw(capture);
use Test::OnlySome::PathCapsule;

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

    diag "vvvvvvvvvvv Running tests in $test_fn under osprove";

    # Use the script in blib if it exists.  TODO: only use blib if blib is in @INC.
    my ($script, $lib);
    my $blib_osprove_fn =
        Test::OnlySome::PathCapsule->new()->down('blib')->down('script')->file('osprove');
    my $bin_osprove_fn =
        Test::OnlySome::PathCapsule->new()->down('bin')->file('osprove');

    # Also check for '.bat', which EUMM creates using pl2bat on Windows.
    if(-x $blib_osprove_fn->abs) {
        $script = $blib_osprove_fn->abs;
    } elsif(-x $blib_osprove_fn->abs . '.bat') {
        $script = $blib_osprove_fn->abs . '.bat';
    } elsif(-x $bin_osprove_fn->abs) {
        $script = $bin_osprove_fn->abs;
    } elsif(-x $bin_osprove_fn->abs . '.bat') {
        $script = $bin_osprove_fn->abs . '.bat';
    }

    $lib = $blib_osprove_fn->clone()->up()->down('lib')->abs;

    diag "Running under $script (lib $lib)";

    # prove(1) gets confused by the mixed output from this script and from
    # the inner osprove.  Therefore, capture it.
    my ($stdout, $stderr, @result) = capture {
        system($script,
            qw(--norc --state=all),  # Isolate us from the environment
            qw(-v),                  # Show the skips
            '-I', $lib,              # DTest relies on Test::OnlySome::PathCapsule
            '--onlysome', $results_fn,
            $test_fn
        );
    };

    diag "  Result was ", join ", ", @result;
    diag "  STDOUT:";
    diag $stdout;
    diag "  STDERR";
    diag $stderr;
    diag "^^^^^^^^^^^ End of output from running tests in $test_fn under $script";
} #run_prove()

sub check_results {
    my $test_fn = shift;
    my $results_fn = shift;
    my $time = shift;

    ok(-e $results_fn, "Output file $results_fn exists");

    SKIP: {
        skip "Can't check a nonexistent results file", 3
            unless -e $results_fn;

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
    } #SKIP
} #check_results()

