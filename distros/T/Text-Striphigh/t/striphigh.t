BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::Striphigh 'striphigh';
$loaded = 1;
print "ok 1\n";
$t = striphigh(pack("C*", 161..255));
print "# $t\n";
print $t eq q{!c#xY|&^(C)a<-$(R)^%~&''uq-,10>1/41/23/4(AAAAAAAECEEEEIIIIBNOOOOOx0UUUUYpBaaaaaaaeceeeeiiiionooooo:0uuuuyby} ?
    "ok 2\n" : "not ok 2\n";
print striphigh("\x81") eq "\cA" ? "ok 3\n" : "not ok 3\n";
