# Need to suppress warinings ?
BEGIN { $^W = 0; $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use UNIX::Cal qw(monday);
$loaded = 1;
print "ok 1\n";
use Data::Dumper;
print cal() ? "ok 2" : "not ok 2", "\n";
print cal(5,2002) ? "ok 3" : "not ok 3", "\n";
print cal(2002) ? "ok 4" : "not ok 4", "\n";
