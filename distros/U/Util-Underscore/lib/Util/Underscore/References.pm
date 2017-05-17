package Util::Underscore::References;

#ABSTRACT: Functions for introspecting and manipulating references

use strict;
use warnings;


## no critic (ProhibitMultiplePackages)
package    # hide from PAUSE
    _;

## no critic (RequireArgUnpacking, RequireFinalReturn, ProhibitSubroutinePrototypes)

sub ref_addr(_) {
    goto &Scalar::Util::refaddr;
}

sub ref_type(_) {
    goto &Scalar::Util::reftype;
}

BEGIN {
    # perl 5.10 thinks reftype qr// eq 'SCALAR'.
    # This is bogus, we'll have to correct that.
    if ($^V < 5.011) {
        no warnings 'redefine';
        *ref_type = sub (_) {
            my $type = &Scalar::Util::reftype;
            return 'REGEXP'
                if defined $type
                and $type eq 'SCALAR'
                and ref $_[0] eq 'Regexp';
            return $type;
        };
    }
}

sub ref_weaken(_) {
    goto &Scalar::Util::weaken;
}

sub ref_unweaken(_) {
    goto &Scalar::Util::unweaken;
}

sub ref_is_weak(_) {
    goto &Scalar::Util::isweak;
}

sub is_ref(_) {
    defined($_[0])
        && defined ref_type $_[0]
        && !defined blessed $_[0];
}

sub is_scalar_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[${}])
        : do {
            my $type = ref_type $_[0] // q[];
            $type eq 'SCALAR' || $type eq 'REF';
        }
        );
}

sub is_array_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[@{}])
        : (ref_type $_[0] // q[]) eq 'ARRAY'
        );
}

sub is_hash_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[%{}])
        : (ref_type $_[0] // q[]) eq 'HASH'
        );
}

sub is_code_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[&{}])
        : (ref_type $_[0] // q[]) eq 'CODE'
        );
}

sub is_glob_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[*{}])
        : (ref_type $_[0] // q[]) eq 'GLOB'
        );
}

sub is_regex(_) {
    defined(blessed $_[0])
        && ('REGEXP' eq ref_type $_[0]
        || overload::Method($_[0], q[qr]));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Util::Underscore::References - Functions for introspecting and manipulating references

=head1 VERSION

version v1.4.2

=head1 FUNCTION REFERENCE

=over 4

=item C<$int = _::ref_addr $reference>

=item C<$int = _::ref_addr>

wrapper for C<Scalar::Util::refaddr>

This is mostly equivalent to the numification of a reference: C<0+$ref>.
However, that fails for objects which have overloaded addition, which is why you should use this function instead.

The ref address denotes identity:
two references with the same address are the same object.
However, the same address might be reused later, so storing the address is not useful.
Use weak references instead.

B<$reference>:
the reference to obtain the address of.
If omitted, uses C<$_>.

B<returns>:
an integer representing ther reference address if the input is any kind of reference (plain reference or object).
If the input is not a reference, C<undef> is returned.

=item C<$str = _::ref_type $reference>

=item C<$str = _::ref_type>

wrapper for C<Scalar::Util::reftype>

Accesses the type of the bare reference:
C<SCALAR>, C<REF>, C<ARRAY>, C<HASH>, C<CODE>, C<GLOB>, C<REGEXP>.
Unfortunately, regexes are special, so C<_::ref_type qr//> is C<REGEXP> while C<ref qr//> is C<Regexp>.

B<$reference>:
the reference to obtain the type of.
If omitted, uses C<$_>.

B<returns>:
the type of the reference.
For blessed references, this will not be the class, but the type of the blessed reference.
If the input is not a reference, C<undef> is returned.

=item C<_::ref_weaken $reference>

=item C<_::ref_weaken>

Turns the reference into a weak reference.

wrapper for C<Scalar::Util::weaken>

B<$reference>:
the reference to weaken.
If omitted, uses C<$_>.

B<returns>:
n/a

=item C<_::ref_unweaken $reference>

=item C<_::ref_unweaken>

Turns a weak reference into a normal reference.

wrapper for C<Scalar::Util::unweaken>

B<$reference>:
the reference to unweaken.
If omitted, uses C<$_>.

B<returns>:
n/a

=item C<$bool = _::ref_is_weak $reference>

=item C<$bool = _::ref_is_weak>

Checks whether the given reference is a weak reference.

wrapper for C<Scalar::Util::isweak>

B<$reference>:
the reference to check.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the given C<$reference> was a weak reference.

=back

=head3 Type Validation

These are inspired from C<Params::Util> and C<Data::Util>.

The I<reference validation> routines take one argument (or C<$_>) and return a boolean value.
They return true when the value is intended to be used as a reference of that kind:
either C<ref_type $arg> is of the requested type,
or it is an overloaded object that can be used as a reference of that kind.
It will not be checked that an object claims to perform an appropriate role (e.g. C<< $arg->DOES('ARRAY') >>).

=over 4

=item *

C<_::is_ref> (any nonblessed reference)

=item *

C<_::is_scalar_ref> (also references to references)

=item *

C<_::is_array_ref>

=item *

C<_::is_hash_ref>

=item *

C<_::is_code_ref>

=item *

C<_::is_glob_ref>

=item *

C<_::is_regex> (note that regexes are blessed objects, not plain references)

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
