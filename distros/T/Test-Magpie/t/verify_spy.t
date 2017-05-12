#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 28;
use Test::Fatal;
use Test::Builder::Tester;

BEGIN { use_ok 'Test::Magpie', qw(mock verify at_least at_most) }

use Test::Magpie::Util qw( get_attribute_value );

my $file = __FILE__;
my $err;

my $mock = mock;
$mock->once;
$mock->twice() for 1..2;

subtest 'verify()' => sub {
    my $spy = verify($mock);
    isa_ok $spy, 'Test::Magpie::Verify';

    is get_attribute_value($spy, 'mock'), $mock, 'has mock';

    like exception { verify },
        qr/^verify\(\) must be given a mock object/,
        'no arg';
    like exception { verify('string') },
        qr/^verify\(\) must be given a mock object/,
        'invalid arg';
};

{
    my $name = 'once() was called once';

    test_out "ok 1 - $name";
    verify($mock, $name)->once;
    test_test 'name';

    test_out "ok 1 - $name";
    verify($mock, times => 1, $name)->once;
    test_test 'name with other options';
}

test_out 'ok 1 - once() was called 1 time(s)';
verify($mock)->once;
test_test 'times default';

# currently Test::Builder::Test (0.98) does not work with subtests
# subtest 'times' => sub {
{
    like exception { verify($mock, times => 'string') },
        qr/^'times' option must be a number/, 'invalid times';

    test_out 'ok 1 - twice() was called 2 time(s)';
    verify($mock, times => 2)->twice();
    test_test 'times equal';

    my $name = 'twice() was called 1 time(s)';
    my $line = __LINE__ + 9;
    test_out "not ok 1 - $name";
    chomp($err = <<ERR);
#   Failed test '$name'
#   at $file line $line.
#          got: 2
#     expected: 1
ERR
    test_err $err;
    verify($mock, times => 1)->twice;
    test_test 'times not equal';
}

# subtest 'at_least' => sub {
{
    like exception { verify($mock, at_least => 'string') },
        qr/^'at_least' option must be a number/, 'invalid at_least';

    my $name = 'once() was called at least 1 time(s)';
    test_out "ok 1 - $name";
    verify($mock, at_least => 1)->once;
    test_test 'at_least';

    $name = 'once() was called at least 2 time(s)';
    my $line = __LINE__ + 10;
    test_out "not ok 1 - $name";
    chomp($err = <<ERR);
#   Failed test '$name'
#   at $file line $line.
#     '1'
#         >=
#     '2'
ERR
    test_err $err;
    verify($mock, at_least => 2)->once;
    test_test 'at_least not reached';
}

# subtest 'at_least()' => sub {
{
    like exception { verify($mock, times => at_least('string')) },
        qr/at_least\(\) must be given a number/, 'invalid at_least()';

    my $name = 'once() was called at least 1 time(s)';
    test_out "ok 1 - $name";
    verify($mock, times => at_least(1))->once;
    test_test 'at_least()';

    $name = 'once() was called at least 2 time(s)';
    my $line = __LINE__ + 10;
    test_out "not ok 1 - $name";
    chomp($err = <<ERR);
#   Failed test '$name'
#   at $file line $line.
#     '1'
#         >=
#     '2'
ERR
    test_err $err;
    verify($mock, times => at_least(2))->once;
    test_test( title => 'at_least() not reached', skip_err => 1 );
}

# subtest 'at_most' => sub {
{
    like exception { verify($mock, at_most => 'string') },
        qr/^'at_most' option must be a number/, 'invalid at_most';

    test_out 'ok 1 - twice() was called at most 2 time(s)';
    verify($mock, at_most => 2)->twice;
    test_test 'at_most';

    my $name = 'twice() was called at most 1 time(s)';
    my $line = __LINE__ + 10;
    test_out "not ok 1 - $name";
    chomp($err = <<ERR);
#   Failed test '$name'
#   at $file line $line.
#     '2'
#         <=
#     '1'
ERR
    test_err $err;
    verify($mock, at_most => 1)->twice;
    test_test 'at_most exceeded';
}

# subtest 'at_most()' => sub {
{
    like exception { verify($mock, times => at_most('string')) },
        qr/^at_most\(\) must be given a number/, 'invalid at_most()';

    my $name = 'twice() was called at most 2 time(s)';
    test_out "ok 1 - $name";
    verify($mock, times => at_most(2))->twice;
    test_test 'at_most()';

    $name = 'twice() was called at most 1 time(s)';
    my $line = __LINE__ + 10;
    test_out "not ok 1 - $name";
    chomp($err = <<ERR);
#   Failed test '$name'
#   at $file line $line.
#     '2'
#         <=
#     '1'
ERR
    test_err $err;
    verify($mock, times => at_most(1))->twice;
    test_test( title => 'at_most exceeded', skip_err => 1 );
}

# subest 'between' => sub {
{
    like exception { verify($mock, between => 1)->twice },
        qr/'between' option must be an arrayref with 2 numbers in ascending order/,
        'between - not arrayref';
    like exception { verify($mock, between => ['one', 'two'])->twice },
        qr/'between' option must be an arrayref with 2 numbers in ascending order/,
        'between - not numbers in arrayref';
    like exception { verify($mock, between => [2, 1])->twice },
        qr/'between' option must be an arrayref with 2 numbers in ascending order/,
        'between - numbers in arrayref not in order';

    my $name = 'twice() was called between 1 and 2 time(s)';
    test_out "ok 1 - $name";
    verify($mock, between => [1, 2])->twice;
    test_test 'between 1';

    $name = 'twice() was called between 2 and 3 time(s)';
    test_out "ok 1 - $name";
    verify($mock, between => [2, 3])->twice;
    test_test 'between 2';

    $name = 'twice() was called between 3 and 4 time(s)';
    test_out "not ok 1 - $name";
    test_fail +1;
    verify($mock, between => [3, 4])->twice;
    test_test 'not between 1';

    $name = 'twice() was called between 0 and 1 time(s)';
    test_out "not ok 1 - $name";
    test_fail +1;
    verify($mock, between => [0, 1])->twice;
    test_test 'not between 2';
}

like exception {
    verify($mock, times => 2, at_least => 2, at_most => 2)->twice
}, qr/^You can set only one of these options:/, 'multiple options';
