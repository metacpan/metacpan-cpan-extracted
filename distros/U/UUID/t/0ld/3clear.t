use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ();


UUID::clear(my $bin);

ok 1, 'basic';

ok defined($bin), 'defined';

is length($bin), 16, 'length';

done_testing;
