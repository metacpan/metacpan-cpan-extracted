
use v5.14;
use warnings;

use Test::YAFT;
use Type::Tiny;

sub expect_failed_constraint_exception {
	my ($re) = @_;

	$re //= qr/did not pass type constraint/;
	$re = qr/^\Q$re\E/ unless ref $re;

	expect_re ($re);
}

sub constraint (&) {
	my ($constraint) = @_;

	act {
		my $rv = $constraint->()->validate (@_);

		die $rv if $rv;

		1;
	} 'value';
}

sub this_constraint ($;@) {
	my ($message, %params) = @_;

	Test::YAFT::test_frame {
		it $message
			=> with_value => delete $params{value}
			=> %params
		;
	}
}

1;
