use strict;
use warnings;

use Test::More;
use Variable::Declaration;

my $s;

Variable::Declaration::data_lock($s);
eval { $s = 'foo' };
like $@, qr!Modification of a read-only value attempted!, 'locked';

done_testing;
