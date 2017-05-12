
# Sequin v0.4 Test routine:

# Should print: ok 1
#               ok 2
#               ok 3


BEGIN { $| = 1; print "ok 1\n"; }
END {print "not ok 1\n" unless $loaded;}
use URI::Sequin qw/se_extract key_extract log_extract %log_types/;;
$loaded = 1;
print "ok 2\n";

$engine = "http://www.google.com/search?q=ok+3";
$blah = &key_extract($engine);
if ($blah) { print "$blah\n"; } else { print "not ok 2\n"; }

print "You should have just seen: ok 1, ok 2, ok 3.\n";
