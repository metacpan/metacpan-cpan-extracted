use strict;
BEGIN { $^W=1; $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $::loaded;}
use Tk::HexEntry;
$::loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


