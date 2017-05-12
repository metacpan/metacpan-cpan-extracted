# -*- perl -*-

BEGIN { 
    $| = 1;
    print "1..1\n";
    $0 = "savevarstest";
}
END {
    print "not ok 1\n" unless $loaded;
}

use savevars qw($test %test @test);

$loaded = 1;
print "ok 1\n";

$test = 1;
$test{2} = 3;
@test = (4, 5);

# if (!savevars::writecfg()) {
#     print "not ";
# }
# print "ok 2\n";
