use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Stub::Generator;

my $some_method = make_subroutine(
    { expects => [ignore], return => [0] },
    { is_repeat => 1 }
);

&$some_method(0);
&$some_method('a');
&$some_method([0, 1]);
&$some_method(+{a => 1});


done_testing;
