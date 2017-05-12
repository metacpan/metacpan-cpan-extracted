use strict;
use warnings;
use lib 't/lib';

# List Util - test that List::Util::import() can be passed parameters

use MyTest::ListUtil;

ok(1, "ok() exists");

my $min = min(shuffle(qw(1 2 3 4 5)));
is $min, '1', 'min() and shuffle() exist';

done_testing();
