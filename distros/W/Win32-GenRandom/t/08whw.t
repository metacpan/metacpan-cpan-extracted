use strict;
use warnings;
use Win32::GenRandom qw(:all);

print "1..2\n";

my $whw = whw();

if($whw eq 'SecureZeroMemory' || $whw eq 'ZeroMemory' || $whw eq 'None') {print "ok 1\n"}
else {
  warn "\n\$whw: $whw\n";
  print "not ok 1\n";
}

if($whw eq 'None') {
  warn "\nUnexpected result - please notify the author\n";
  warn "Calling this a FAIL, though perhaps that's a bit too harsh\n";
  print "not ok 2\n";
}
else {print "ok 2\n"}


