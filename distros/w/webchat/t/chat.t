# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok\n" unless $loaded;}
use WWW::Chat;
$loaded = 1;
print "ok\n";
