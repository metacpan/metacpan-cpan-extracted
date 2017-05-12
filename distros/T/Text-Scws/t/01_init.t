BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::Scws;
$loaded = 1;
print "ok 1\n";
$scws = Text::Scws->new;
print "ok 2\n";
$scws->set_ignore(1);
print "ok 3\n";
