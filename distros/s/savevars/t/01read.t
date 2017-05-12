# -*- perl -*-

BEGIN { 
    $| = 1;
    print "1..4\n";
    $0 = "savevarstest";
}
END {
    print "not ok 1\n" unless $loaded;
}

use savevars qw($test %test @test);

$loaded = 1;
print "ok 1\n";

if (!defined $test || $test != 1) {
    print "not ";
}
print "ok 2\n";

if (!scalar keys %test || $test{2} != 3) {
    print "not ";
}
print "ok 3\n";

if (@test != 2 || $test[0] != 4 || $test[1] != 5) {
    print "not ";
}
print "ok 4\n";
