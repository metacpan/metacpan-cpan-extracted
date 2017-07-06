use strict;
use warnings;

use Test::More tests => 18;
use Scalar::Util qw(weaken);
use curry;

sub dispose_ok($;$) {
	weaken(my $copy = $_[0]);
	fail("variable is not a ref") unless ref $_[0];
	undef $_[0];
	ok(!defined($copy), $_[1]);
}

{
	package Foo;
	sub new { bless {}, shift }
}

{ # basic behaviour - can we call without args?
	my $foo = Foo->new;

	my $called;
	my $code = $foo->$curry::curry(sub {
		ok(shift->isa('Foo'), '$curry::curry object is correct class');
		ok(!@_, '$curry::curry did not pick up any stray parameters');
		++$called;
	});
	fail('$curry::curry did not give us a coderef') unless ref($code) eq 'CODE';
	$code->();
	ok($called, 'curried code was called');
	undef $foo;
	$called = 0;
	$code->();
	ok($called, 'curried code executed successfully after original object goes out of scope');
}

{ # parameter passthrough
	my $foo = Foo->new;

	my $called;
	my $code = $foo->$curry::curry(sub {
		ok(shift->isa('Foo'), '$curry::curry object is correct class');
		is_deeply(\@_, [qw(one two three)], 'curried code had the expected parameters');
		++$called;
	});
	fail('$curry::curry did not give us a coderef') unless ref($code) eq 'CODE';
	$code->(qw(one two three));
	ok($called, 'curried code was called');
	undef $foo;
	$called = 0;
	$code->(qw(one two three));
	ok($called, 'curried code again executed successfully after original object goes out of scope');
}

{ # stashed parameters
	my $foo = Foo->new;

	my $called;
	my $code = $foo->$curry::curry(sub {
		ok(shift->isa('Foo'), '$curry::curry object is correct class');
		is_deeply(\@_, [qw(stashed parameters one two three)], 'curried code had the expected parameters');
		++$called;
	}, qw(stashed parameters));
	fail('$curry::curry did not give us a coderef') unless ref($code) eq 'CODE';
	$code->(qw(one two three));
	ok($called, 'curried code was called');
	undef $foo;
	$called = 0;
	$code->(qw(one two three));
	ok($called, 'curried code again executed successfully after original object goes out of scope');
}

done_testing;
