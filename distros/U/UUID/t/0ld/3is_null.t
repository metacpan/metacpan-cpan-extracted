use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ();


UUID::generate_time(my $bin);
ok 1, 'generate';

is UUID::is_null($bin), 0, 'not null';

UUID::clear($bin);
ok 1, 'clear';

ok UUID::is_null($bin), 'is null';

$bin = 'foo';
is UUID::is_null($bin), 0, 'bogus null';

is $bin, 'foo', 'unchanged';

done_testing;
