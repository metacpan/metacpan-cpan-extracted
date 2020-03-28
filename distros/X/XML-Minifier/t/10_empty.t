use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier "minify";

my $maxi = << "END";
<empty>


  </empty>
END

my $mini = "<empty/>";

chomp $mini;

is(minify($maxi, remove_empty_text => 1, no_prolog => 1), $mini, "Tag is pseudo empty and merged");

done_testing;

