use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier "minify";

my $maxi = << "EOM";

<person


>
  <name  >
    Tib
    Bob
    Richard
  </name   
  >
  <level  > 


</level          >
</person   >




EOM

my $mini = << "EOM";
<person><name>TibBobRichard</name><level/></person>
EOM

chomp $mini;

is(minify($maxi, no_prolog => 1, insane => 1), $mini, "Insane");

done_testing;
