use strict;
use warnings;

use Test::More 0.98;

use XML::Minify "minify";

my $maxi = << "EOM";
<root>
    <spaces>
    indent
    indent
      indent
      indent
    </spaces>
	<tabs>
	indent
	indent
		indent
		indent
	</tabs>
</root>
EOM

my $mini = << "EOM";
<root><spaces>
indent
indent
indent
indent
</spaces><tabs>
indent
indent
indent
indent
</tabs></root>
EOM

chomp $mini;

is(minify($maxi, no_prolog => 1, remove_indent => 1), $mini, "Remove indent with remove_indent");
is(minify($maxi, no_prolog => 1, remove_spaces_line_start => 1), $mini, "Remove indent with remove_spaces_line_start");
is(minify($maxi, no_prolog => 1, remove_spaces_line_start => 1), minify($maxi, no_prolog => 1, remove_indent => 1), "Remove indent with both and compare them");

done_testing;
