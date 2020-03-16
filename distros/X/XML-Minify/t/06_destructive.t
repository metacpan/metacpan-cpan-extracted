use strict;
use warnings;

use Test::More 0.98;

use XML::Minify "minify";

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

my $minikeeplinestart = << "EOM";
<person><name>Tib
    Bob
    Richard</name><level/></person>
EOM

# Some line start and line end blanks are removed by option blanks and blanks end
my $minikeeplineend = << "EOM";
<person><name>Tib  
Bob  
Richard</name><level/></person>
EOM


chomp $mini;
chomp $minikeeplinestart;
chomp $minikeeplineend;

is(minify($maxi, no_prolog => 1, destructive => 1), $mini, "Destructive");
is(minify($maxi, no_prolog => 1, destructive => 1, remove_spaces_line_start => 0), $minikeeplinestart, "Destructive but keep spaces line start");
is(minify($maxi, no_prolog => 1, destructive => 1, remove_spaces_line_end => 0), $minikeeplineend, "destructive but keep spaces line end");

done_testing;

