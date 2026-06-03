
use v5.14;
use warnings;

use feature qw (state);

use Sub::Override;

# Test::Tester 1.302107 => Allow regexp in Test::Tester
use Test::Tester 1.302107 import => [qw ( !check_test )];

use Test::YAFT;

use Context::Singleton;
use List::Util;

my $SINGLETON_EXPECTATION = \ q (testing-expectation);

my @assumptions = sort
	q (assume),
	q (it),
	q (there),
	;

my $test_deep_render_val = \ &Test::Deep::render_val;

sub assumption_under_test;

sub _anonymous_importer {
	my ($symbol, $exported, $import, $returns) = @_;

	state $serial = 0;
	state $prefix = q (Test::Export::__ANON__::);

	$import = defined ($import)
		? qq (q ($import))
		: q ()
		;

	my $package = $prefix . ++$serial;

	$symbol = q (&) . $symbol
		if $symbol =~ m (^\w)
		;

	$returns //= qq {
		local \$_ = \\ $symbol;

		Ref::Util::is_coderef (\$_) ? defined &\$_ : defined \$_;
	};

	my $eval = qq {
		package ${package} {
			use strict;
			use $exported $import;

			$returns;
		};
	};

	eval $eval
		// die $@
		;
}

sub _override_render_val {
	my ($value) = @_;

	# Replace refaddr with '...'
	$test_deep_render_val->($value)
		=~ s ( ((?: ^ | =)\w+) [(] 0x [0-9a-f]+ [)] ) ($1(0x...))rgx
		;
}

sub assume_test_yaft_exports {
	my ($symbol, %args) = @_;

	my %tags = (
		all          => 1,
		default      => 0,
		asserts      => 0,
		assumptions  => 0,
		expectations => 0,
		foundations  => 0,
		helpers      => 0,
		plumbings    => 0,
		utils        => 0,
	);

	for my $tag (@{ $args{by_tag} // [] }) {
		$tags{$tag} = 1;
	}

	Test::YAFT::test_frame {
		subtest qq (importing $symbol) => sub {
			it q (is exported by default)
				=> got    { _anonymous_importer $symbol => Test::YAFT:: }
				=> expect => expect_bool ($args{by_default})
				;

			it q (is exportable on demand)
				=> got    { _anonymous_importer $symbol => Test::YAFT:: => $symbol }
				=> expect => expect_bool ($args{on_demand})
				;

			for my $tag (sort keys %tags) {
				it qq (is exportable by tag: $tag)
					=> got    { _anonymous_importer $symbol => Test::YAFT:: => qq (:$tag) }
					=> expect => expect_bool ($tags{$tag})
					;
			}
		};
	};
}

sub assume_yaft_dump {
	my ($message, @args) = @_;

	my %args = Test::YAFT::_test_yaft_assumption_args (@args);

	my $result = Test::YAFT::_build_got (\ %args);
	my $value = $result->{value};

	local $Data::Dumper::Deparse   = 1;
	local $Data::Dumper::Indent    = 1;
	local $Data::Dumper::Purity    = 0;
	local $Data::Dumper::Terse     = 1;
	local $Data::Dumper::Deepcopy  = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Useperl   = 1;
	local $Data::Dumper::Sortkeys  = 1;

	my $dumped = Test::YAFT::Dumper::Dumper ($value);
	my $expect = $args{expect};

	$dumped =~ s (\n+$) ()x;
	$expect =~ s (\n+$) ()x;

	assume $message
		=> got    => $dumped
		=> expect => $expect
		;
}

sub assumption (&;@) {
	my ($code) = shift;

	return check_test => $code, @_;
}

sub check_assumptions {
	my ($message, %arguments) = @_;

	my $check_test   = delete $arguments{check_test};
	my %expectations = (
		diag   => q (),
		reason => q (),
		type   => q (),
		%arguments,
	);

	# Test::Tester does not like when diag message contains refaddresses
	my $guard = Sub::Override::->new (q (Test::Deep::render_val) => \ &_override_render_val);

	Test::YAFT::test_frame {
		subtest $message => sub {
			for my $assumption (@assumptions) {
				local *assumption_under_test = __PACKAGE__->can ($assumption);
				subtest qq (using $assumption ()) => sub {
					Test::Tester::check_test (
						$check_test,
						\ %expectations,
						qq ($assumption ()),
					);
				};
			}
		};
	};
}

sub check_test {
	my ($message, %arguments) = @_;

	my $check_test   = delete $arguments{check_test};
	my %expectations = (
		diag   => q (),
		reason => q (),
		type   => q (),
		%arguments,
	);

	# Test::Tester does not like when diag message contains refaddresses
	my $guard = Sub::Override::->new (q (Test::Deep::render_val) => \ &_override_render_val);

	Test::YAFT::test_frame {
		subtest $message => sub {
			Test::Tester::check_test (
				$check_test,
				\ %expectations,
				$message,
			);
		};
	};
}

sub expectation {
	deduce ($SINGLETON_EXPECTATION)->(@_);
}

sub testing_expectation (&) {
	my ($code) = @_;

	arrange { $SINGLETON_EXPECTATION => $code };
}

1;
