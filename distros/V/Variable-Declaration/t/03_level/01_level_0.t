use strict;
use warnings;

use Test::More;
use Type::Nano qw(Int);

use Variable::Declaration level => 0;

eval {
    let Int $s = 'foo';
};
ok !$@, 'do nothing when initialize';

eval {
    let Int $s = 123;
    $s = 'bar';
};
ok !$@, 'do nothing when reassignment';

done_testing;
