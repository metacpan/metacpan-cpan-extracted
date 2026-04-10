package Test2::Bundle::Numerical;

use strict;
use warnings;
use base 'Exporter';

use Test2::Plugin::Numerical;
use Test2::Tools::Numerical qw(:all);

our @EXPORT = @Test2::Tools::Numerical::EXPORT;
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = ( all => \@EXPORT );

our $VERSION = '0.03';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Bundle::Numerical - Numerical Quadmath/longdouble aware Test2 bundle

=head1 SYNOPSIS

	use Test2::Bundle::Numerical qw(:all);

	plan 2;
	ok(1.555, 'basic pass');
	is(1.555, 1.555, 'numeric equality');

=head1 DESCRIPTION

This bundle loads C<Test2::Plugin::Numerical> and exports the full set of
numeric aware test tools from C<Test2::Tools::Numerical>.

The idea behind this bundle is to solve the dreaded quadmath/long double testing problem.
If you want to write numeric tests that work correctly regardless of the underlying NV type, this bundle is hopefully for you.

Alpha version to confirm it solves my problem, first via cpantesters.

=head1 EXPORTS

=over 4

=item ok($;$)

Basic pass/fail assertion.

=item is($$;$)

Numeric-aware equality assertion.

=item isnt($$;$)

Numeric-aware inequality assertion.

=item is_deeply($$;$)

Deep comparison of nested structures with numeric-aware scalar comparison.

=item diag($)

Emit diagnostic output.

=item plan($;@)

Set the test plan or run C<skip_all()>.

=item done_testing

Finish the test script without an explicit plan.

=item skip($;$)

Skip a test or tests with a reason.

=item skip_all($)

Skip all tests with a reason.

=item todo($;@)

Mark tests as TODO.

=item pass($)

Declare a passing test.

=item fail($)

Declare a failing test.

=item like($$;$)

Assert that a string matches a regex.

=item use_ok($;@)

Verify a module loads and imports correctly.

=item subtest($$)

Run a nested test block with a descriptive name.

=item is_lt($$;$)

Assert that one value is less than another.

=item is_lte($$;$)

Assert that one value is less than or equal to another.

=item is_gt($$;$)

Assert that one value is greater than another.

=item is_gte($$;$)

Assert that one value is greater than or equal to another.

=item approx_eq($$;$)

Approximate numeric equality using absolute tolerance.

=item approx_ok($$;$)

Alias for C<approx_eq>.

=item vec_approx_eq($$;$)

Compare numeric vectors element-wise.

=item vec_is($$;$)

Assert that two vectors are approximately equal.

=item vec_ok($$;$)

Alias for C<vec_is>.

=item vec_isnt($$;$)

Assert that two vectors are not approximately equal.

=item vec_ne($$;$)

Alias for C<vec_isnt>.

=item within_tolerance($$;$)

Float comparison using absolute tolerance.

=item within_tol($$;$)

Alias for C<within_tolerance>.

=item is_quadmath($)

Test if the current Perl build uses quadmath NVs.

=item is_long_double($)

Test if the current Perl build uses long double NVs.

=item is_infinite($;$)

Assert a value is infinite.

=item is_finite($;$)

Assert a value is finite.

=item get_tolerance($)

Return a tolerance appropriate for the current NV type.

=item float_is($$$;$)

Numeric float comparison with configurable rules.

=item float_isnt($$$;$)

Assert that float values are not equal.

=item float_ne($$$;$)

Alias for C<float_isnt>.

=item float_is_abs($$$;$)

Absolute tolerance float comparison.

=item float_is_ulps($$$;$)

ULP-based float comparison.

=item float_is_relative($$$;$)

Relative tolerance float comparison.

=item float_ok($$$;$)

Boolean float comparison using the default tolerance.

=item float_cmp($$;$)

Compare numeric values with tolerance, returning C<-1>, C<0>, or C<1>.

=item ulp_equal($$;$)

Assert two floats are within a ULP distance.

=item ulp_distance($$;$$$)

Compute float ULP distance, or compare it against a threshold.

=item relatively_equal($$;$)

Check relative equality within a tolerance.

=item relative_tolerance($;$)

Return a relative tolerance.

=item bits_equal($$;$)

Compare raw float bit patterns.

=item bits_ok($$$)

Assert exact float bit equality.

=item bits_compare($$)

Compare float bit representations.

=item bits_diff($$)

Return a bit-difference string.

=item bits_hex($)

Return the hex representation of a float's bits.

=item nan_ok($;$)

Assert a value is NaN.

=item nan_is($$$)

Assert that two values are both NaN or both equal.

=item nan_equal($$;$)

Compare values treating NaN as equal.

=item nv_info

Return information about the current NV type.

=item nv_epsilon

Return the machine epsilon for the current NV type.

=item nv_digits

Return the decimal digits of precision for the current NV type.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Test2-Bundle-Numerical at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test2-Bundle-Numerical>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Test2::Bundle::Numerical

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test2-Bundle-Numerical>

=item * Search CPAN

L<https://metacpan.org/release/Test2-Bundle-Numerical>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
