use strict;
use warnings;

=head1 NAME

45-tester.t - testing Test::Group::Tester

=cut

use Test::More tests => 1;
use Test::Group;
use Test::Group::Tester;

testscript_ok('#line '.(__LINE__+1)."\n".<<'EOSCRIPT', 8);
use strict;
use warnings;

use Test::More;
use Test::Group;

# simple test passing
want_test('pass', 'this will pass');
ok 1, "this will pass";

# nameless test passing
want_test('pass');
ok 1;

# simple test failing
want_test('fail', 'this will fail',
    fail_diag('this will fail', 1, __LINE__+2),
);
ok 0, "this will fail";

# test group passing
want_test('pass', 'mytest');
test mytest => sub {
    ok 1, "inner";
};

# test group failing
want_test('fail', 'mytest',
    fail_diag('inner', 0, __LINE__+4),
    fail_diag('mytest', 1, __LINE__+4),
);
test mytest => sub {
    ok 0, "inner";
};

# diag exact match
want_test('pass', 'mytest', '# foo');
diag('foo');
ok 1, 'mytest';

# diag regex match
want_test('pass', 'mytest', '/f.o');
diag('foo');
ok 1, 'mytest';

# diag qr// match
want_test('pass', 'mytest', qr/f.o/);
diag('foo');
ok 1, 'mytest';

EOSCRIPT

