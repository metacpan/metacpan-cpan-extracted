
use v5.14;
use warnings;

# Test::Tester 1.302107 => Allow regexp in Test::Tester
use Test::Tester 1.302107 import => [qw[ !check_test ]];
use Test::Deep qw[];
use Test::More qw[];
use Test::Warnings qw[ :no_end_test ];

use Test::YAFT;

use Context::Singleton;

sub check_test (&;@) {
	my ($code, %expectations) = @_;

	Test::Tester::check_test $code, \%expectations;
}

1;
