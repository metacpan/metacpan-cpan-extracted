use strict;
use warnings;

use Test::More 0.98;

use XML::Minify "minify";

my $maxi = << "EOM";

<person>
  <name>
    T i b   
    B    o b
    R  i    c h  a r d
  </name   
  >
  <level  >


</level          >
</person   >




EOM

my $mini = << "EOM";
<person><name>
Tib
Bob
Richard
</name><level>


</level></person>
EOM

chomp $mini;

is(minify($maxi, no_prolog => 1, remove_spaces_everywhere => 1), $mini, "Remove spaces everywhere");

my $maxi_with_spaces = << "EOM";
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

my $mininospaces_linestart = << "EOM";
<person><name>

Tib   
Bob   
Richard   

</name><level>
</level></person>
EOM

my $mininospaces_lineend = << "EOM";
<person><name>

   Tib
   Bob
   Richard

</name><level>
</level></person>
EOM

my $mininospaces_lineboth = << "EOM";
<person><name>

Tib
Bob
Richard

</name><level>
</level></person>
EOM

chomp $maxi_with_spaces;
chomp $mininospaces_linestart;
chomp $mininospaces_lineend;
chomp $mininospaces_lineboth;


is(minify($maxi_with_spaces, no_prolog => 1, remove_spaces_line_start => 1), $mininospaces_linestart, "Remove spaces every line start");
is(minify($maxi_with_spaces, no_prolog => 1, remove_spaces_line_end => 1), $mininospaces_lineend, "Remove spaces every line end");
is(minify($maxi_with_spaces, no_prolog => 1, remove_spaces_line_start => 1, remove_spaces_line_end => 1), $mininospaces_lineboth, "Remove spaces every line start and line end");

my $maxi_with_spaces_inside_words = << "EOM";
<person>
  <name>
   
   T i b   
   B o b   
   R i c h a r d   
   
  </name>
  <level>
</level>
</person>
EOM

my $mini_keepspaces_inside_words = << "EOM";
<person><name>

T i b
B o b
R i c h a r d

</name><level>
</level></person>
EOM


chomp $maxi_with_spaces_inside_words;
chomp $mini_keepspaces_inside_words;

is(minify($maxi_with_spaces_inside_words, no_prolog => 1, remove_spaces_line_start => 1, remove_spaces_line_end => 1), $mini_keepspaces_inside_words, "Remove spaces every line start and line end but keep spaces inside words");

done_testing;
