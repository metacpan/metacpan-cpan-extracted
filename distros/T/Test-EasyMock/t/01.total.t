use strict;
use warnings;

use Test::More;
BEGIN {
    use_ok('Test::EasyMock',
           qw{
               create_mock
               expect
               replay
               reset
               verify
               whole
           });
}
use Test::Deep qw(ignore);
use Test::Exception;
use Scalar::Util qw(weaken);

# ----
# Tests.
subtest 'default mock' => sub {
    my $mock = create_mock();

    subtest 'array arguments and array result' => sub {
        my @args = qw(arg1 arg2 arg3);
        my @result = qw(result1 result2 result3);
        expect($mock->foo(@args))->and_array_return(@result);
        replay($mock);

        my @actual = $mock->foo(@args);

        is_deeply(\@actual, \@result, 'result');
        verify($mock);
    };

    reset($mock);

    subtest 'named parameter and scalar result' => sub {
        my $args = { arg1 => 1, arg2 => 2, arg3 => 3 };
        my $result = { result1 => 1, result2 => 2, result3 => 3 };
        expect($mock->foo($args))->and_scalar_return($result);
        replay($mock);

        my $actual = $mock->foo($args);

        is_deeply($actual, $result, 'result');
        verify($mock);
    };

    reset($mock);

    subtest 'expect and_list_return in list context' => sub {
        my ($result1, $result2, $result3) = qw(result1 result2 result3);
        expect($mock->foo)->and_list_return($result1, $result2, $result3);
        replay($mock);

        my @actual = $mock->foo;

        is_deeply(\@actual, [$result1, $result2, $result3], 'result');
        verify($mock);
    };

    reset($mock);

    subtest 'expect and_list_return in scalar context' => sub {
        my ($result1, $result2, $result3) = qw(result1 result2 result3);
        expect($mock->foo)->and_list_return($result1, $result2, $result3);
        replay($mock);

        my $actual = $mock->foo;

        is($actual, $result3, 'result');
        verify($mock);
    };

    reset($mock);

    subtest 'expect and_answer' => sub {
        my $result = 'result';
        expect($mock->foo)->and_answer(sub { $result });
        replay($mock);

        my $actual = $mock->foo;

        is($actual, $result, 'result');
        verify($mock);
    };

    reset($mock);

    subtest 'expect and_die' => sub {
        my $error = 'an error message';
        expect($mock->foo)->and_die($error);
        replay($mock);

        throws_ok { $mock->foo } qr{$error}, 'throw error';

        verify($mock);
    };

    reset($mock);

    subtest 'with Test::Deep comparison parameter' => sub {
        my $result1 = 'a result of first.';
        my $result2 = 'a result of sencond.';
        my $result3 = 'a result of third.';
        expect($mock->foo( ignore(), ignore() ))->and_scalar_return($result1);
        expect($mock->foo( ignore() ))->and_scalar_return($result2);
        expect($mock->foo( whole(ignore()) ))->and_scalar_return($result3);
        replay($mock);

        my $actual1 = $mock->foo(1, 2);
        my $actual2 = $mock->foo({ arg1 => 1, arg2 => 2 });
        my $actual3 = $mock->foo(1, 2, 3);

        is($actual1, $result1, 'result1');
        is($actual2, $result2, 'result2');
        is($actual3, $result3, 'result3');
        verify($mock);
    };

    reset($mock);

    subtest 'multiple `expect` to same method and argument.' => sub {
        my $args = 'argument';
        my $result1 = 'a result of first.';
        my $result2 = 'a result of second.';

        expect($mock->foo($args))->and_scalar_return($result1);
        expect($mock->foo($args))->and_scalar_return($result2);
        replay($mock);

        my $actual1 = $mock->foo($args);
        my $actual2 = $mock->foo($args);

        is($actual1, $result1, 'result1');
        is($actual2, $result2, 'result2');
        verify($mock);
    };

    reset($mock);

    subtest 'multiple `expect` to same method and different argument.' => sub {
        my $args1 = 'argument1';
        my $args2 = 'argument2';
        my $result1 = 'a result of first.';
        my $result2 = 'a result of second.';

        expect($mock->foo($args1))->and_scalar_return($result1);
        expect($mock->foo($args2))->and_scalar_return($result2);
        replay($mock);

        my $actual2 = $mock->foo($args2);
        my $actual1 = $mock->foo($args1);

        is($actual1, $result1, 'result1');
        is($actual2, $result2, 'result2');
        verify($mock);
    };

    reset($mock);

    subtest 'multiple `expect` to different method.' => sub {
        my $args = 'argument';
        my $result1 = 'a result of first.';
        my $result2 = 'a result of second.';

        expect($mock->foo($args))->and_scalar_return($result1);
        expect($mock->bar($args))->and_scalar_return($result2);
        replay($mock);

        my $actual2 = $mock->bar($args);
        my $actual1 = $mock->foo($args);

        is($actual1, $result1, 'result1');
        is($actual2, $result2, 'result2');
        verify($mock);
    };

    reset($mock);

    subtest 'multiple `and_[scalar|array]_return.' => sub {
        my $args = 'argument';
        my $result1 = 'a result of first';
        my @result2 = qw(a result of second);
        my $result3 = 'a result of third';

        expect($mock->foo($args))
            ->and_scalar_return($result1)
            ->and_array_return(@result2)
            ->and_scalar_return($result3);
        replay($mock);

        my $actual1 = $mock->foo($args);
        my @actual2 = $mock->foo($args);
        my $actual3 = $mock->foo($args);

        is($actual1, $result1, 'result1');
        is_deeply(\@actual2, \@result2, 'result2');
        is($actual3, $result3, 'result3');
        verify($mock);
    };

    reset($mock);

    subtest 'and_stub_scalar_return' => sub {
        my $args1 = 'argument';
        my $result1_1 = 'a result of first.';
        my $result1_2 = 'a result of second.';
        my $args2 = 'other';
        my $result2 = 'a result of other.';

        expect($mock->foo($args1))->and_scalar_return($result1_1);
        expect($mock->foo($args1))->and_stub_scalar_return($result1_2);
        expect($mock->foo($args2))->and_stub_scalar_return($result2);
        replay($mock);

        my $actual1_1 = $mock->foo($args1);
        my $actual1_2 = $mock->foo($args1);
        my $actual1_3 = $mock->foo($args1);
        my $actual2 = $mock->foo($args2);

        is($actual1_1, $result1_1, 'result1_1');
        is($actual1_2, $result1_2, 'result1_2');
        is($actual1_3, $result1_2, 'result1_3');
        is(  $actual2,   $result2,   'result2');

        verify($mock);
    };

    reset($mock);

    subtest 'expect with `stub_scalar_return`, but no call mock method.' => sub {
        expect($mock->foo())->and_stub_scalar_return('');
        replay($mock);
        verify($mock); # pass
    };

    reset($mock);

    subtest 'and_stub_array_return' => sub {
        my $args1 = 'argument';
        my @result1_1 = ('a result of first.');
        my @result1_2 = ('a result of second.');
        my $args2 = 'other';
        my @result2 = ('a result of other.');

        expect($mock->foo($args1))->and_array_return(@result1_1);
        expect($mock->foo($args1))->and_stub_array_return(@result1_2);
        expect($mock->foo($args2))->and_stub_array_return(@result2);
        replay($mock);

        my @actual1_1 = $mock->foo($args1);
        my @actual1_2 = $mock->foo($args1);
        my @actual1_3 = $mock->foo($args1);
        my @actual2 = $mock->foo($args2);

        is_deeply(\@actual1_1, \@result1_1, 'result1_1');
        is_deeply(\@actual1_2, \@result1_2, 'result1_2');
        is_deeply(\@actual1_3, \@result1_2, 'result1_3');
        is_deeply(  \@actual2,   \@result2,   'result2');

        verify($mock);
    };

    reset($mock);

    subtest 'expect with `stub_array_return`, but no call mock method.' => sub {
        expect($mock->foo())->and_stub_array_return('');
        replay($mock);
        verify($mock); # pass
    };

    reset($mock);

    subtest 'and_stub_list_return' => sub {
        my $args1 = 'argument';
        my @result1_1 = ('a result of first-1.', 'a result of first-2.');
        my @result1_2 = ('a result of second-1.', 'a result of second-2.');
        my $args2 = 'other';
        my @result2 = ('a result of other-1.', 'a result of other-2.');

        expect($mock->foo($args1))->and_list_return(@result1_1);
        expect($mock->foo($args1))->and_stub_list_return(@result1_2);
        expect($mock->foo($args2))->and_stub_list_return(@result2);
        replay($mock);

        my @actual1_1 = $mock->foo($args1);
        my @actual1_2 = $mock->foo($args1);
        my $actual1_3 = $mock->foo($args1);
        my @actual2 = $mock->foo($args2);

        is_deeply(\@actual1_1, \@result1_1, 'result1_1');
        is_deeply(\@actual1_2, \@result1_2, 'result1_2');
        is($actual1_3, $result1_2[1], 'result1_3');
        is_deeply(  \@actual2,   \@result2,   'result2');

        verify($mock);
    };

    reset($mock);

    subtest 'expect with `stub_list_return`, but no call mock method.' => sub {
        expect($mock->foo())->and_stub_list_return('');
        replay($mock);
        verify($mock); # pass
    };

    reset($mock);

    subtest 'and_stub_answer' => sub {
        my $args1 = 'argument';
        my $result1_1 = 'a result of first.';
        my $result1_2 = 'a result of second.';
        my $args2 = 'other';
        my $result2 = 'a result of other.';
        expect($mock->foo($args1))->and_answer(sub { $result1_1 });
        expect($mock->foo($args1))->and_stub_answer(sub { $result1_2 });
        expect($mock->foo($args2))->and_stub_answer(sub { $result2 });
        replay($mock);

        my $actual1_1 = $mock->foo($args1);
        my $actual1_2 = $mock->foo($args1);
        my $actual1_3 = $mock->foo($args1);
        my $actual2 = $mock->foo($args2);

        is($actual1_1, $result1_1, 'result1_1');
        is($actual1_2, $result1_2, 'result1_2');
        is($actual1_3, $result1_2, 'result1_2');
        is($actual2, $result2, 'result2');
        verify($mock);
    };

    reset($mock);

    subtest 'and_stub_die' => sub {
        my $args1 = 'argument';
        my $error1_1 = 'an error message of first';
        my $error1_2 = 'an error message of second';
        my $args2 = 'other';
        my $error2 = 'an error message of other';

        expect($mock->foo($args1))->and_die($error1_1);
        expect($mock->foo($args1))->and_stub_die($error1_2);
        expect($mock->foo($args2))->and_stub_die($error2);
        replay($mock);

        throws_ok { $mock->foo($args1) } qr{$error1_1}, 'throw error1_1';
        throws_ok { $mock->foo($args1) } qr{$error1_2}, 'throw error1_2';
        throws_ok { $mock->foo($args1) } qr{$error1_2}, 'throw error1_2';
        throws_ok { $mock->foo($args2) } qr{$error2}, 'throw error2';

        verify($mock);
    };

    reset($mock);

    subtest 'expect with `stub_die`, but no call mock method.' => sub {
        expect($mock->foo())->and_stub_die('');
        replay($mock);
        verify($mock); # pass
    };

    reset($mock);

    subtest 'destroy mock object' => sub {
        my $weak_ref_mock = $mock;
        weaken($weak_ref_mock);
        undef($mock);
        is($weak_ref_mock, undef, 'mock is destroied.');
    };
};


# ----
done_testing;
