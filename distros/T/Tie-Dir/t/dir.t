
use Tie::Dir;

print "1..2\n";

print "ok 1\n";

new Tie::Dir \%hash, ".";

print "ok 2\n"
	if exists $hash{MANIFEST};


