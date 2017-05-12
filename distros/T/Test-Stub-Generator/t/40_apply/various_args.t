use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_subroutine);

my $some_method = make_subroutine(
    [
        { expects => [ 0 ], return => 1 },
        { expects => [ 0, 1 ], return => 1 },
        { expects => [ [0, 1] ], return => 1 },
        { expects => [ { a => 1 } ], return => 1 },
        { expects => [ [0], [0, 1] ], return => 1 },
        { expects => [ { a => 1 }, { b => 2 } ], return => 1 },
    ]
);

&$some_method(0);
&$some_method(0, 1);
&$some_method([0, 1]);
&$some_method({ a => 1 });
&$some_method([0], [0, 1]);
&$some_method({ a => 1 }, { b => 2 });

done_testing;
