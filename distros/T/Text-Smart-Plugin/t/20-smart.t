# $Id: 010Smart.t,v 1.1 2004/05/12 16:45:13 dan Exp $

BEGIN { $| = 1; print "1..1\n"; }
END { print "not ok 1\n" unless $loaded; }

use Text::Smart::Plugin;
$loaded = 1;
print "ok 1\n";

# Local Variables:
# mode: cperl
# End:
