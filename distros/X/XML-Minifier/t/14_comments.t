use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier qw(minify);

my $maxicommented = << "END";
<root>  <!-- Comment -->
  <!-- Comment -->  <tag></tag>
</root>
END

my $minicommented = << "END";
<root>  <!-- Comment -->
  <!-- Comment -->  <tag/></root>
END

my $miniuncommented = << "END";
<root><tag/></root>
END

chomp $maxicommented;
chomp $minicommented;
chomp $miniuncommented;

is(minify($maxicommented, no_prolog => 1, keep_comments => 1), $minicommented, "Keep comments");
is(minify($maxicommented, no_prolog => 1, keep_comments => 0), $miniuncommented, "Explicitely remove comments");

$maxicommented = << "END";
<root>  <!-- <tag></tag> -->  </root>
END

$minicommented = << "END";
<root>  <!-- <tag></tag> -->  </root>
END

$miniuncommented = << "END";
<root/>
END

chomp $maxicommented;
chomp $minicommented;
chomp $miniuncommented;

is(minify($maxicommented, no_prolog => 1, keep_comments => 1), $minicommented, "Keep comments (2 with tag inside)");
is(minify($maxicommented, no_prolog => 1, keep_comments => 0), $miniuncommented, "Explicitely remove comments (2 with tag inside)");

done_testing;

