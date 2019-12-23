use strict;
use warnings;
use Test::More;
use overload::open;
overload::open->prehook_open(\&overload::open::_test_xs_function);
my $open_dies = 0;
eval {
    open my $fh, '>', "filename";
    1;
} or do {
    $open_dies = 1;
};
is($open_dies, 1, "open dies when you try and hook");

done_testing;
