#!perl
# 43-plugin-output.t: Test the App::Prove plugin.
# Runs t/allkinds.test with prove -PTest::OnlySomeP.

package t43;

use rlib 'lib';
use DTest;
use App::Prove;
use Best [ [qw(YAML::XS YAML)], qw(LoadFile) ];

my $test_fn = localpath("allkinds.test");   # the test file to run

# Test specified filename
my $results_fn = localpath '43.out';
unlink $results_fn if -e $results_fn;

run_prove($test_fn, $results_fn);
check_results($results_fn);

# Run it a second time, keeping the result file the same.
run_prove($test_fn, $results_fn);
check_results($results_fn);

done_testing();

exit(0);

# Run prove().  TODO: Swallow stdout and stderr while this is running, so
# that the intentional failures in t/allkinds.test don't confuse the output.
sub run_prove {
    my $test_fn = shift;
    my $results_fn = shift;

    diag "=========== Running tests in $test_fn under App::Prove";
    my $app = App::Prove->new;
    $app->process_args(
        qw(-Q --norc --state=all),  # Isolate us from the environment
        qw(-l),                     # DTest relies on Test::OnlySome::PathCapsule
        $test_fn,
        '-PTest::OnlySomeP=filename,' . $results_fn
    );
    $app->run;
    diag "=========== Done running tests in $test_fn under App::Prove";
}

sub check_results {
    my $results_fn = shift;
    ok(-e $results_fn, "Output file exists");

    my $results = LoadFile $results_fn;
    ok(ref $results eq 'HASH', "Result file is valid YAML");
    ok($results->{$test_fn}, "Result file has an entry for $test_fn");
}

