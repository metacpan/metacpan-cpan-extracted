use strict;
use warnings;

use Test::More;
use Type::Nano qw(Int);

use Variable::Declaration level => 2;

eval {
    let Int $s = 'foo';
};
like $@, qr!Value "foo" did not pass type constraint Int!, 'check type when initialize';

eval {
    let Int $s = 123;
    $s = 'bar';
};
like $@, qr!Value "bar" did not pass type constraint Int!, 'check type when reassignment';

done_testing;
