BEGIN { $| = 1; print "1..1\n" }

use common::sense;

if ($common::sense::VERSION < 3.7) {
   print STDERR <<EOF;

***
*** WARNING
***
*** old version of common::sense still installed,
*** your perl library is corrupted.
***
*** please manually uninstall older common::sense versions
*** or use "make install UNINST=1" to remove them.
***

EOF
}

print "ok 1\n";
