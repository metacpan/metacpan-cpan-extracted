#! perl

# Tom Moertel <tom@moertel.com>

# Here we test the output and exit status of the Test::LectroTest
# testing apparatus to make sure that they conform to the expectations
# of Test::Harness.  In particular the output should have an "ok"
# for every successful test and a "not ok" line for every failure.
# The exit status should be equal to the number of failures or
# 254, whichever is least.

use File::Temp 'tempfile';
use Test::More tests => 6;

BEGIN { unshift @INC, 't/lib'; }
use CaptureOutput;

my $prop_success = "Property { ##[ ]## 1 };\n";
my $prop_failure = "Property { ##[ ]## 0 };\n";

for( [0,0,0], [0,1,1], [1,0,0], [1,1,1],
     [0,254,254], [0,300,254] )
{
    my ($s, $f)  = @$_;  # successes, failures, 
    my $results  = make_and_run_suite($s, $f);
    my $oks      = grep 1, $results =~ /^ok/mg;
    my $noks     = grep 1, $results =~ /^not ok/mg;
    my ($status) = $results =~ /^(.*)/;
    is_deeply( [$oks, $noks, $status], $_, "suite @$_" );
}

sub make_and_run_suite {
    my ($successes, $failures) = @_;
    my ($fh, $fn) = tempfile() or die "can't open temp file: $!";
    print $fh
        "use Test::LectroTest;\n",
        ($prop_success) x $successes,
        ($prop_failure) x $failures;
    close $fh or die "can't close temp file: $!";
    my @cmd = ($^X, "-Ilib", $fn);
    my $recorder = capture(*STDOUT);
    my $exit_status = system(@cmd) >> 8;
    unlink $fn;
    return "$exit_status\n" . $recorder->();
}
