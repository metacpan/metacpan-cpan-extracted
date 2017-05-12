# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::NumRange;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my ($r,$g,$b);

tie $r, Tie::NumRange => (0, 0, 255);
tie $g, Tie::NumRange => (0, 0, 255);
tie $b, Tie::NumRange => (0, 0, 255);

$r = 100;  # fine
$g = 200;  # fine
$b = 300;  # set to 255

for ([$r,100], [$g,200], [$b,255]) {
  print "not " if $_->[0] != $_->[1];
  print "ok ", ++$loaded, "\n";
}

$b -= 150;  # fine, is now 105
$g -= 150;  # fine, is now 50
$r -= 150;  # set to 0

for ([$r,0], [$g,50], [$b,105]) {
  print "not " if $_->[0] != $_->[1];
  print "ok ", ++$loaded, "\n";
}

tie my($w), Tie::NumRange::Wrap => (0, 0, 10);

my $str;
$str .= $w, $w += 3 while $w != 10;

print "not " if $str ne "0369258147";
print "ok ", ++$loaded, "\n";
