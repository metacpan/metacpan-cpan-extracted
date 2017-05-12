package Util::Underscore::Scalars;

#ABSTRACT: Functions for introspecting and manipulating scalars

use strict;
use warnings;


## no critic (ProhibitMultiplePackages)
package    # hide from PAUSE
    _;

## no critic (RequireArgUnpacking, RequireFinalReturn, ProhibitSubroutinePrototypes)

## no critic (ProtectPrivateVars)
$Util::Underscore::_ASSIGN_ALIASES->('Scalar::Util', new_dual => 'dualvar');

sub is_dual(_) {
    goto &Scalar::Util::isdual;
}

sub is_vstring(_) {
    goto &Scalar::Util::isvstring;
}

sub is_readonly(_) {
    goto &Scalar::Util::readonly;
}

## no critic (ProtectPrivateVars)
$Util::Underscore::_ASSIGN_ALIASES->('Const::Fast', const => 'const');

sub is_tainted (_) {
    goto &Scalar::Util::tainted;
}

if (eval q{use Data::Alias 1.18 (); 1}) {  ## no critic (ProhibitStringyEval)
    ## no critic (ProtectPrivateVars)
    $Util::Underscore::_ASSIGN_ALIASES->('Data::Alias', alias => 'alias');
}

sub is_plain(_) {
    defined $_[0]
        && !defined ref_type $_[0];
}

sub is_string(_) {
    defined $_[0]
        && (!defined ref_type $_[0]
        || overload::Method($_[0], q[""]));
}

sub is_bool(_) {
    !defined ref_type $_[0]
        || overload::Method($_[0], q[bool]);
}

sub is_identifier(_) {
    defined $_[0]
        && scalar($_[0] =~ /\A [^\W\d]\w* \z/xsm);
}

sub is_package(_) {
    defined $_[0]
        && scalar($_[0] =~ /\A [^\W\d]\w* (?: [:][:]\w+ )* \z/xsm);
}

sub chomp(_;$) {

    # localizedly set the input record separator
    local $/ = $/;
    if (@_ > 1) {
        if (_::is_string $_[1]) {
            $/ = "$_[1]";
        }
        else {
            Carp::croak q(_::chomp: second argument must be a string);
        }
    }

    # handle a single string
    # ATTENTION: this depends on _::is_string
    if (_::is_string $_[0]) {
        CORE::chomp(my $copy = $_[0]);
        return $copy;
    }

    # handle an arrayref of strings (effectively auto-mapping)
    # ATTENTION: _::is_array_ref will be defined later
    elsif (_::is_array_ref($_[0])) {
        my @result = @{ $_[0] };
        for (@result) {
            goto ERROR if not _::is_string;
            CORE::chomp;
        }
        return \@result;
    }

    ERROR:
    Carp::croak
        q(_::chomp: first argument must be string or arrayref of strings);
}

sub index($$;$) {
    if (@_ >= 3 and $_[2] < 0) {
        Carp::croak q(_::index: starting position must be non-negative.)
    }
    my $result = CORE::index($_[0], $_[1], $_[2] // 0);
    return ($result >= 0) ? $result : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Util::Underscore::Scalars - Functions for introspecting and manipulating scalars

=head1 VERSION

version v1.4.1

=head1 FUNCTION REFERENCE

=over 4

=item C<$scalar = _::new_dual $num, $str>

Creates a new dualvar with numeric value C<$num> and string value C<$str>.

In Perl, scalars contain both a numeric value and a string value.
Usually, Perl freely converts between the two values.
A dualvar disables the syncing between the two values, so that the string value and the numeric value can be completely unrelated.

wrapper for C<Scalar::Util::dualvar>

B<$num>:
the value for the numeric slot

B<$str>:
the value for the string slot

B<returns>:
a new dualvar

=item C<$bool = _::is_dual $scalar>

=item C<$bool = _::is_dual>

Checks whether the given scalar is a dualvar.

wrapper for C<Scalar::Util::isdual>

B<$scalar>:
the scalar to check. If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is a dualvar.

=item C<$bool = _::is_vstring $scalar>

=item C<$bool = _::is_vstring>

Checks whether the given C<$scalar> was created as a v-string like C<v127.0.0.1> or C<v1.0.3>.

wrapper for C<Scalar::Util::isvstring>

B<$scalar>:
the scalar to check.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is a v-string.

=item C<< _::const LVALUE => VALUE >>

Creates a readonly variable containing the specified value.

Note that this makes a deep immutable copy of the value instead of only disallowing reassignment.
This works for scalars, arrays, and hashes.
Certain care has to be taken for hashes because this locks the keys,
and using an illegal key would blow up with an error.
Therefore: always use S<C<exists $hash{$key}>> to see whether a key exists.

Examples:

    _::const my $const => 42;
    _::const my @const => 1, 2, 3;
    _::const my %const => a => 1, b => 2;

Wrapper for C<const> from L<Const::Fast|Const::Fast>.

B<LVALUE>:
an lvalue (scalar, hash, or array variable) to make constant.

B<VALUE>:
the value to make deeply immutable and assign.
The expression is always evaluated in list context, but the length of the resulting list must match the lvalue type.

B<returns>:
n/a

=item C<$bool = _::is_readonly $scalar>

=item C<$bool = _::is_readonly>

Checks whether the given scalar is readonly, i.e. can't be reassigned.

wrapper for C<Scalar::Util::readonly>

B<$scalar>:
the scalar to check for readonlyness.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the C<$scalar> is readonly.

=item C<$bool = _::is_tainted $scalar>

=item C<$bool = _::is_tainted>

Checks whether the C<$scalar> is tainted.

Tainted values come from untrusted sources, such as user input, environment variables, or file contents.
The result of a computation with tainted values is itself tainted.
Tainting is only traced when requested via the C<-t> or C<-T> command line switch.
If activated, certain builtins will refuse to execute with tainted input, such as C<open> or C<system>.
See L<perlsec|perlsec/"Taint mode"> for more information.

wrapper for C<Scalar::Util::tainted>

B<$scalar>:
the scalar to check for taintedness.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the C<$scalar> is tainted.

=item C<_::alias my $alias = $orig>

Aliases the first variable to the second scalar, unlike normal assignment which assigns a copy.

Afterwards, the C<$alias> will be another name for the C<$orig> scalar, so C<\$alias == \$orig> will always be true.
As the same scalar is now accessible by two names, changes are also visible under the other name.

Aliases occur naturally with the C<for>, C<map>, and C<grep> builtins:

    my @values = qw(a b c);
    for (@values) {
        # now $_ is an alias for the current element
        $_ = 42;
    }
    # @values = (42, 42, 42)

but also with subroutine parameters:

    sub assign {
        # the values in @_ are aliases for the arguments
        $_[0] = $_[1];
        return;
    }

    my $x = "foo";
    assign $x => "bar";
    # $x = "bar"

This function is an alias (heh) for the functionality in L<Data::Alias|Data::Alias>.

B<Only available if Data::Alias is already installed.>
Since Data::Alias has problems with some perl versions,
it is not a required dependency.

B<$alias>:
an additional name for the C<$orig> scalar.

B<$orig>:
The alias target.

B<returns>:
n/a

=item C<$bool = _::is_plain $scalar>

=item C<$bool = _::is_plain>

Checks that the value is C<defined> and not a reference of any kind.

This is as close as Perl gets to checking for an ordinary string.

B<$scalar>:
the scalar to check.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the scalar is plain.

=item C<$bool = _::is_string $scalar>

=item C<$bool = _::is_string>

Checks that the value is intended to be usable as a string:
Either C<_::is_plain> returns true, or it is an object that has overloaded stringification.

This does not test that the scalar has ever been used as a string, or was assigned as a string, only that it I<can> be used as a string.
Note that some data structures (like references) do have a stringification, but this is rarely intended to be actually used and therefore rejected.

B<$scalar>:
the scalar to check for stringiness.

B<returns>:
a boolean indicating whether the scalar is string-like.

=item C<$bool = _::is_bool $scalar>

=item C<$bool = _::is_bool>

Checks that the value is intended to be usable as a boolean:
The argument can either be a non-reference (i.e. plain scalar or undef), or can be an object that overloads C<bool>.

This does not check that the argument is some specific value such as C<1> or C<0>.
Note also that I<any> value will be interpreted as a boolean by Perl, but not by this function.
For example plain references are true-ish, while this function would not consider them to be a valid boolean value.

B<$scalar>:
the scalar to check.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the given C<$scalar> can be considered to be a boolean by the rules of this function.

=item C<$bool = _::is_identifier $string>

=item C<$bool = _::is_identifier>

Checks that the given string would be a legal identifier:
a letter followed by zero or more word characters.

B<$string>:
a string possibly containing an identifier.

B<returns>:
a boolean indicating whether the string looks like an identifier.

=item C<$bool = _::is_package $string>

=item C<$bool = _::is_package>

Checks that the given string is a valid package name.
It only accepts C<Foo::Bar> notation, not the C<Foo'Bar> form.
This does not assert that the package actually exists.

B<$string>:
a string possibly containing a package name.

B<returns>:
a boolean indicating whether the given string looks like a package name.

=item C<$str = _::chomp>

=item C<$str = _::chomp $line>

=item C<$str = _::chomp $line, $end>

=item C<$str_array = _::chomp \@lines>

=item C<$str_array = _::chomp \@lines, $end>

Performs the C<chomp> builtin on a I<copy> of the input – this will not modify the input.

B<$line>, B<\@lines>:
a string or a reference to an array of strings.
These will not be modified.
If omitted, uses C<$_>.

B<$end>:
a string designating the I<input record separator>.
If not specified, uses C<$/>.

B<returns>:
If given a single C<$line>, returns a copy of that string with the C<end> removed.
If given multiple C<\@lines>, returns an array reference containing copies of the input lines, with the C<$end> removed from each copy.

Examples:

    # assuming the default $/ = "\n":
    _::chomp ["foo\n", "bar", "baz\n"];
    #=> ["foo", "bar", "baz"]
    
    # removing a custom terminator:
    _::chomp "foobar", "bar";
    #=> "foo"

=item C<$pos = _::index $haystack, $needle>

=item C<$pos = _::index $haystack, $needle, $start>

Wraps the builtin C<index> function to return C<undef> rather than C<-1> if the C<$needle> wasn't found in the C<$haystack>.

B<$haystack>:
a string in which to search.

B<$needle>:
a string for which to search.

B<$start>:
the position at which to start searching.
This must be a non-negative integer.
Defaults to zero.

B<returns>:
The position at which the C<$needle> was found in the C<$haystack>,
If no match was found, returns C<undef>.

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
