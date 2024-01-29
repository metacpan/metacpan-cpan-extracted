use strict;
use warnings;
use Test::More;
use UUID ();


UUID::generate_random(my $bin);

ok 1, 'generate';

ok defined($bin), 'defined';

is length($bin), 16, 'length';

done_testing;
