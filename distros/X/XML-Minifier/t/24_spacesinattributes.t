use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier "minify";

my $maxi = << "EOM";
<root>
	<tag a="    spaces before and after    " b="

carriage return before and after


" c="multiple spaces           inside"/>
</root>
EOM

my $mini = << "EOM";
<root><tag a="    spaces before and after    " b="  carriage return before and after   " c="multiple spaces           inside"/></root>
EOM

my $tiny = << "EOM";
<root><tag a="spaces before and after" b="carriage return before and after" c="multiple spaces           inside"/></root>
EOM




chomp $mini;

is(minify($maxi, no_prolog => 1), $mini, "Carriage return automatically removed in attributes");
is(minify($maxi, no_prolog => 1, aggressive => 1), $mini, "Aggressive mode should remove starting and ending spaces in attributes");

done_testing;
