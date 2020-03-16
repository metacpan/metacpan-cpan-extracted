use strict;
use warnings;

use Test::More 0.98;

use XML::Minify "minify";

my $maxi = << "END";
<root>
  <tag>
  Tib
  Bob
  Richard
  </tag>
</root>
END

is(minify($maxi, aggressive => 1), minify($maxi, aggressive => 0, aggressive => 1), "Redeclare option");
is(minify($maxi, destructive => 1), minify($maxi, aggressive => 0, destructive => 1), "Override aggressive with destructive");
is(minify($maxi, destructive => 1), minify($maxi, destructive => 1, aggressive => 0), "Override aggressive with destructive (change order");
is(minify($maxi, destructive => 1), minify($maxi, aggressive => 1, destructive => 1), "Destructive contains aggressive");
is(minify($maxi, destructive => 1), minify($maxi, destructive => 1, aggressive => 1), "Destructive contains aggressive (change order)");

is(minify($maxi, insane => 1), minify($maxi, destructive => 0, insane => 1), "Override destructive with insane");
is(minify($maxi, insane => 1), minify($maxi, insane => 1, destructive => 0), "Override destructive with insane (change order");
is(minify($maxi, insane => 1), minify($maxi, destructive => 1, insane => 1), "Insane contains destructive");
is(minify($maxi, insane => 1), minify($maxi, insane => 1, destructive => 1), "Insane contains destructive (change order)");

is(minify($maxi, insane => 1), minify($maxi, destructive => 0, aggressive => 0, insane => 1), "Override aggressive and destructive with insane");
is(minify($maxi, insane => 1), minify($maxi, insane => 1, destructive => 0, aggressive => 0), "Override aggressive and destructive with insane (change order)");
is(minify($maxi, insane => 1), minify($maxi, insane => 1, destructive => 1, aggressive => 1), "Insane contains aggressive and destructive");
is(minify($maxi, insane => 1), minify($maxi, destructive => 1, aggressive => 1, insane => 1), "Insane contains aggressive and destructive (change order)");


is(minify($maxi, insane => 0), minify($maxi, destructive => 0), "Not insane is like not destructive");
is(minify($maxi, insane => 0), minify($maxi, aggressive => 0), "Not insane is like not aggressive");
is(minify($maxi, destructive => 0), minify($maxi, aggressive => 0), "Not destructive is like not aggressive");
is(minify($maxi, aggressive => 0), minify($maxi), "Not aggressive is like... Nothing");
is(minify($maxi, destructive => 0), minify($maxi), "Not destructive is like.. Nothing");
is(minify($maxi, insane => 0), minify($maxi), "Not insane is like.. Nothing");
ok(1);

done_testing;

