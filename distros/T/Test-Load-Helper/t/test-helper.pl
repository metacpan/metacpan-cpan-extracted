
use v5.14;
use warnings;

use Carp::Always;

use Test::More import => [qw[
	!cmp_ok
	!is
	!is_deeply
	!ok
]];
use Test::Deep qw[
	!cmp_bag
	!cmp_methods
	!cmp_set
];
use Test::Warnings v0.38 qw[
	:no_end_test
	had_no_warnings
];

use Path::Tiny 0.018;

our $counter;

sub do_not_expect_helper_function {
	my ($fqn, $expected_value) = @_;
	$expected_value //= 1;

	no strict q (refs);
	code (sub {
		defined &{ $fqn }
			? return (0, qq ($fqn is defined))
			: return 1
			;
	});
}

sub expect_all {
	all (@_)
}

sub expect_helper_function {
	my ($fqn, $expected_value) = @_;
	$expected_value //= 1;

	no strict q (refs);
	code (sub {
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

sub expect_re {
	re (@_)
}

sub fixtures_path {
	Path::Tiny::->new ((caller)[1])->parent->child (q (fixtures));
}

sub got (&) {
	eval {
		return +(got => shift->());
	};

	return +(died => $@);
}

sub it {
	my ($message, %args) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $got = $args{got};

	exists $args{throws}
		? cmp_deeply $args{died}, $args{throws}, $message
		: cmp_deeply $got, $args{expect}, $message
		;
}

sub setup_helper_root {
	$ENV{TEST_LOAD_ROOT} = fixtures_path ()->stringify;
}

1;
