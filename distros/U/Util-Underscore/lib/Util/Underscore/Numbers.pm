package Util::Underscore::Numbers;

#ABSTRACT: Functions for dealing with numbers

use strict;
use warnings;


## no critic (ProhibitMultiplePackages)
package    # hide from PAUSE
    _;

## no critic (RequireArgUnpacking, RequireFinalReturn, ProhibitSubroutinePrototypes)

sub is_numeric(_) {
    goto &Scalar::Util::looks_like_number;
}

sub is_int(_) {
    ## no critic (ProhibitEnumeratedClasses)
    defined $_[0]
        && !defined ref_type $_[0]
        && scalar($_[0] =~ /\A [-]? [0-9]+ \z/xsm);
}

sub is_uint(_) {
    ## no critic (ProhibitEnumeratedClasses)
    defined $_[0]
        && !defined ref_type $_[0]
        && scalar($_[0] =~ /\A [0-9]+ \z/xsm);
}

sub ceil(_) {
    goto &POSIX::ceil;
}

sub floor(_) {
    goto &POSIX::floor;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Util::Underscore::Numbers - Functions for dealing with numbers

=head1 VERSION

version v1.4.2

=head1 FUNCTION REFERENCE

=over 4

=item C<$bool = _::is_numeric $scalar>

=item C<$bool = _::is_numeric>

Check whether Perl considers the C<$scalar> to be numeric in any way.

This includes integers and various floating point formats, but usually also C<NaN> and C<inf> and some other special strings.

wrapper for C<Scalar::Util::looks_like_number>

B<$scalar>:
the scalar to check for numericness.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> can be used as a numeric value.

=item C<$bool = _::is_int $scalar>

=item C<$bool = _::is_int>

Checks that the argument is a plain scalar,
and its stringification matches a signed integer.

B<$scalar>:
the scalar to be checked.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is an integer.

=item C<$bool = _::is_uint $scalar>

=item C<$bool = _::is_uint>

Like C<_::is_int>, but the stringification must match an unsigned integer
(i.e. the number is zero or positive).

B<$scalar>:
the scalar to be checked.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is an unsigned integer.

=item C<$int = _::ceil $float>

=item C<$int = _::ceil>

wrapper for C<POSIX::ceil>

B<$float>:
any number.
If omitted, uses C<$_>.

B<returns>:
a float representing the smallest integral value greater than or equal to the C<$float>.
If the C<$float> is not a finite number (i.e. infinite or NaN), then that input is returned.

=item C<$int = _::floor $float>

=item C<$int = _::floor>

wrapper for C<POSIX::floor>

This is different from the C<int()> builtin in that C<int()> I<truncates> a float towards zero,
and that C<int()> actually returns an integer.

B<$float>:
any number.
If omitted, uses C<$_>.

B<returns>:
a float representing the smallest integral value smaller than or equal to the argument.
If the C<$float> is not a finite number (i.e. infinite or NaN), then that input is returned.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/latk/p5-Util-Underscore/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Lukas Atkinson (cpan: AMON) <amon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lukas Atkinson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
