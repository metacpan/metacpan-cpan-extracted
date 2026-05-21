use strict;
use warnings;
use MyTest;
use UUID ();


UUID::clear(my $bin);

ok 1, 'basic';

ok defined($bin), 'defined';

is length($bin), 16, 'length';

done_testing;
