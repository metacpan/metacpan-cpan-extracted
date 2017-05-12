# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

my $ok_count = 1;
sub ok {
  shift or print "not ";
  print "ok $ok_count\n";
  ++$ok_count;
}

use Win32::Process;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $p;
my $pid = $^O eq 'cygwin' ? Win32::Process::GetCurrentProcessID() : $$;
if (Win32::Process::Open($p, $pid, 0)) {
  ok(1);
  ok($p->SetPriorityClass(HIGH_PRIORITY_CLASS))
} else {
  ok(0);
  ok(0);
}

ok(!Win32::Process::Open($p, -1, 0));
