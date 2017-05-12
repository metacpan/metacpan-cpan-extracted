# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use VMS::Monitor;
$loaded = 1;
print "ok 1\n";

my $cpubusy = VMS::Monitor::one_monitor_piece('CPUBUSY');
if (defined $cpubusy) {
    print "ok 2 # CPU is $cpubusy\% busy\n";
}
else {
    print "not ok 2\n";
}

