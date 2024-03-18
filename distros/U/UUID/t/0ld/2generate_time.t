use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ();


UUID::generate_time(my $bin);

ok 1, 'generate';

ok defined($bin), 'defined';

is length($bin), 16, 'length';

done_testing;
