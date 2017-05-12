# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;

BEGIN { plan tests => 1 };
use dirtyRSS;

open F, "feed_sample.xml" || die("Failed to open input file feed_sample.xml\n");
$in = join "", <F>;
close F;

$tree = parse($in);

ok((ref $tree) ? 1 : 0);

#########################

