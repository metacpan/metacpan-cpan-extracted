use strict;
use warnings;
use Test::More;
use UUID ();


UUID::generate(my $bin);

ok 1, 'generate';

ok defined($bin), 'defined';

is length($bin), 16, 'length';

done_testing;
