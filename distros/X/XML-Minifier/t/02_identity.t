use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier "minify";

my $maxi = << "EOM";
<person>
  <name  >Tib</name>
  <level></level >
</person>
EOM

my $mini = << "EOM";
<person><name>Tib</name><level/></person>
EOM

chomp $mini;

is(minify($maxi, no_prolog => 1), $mini, "Simple check");
is(minify($maxi, no_prolog => 1), minify($maxi, no_prolog => 1), "Execute 2 times and check result");
is(minify($maxi), minify($maxi), "Execute 2 times and check result (with prolog)");
is(minify($mini, no_prolog => 1), $mini, "Try to minify the minified xml");
is(minify(minify(minify($maxi))), minify($maxi), "Minify-Minify-Minify");
is(minify(minify(minify($mini))), minify($mini), "Minify-Minify-Minify");

done_testing;

