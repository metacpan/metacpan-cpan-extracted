
use warnings;
use strict;

use blib;

use Test::More;

use WWW::Search;

ok(my $o = new WWW::Search('Null'));

is($o->approximate_result_count, undef);
$o->approximate_result_count(3);
is($o->approximate_result_count, 3);

done_testing;

