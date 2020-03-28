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
<person><name>Tib
    Bob
    Richard</name><level/></person>
EOM

my $minikeepblanksend = << "EOM";
<person><name>Tib
    Bob
    Richard
  </name><level/></person>
EOM


chomp $mini;
chomp $minikeepblanksend;

is(minify($maxi, no_prolog => 1, aggressive => 1), $mini, "Aggressive");

is(minify($maxi, no_prolog => 1, aggressive => 1, remove_blanks_end => 0), $minikeepblanksend, "Aggressive but keep CR LF (1)");
is(minify($maxi, no_prolog => 1, remove_blanks_end => 0, aggressive => 1), $minikeepblanksend, "Aggressive but keep CR LF (2 change order)");

is(minify($maxi, no_prolog => 1, aggressive => 1), minify($maxi, no_prolog => 1, agressive => 1), "Agressive (with a typo) is supported");

done_testing;

