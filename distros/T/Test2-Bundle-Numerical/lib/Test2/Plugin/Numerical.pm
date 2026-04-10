package Test2::Plugin::Numerical;
use strict;
use warnings;
use Test2::API qw/test2_add_callback_context_release/;

our $VERSION = '0.03';

my $LOADED;
sub import {
	return if $LOADED++;

	test2_add_callback_context_release(sub {
		my $ctx = shift;
		my $hub = $ctx->hub;

		return if $hub->failed == 0;

		my $numerical = $ctx->numerical;
		return unless $numerical->{numeric_failure}{active};

		my $info = $numerical->{nv_info};
		my $mode = $info->{is_quadmath} ? 'quadmath' : $info->{is_long_double} ? 'long double' : 'double';

		$ctx->diag('Test2::Plugin::Numerical: Numeric environment details:');
		$ctx->diag(sprintf('  NV type:               %s', $info->{type}));
		$ctx->diag(sprintf('  NV mode:               %s', $mode));
		$ctx->diag(sprintf('  precision digits:      %d', $info->{digits}));
		$ctx->diag(sprintf('  machine epsilon:       %g', $numerical->{nv_epsilon}));
		$ctx->diag(sprintf('  relative tolerance(4): %g', $numerical->{relative_tolerance}));
		$ctx->diag(sprintf('  default absolute tol:  %g', $numerical->{default_tolerance}));

		if (defined $numerical->{numeric_failure}{method}) {
			$ctx->diag('  Numeric comparison failure:');
			$ctx->diag(sprintf('    method:   %s', $numerical->{numeric_failure}{method}));
			$ctx->diag(sprintf('    got:      %s', defined $numerical->{numeric_failure}{got} ? $numerical->{numeric_failure}{got} : 'undef'));
			$ctx->diag(sprintf('    expected: %s', defined $numerical->{numeric_failure}{expected} ? $numerical->{numeric_failure}{expected} : 'undef'));
			$ctx->diag(sprintf('    details:  %s', $numerical->{numeric_failure}{details} // 'none'));
		}

		$numerical->{numeric_failure}{active} = 0;
	});
}

1;
