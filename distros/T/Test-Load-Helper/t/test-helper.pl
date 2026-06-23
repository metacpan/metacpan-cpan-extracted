
use v5.14;
use warnings;

use Path::Tiny 0.018;
use Test::YAFT;

our $counter;

sub fixtures_path {
	Path::Tiny::->new ((caller)[1])->parent->child (q (fixtures));
}

sub setup_helper_root {
	$ENV{TEST_LOAD_ROOT} = fixtures_path ()->stringify;
}

sub expect_helper_function {
	my ($fqn, $expected_value) = @_;
	$expected_value //= 1;

	no strict q (refs);
	expect_code (sub {
		defined &{ $fqn }
			or return (0, qq ($fqn is not defined))
			;

		my $actual = &{ $fqn } ();
		$actual == $expected_value
			or return (0, qq ($fqn () returned $actual, expected $expected_value))
			;

		return 1;
	});
}

1;
