use strict;
use warnings;

use Test::More 0.98;

use XML::Minify "minify";

my $maxi = << "EOM";
<person>
  <name>

    Tib
    Bob
    Richard

  </name>
  <level>
</level>
</person>
EOM

my $mininoblanks_start = << "EOM";
<person><name>Tib
    Bob
    Richard

  </name><level/></person>
EOM

my $mininoblanks_end = << "EOM";
<person><name>

    Tib
    Bob
    Richard</name><level/></person>
EOM

my $mininoblanks_both = << "EOM";
<person><name>Tib
    Bob
    Richard</name><level/></person>
EOM

chomp $mininoblanks_start;
chomp $mininoblanks_end;
chomp $mininoblanks_both;

is(minify($maxi, no_prolog => 1, remove_blanks_start => 1), $mininoblanks_start, "Remove blanks at start of text nodes (1 remove_blanks_start)");
is(minify($maxi, no_prolog => 1, remove_blanks_end => 1), $mininoblanks_end, "Remove blanks at the end of text nodes (2 use remove_blanks_end)");
is(minify($maxi, no_prolog => 1, remove_blanks_start => 1, remove_blanks_end => 1), $mininoblanks_both, "Remove blanks at start and end of text nodes (3 remove_blanks_start and remove_blanks_end)");

done_testing;

