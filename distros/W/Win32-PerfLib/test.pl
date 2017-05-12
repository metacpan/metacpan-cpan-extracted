# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Win32::PerfLib;
$loaded = 1;
print "ok 1\n";

$verbose = 0;
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
$machine = "";
Win32::PerfLib::GetCounterNames($machine, \%counter) or print "not ";
print "ok 2\n";
Win32::PerfLib::GetCounterHelp($machine, \%help) or print "not ";
print "ok 3\n";

$perf = new Win32::PerfLib($machine) or print "not ";
print "ok 4\n";

$ref = {};
$perf->GetObjectList("2", $ref) or print "not ";
print "ok 5\n";

$perf->Close() or print "not ";
print "ok 6\n";
