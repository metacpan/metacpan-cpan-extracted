use strict;
use warnings;

use Test::More;
use Scalar::Util qw(weaken);
use curry::weak;

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
	my $code = $foo->$curry::weak(sub {
		ok(shift->isa('Foo'), '$curry::weak object is correct class');
		ok(!@_, '$curry::weak did not pick up any stray parameters on the way in');
		++$called;
	});
	fail('$curry::weak::curry did not give us a coderef') unless ref($code) eq 'CODE';
	$code->();
	ok($called, 'curried code was called');
	dispose_ok($foo, '$foo departs without a fight');
	$called = 0;
	$code->();
	ok(!$called, '... and we can still use the coderef as a no-op');
}

{ # parameter passthrough
	my $foo = Foo->new;

	my $called;
	my $code = $foo->$curry::weak(sub {
		ok(shift->isa('Foo'), '$curry::weak object is correct class');
		is_deeply(\@_, [qw(stashed parameters one two three)], 'args passed as expected');
		++$called;
	}, qw(stashed parameters));
	fail('$curry::weak::curry did not give us a coderef') unless ref($code) eq 'CODE';
	$code->(qw(one two three));
	ok($called, 'curried code was called');
	dispose_ok($foo, '$foo departs without a fight');
	$called = 0;
	$code->();
	ok(!$called, '... and we can still use the coderef as a no-op');
}

done_testing;
