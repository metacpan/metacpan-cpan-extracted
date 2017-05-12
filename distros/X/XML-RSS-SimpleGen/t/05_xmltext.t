
require 5;
use strict;
use Test;
BEGIN { plan tests => 4 }

print "# Starting ", __FILE__ , " ...\n";
ok 1;

#sub XML::RSS::SimpleGen::DEBUG () {20}

use XML::RSS::SimpleGen;
print "# XML::RSS::SimpleGen version $XML::RSS::SimpleGen::VERSION\n";
sub z ($) { return XML::RSS::SimpleGen->xmlesc( $_[0] ) }

ok z "vis-à-vis Beyoncé's naïve papier-mâché résumé",
     "vis-&#224;-vis Beyonc&#233;'s na&#239;ve papier-m&#226;ch&#233; r&#233;sum&#233;";

ok z "This & That, N < 10, N > 2",
     "This &amp; That, N &lt; 10, N &gt; 2";

print "# Quitting...\n";
ok 1;

