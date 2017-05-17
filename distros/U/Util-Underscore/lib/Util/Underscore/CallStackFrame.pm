package Util::Underscore::CallStackFrame;

#ABSTRACT: object-oriented wrapper for "caller" builtin

use strict;
use warnings;

use Carp ();

## no critic (RequireFinalReturn)
# reason: performance and terse code.
# All methods are supposed to return something.

## no critic (ProhibitMagicNumbers)
# reason: the "caller" builtin is full of magic numbers.
# This class wraps them so that users don't have to deal with them.


sub of {
    my ($class, $level) = @_;

    package DB;    ## no critic (ProhibitMUltiplePackages)
    my @caller = CORE::caller($level + 1);
    return if not @caller;
    push @caller, [@DB::args];    ## no critic (ProhibitPackageVars)
    return bless \@caller => $class;
}


## no critic (ProhibitBuiltinHomonyms)
sub package { shift()->[0] }


sub file { shift()->[1] }


sub line { shift()->[2] }


sub subroutine { shift()->[3] }


sub has_args {
    my ($self) = @_;
    $self->[4] && $self->[11];
}


sub wantarray { shift()->[5] }


sub is_eval {
    my ($self) = @_;
    if ($self->[3] eq '(eval)') {
        my $accessor_object = [ @{$self}[ 6, 7 ] ];
        bless $accessor_object => 'Util::Underscore::CallStackFrame::_Eval';
        return $accessor_object;
    }
    else {
        return !!0;
    }
}

{
    ## no critic (ProhibitMUltiplePackages)
    package Util::Underscore::CallStackFrame::_Eval;

    sub source { shift()->[0] }

    sub is_require { shift()->[1] }
}


sub is_require { shift()->[7] }


sub hints { shift()->[8] }


sub bitmask { shift()->[9] }


sub hinthash { shift()->[10] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Util::Underscore::CallStackFrame - object-oriented wrapper for "caller" builtin

=head1 VERSION

version v1.4.2

=head1 SYNOPSIS

    (caller(4))[3];
    # is equivalent to
    Util::Underscore::CallStackFrame->of(4)->subroutine;

=head1 DESCRIPTION

This is a wrapper class for the C<caller> builtin, to allow access to the fields by name.
See L<the C<caller> documentation|perlfunc/caller> for more details.

=head1 METHODS

=over 4

=item C<of($level)>

This class method is a factory method.
It returns an object-oriented view on the C<caller> builtin.

B<$level>:
An integer indicating the call stack frame level to return.
A level of zero indicates the current level (from the perspective of an immediate user of this class).
Negative values are illegal.

B<returns>:
A C<Util::Underscore::CallStackFrame> instance for the requested stack frame.
If no such level exists, C<undef> is returned.

=item C<package>

The package from which the function was called.

    package Foo;
    
    Bar::baz() eq __PACKAGE__ or die;
    
    package Bar;
    
    sub baz {
        return Util::Underscore::CallStackFrame->of(0)->package;
    }

B<returns>:
This stack frame's package name, as a string.

=item C<file>

The file name where the function was called.

B<returns>:
The file name, as a string.

=item C<line>

The line where the function was called.
Note that this isn't necessarily the exact line, but sometimes the line where the current statement ended.

B<returns>:
The line number, as an integer.

=item C<subroutine>

The fully qualified name of the subroutine that was called in this stack frame.
There are a couple of special values:

=over 4

=item *

The last part of the fully qualified name is C<__ANON__> when the sub never had a name, i.e. is an anonymous subroutine.

=item *

The whole name is C<(eval)> when this frame was generated from the C<eval> builtin, rather than from an ordinary function call. Instead of matching against this name, one can use the C<is_eval> accessor below,

=item *

The whole name is C<(unknown)> when a subroutine was named, but the typeglob where the subroutine was stored was deleted. I have never encountered this behaviour.

=back

B<return>:
The fully qualified name of the called subroutine, as a string.

=item C<has_args>

Checks whether the function call set up a new instance of C<@_>.
It does not check whether any arguments where passed at all.

In which cases is C<has_args> false?

=over 4

=item *

The stack frame was generated for an C<eval>, rather than for a function call.

=item *

The function call re-used the existing C<@_>, which happens when calling a function like C<&func> rather than C<&func()> or C<func()>. This is a fairly obscure feature, but is sometimes encountered when doing an explicit tail call such as C<goto &func>.

=back

If args were passed, an array ref to a copy of C<@_> is returned.
This means that arguments loose their referential identity.
This uses the C<@DB::args> mechanism (see the L<caller|perlfunc/caller> docs for more details), which means these values may not be up to date.

B<returns>:
A false value if no new C<@_> instance was created in this stack frame.
Otherwise, a true value is returned, which is an arrayref containing the arguments with which the subroutine was called.

=item C<wantarray>

The context in which that function was called.
See L<the C<wantarray> documentation|perlfunc/wantarray> for more details.

The values are true for list context, false but defined for scalar context, and undefined for void context.

B<return>:
an indicator for that stack frame's context.

=item C<is_eval>

Checks whether this stack frame was generated by an C<eval> construct.
If so, this returns another accessor object with two attributes.

B<returns>:
a false value if this frame was generated by an ordinary subroutine call.
If it was created by an C<eval>, then it returns an accessor object (which is also a true-ish value).

The fields of the accessor object are:

=over 4

=item C<source>

If that stack frame was generated by a string-eval and not a block-eval, then this field contains the source code that was eval'd.

B<returns>:
C<undef> or the source of the C<eval>, if available.

=item C<is_require>

Indicates whether this C<eval> is actually a C<use> or C<require>.

B<returns>:
a boolean value.

=back

=item C<is_require>

Indicates whether this C<eval> is actually a C<use> or C<require>.

B<returns>:
a boolean value.

=item C<hints>

The C<$^H> under which the caller was compiled.
This value is for perl's internal use only.

B<returns>:
The caller's C<$^H>.

=item C<bitmask>

The C<%{^WARNING_BITS}> under which the caller was compiled.
This value is for perl's internal use only.

B<returns>_
The caller's C<${^WARNING_BITS}>.

The C<%^H> hint hash under which the caller was compiled.
This hash offers storage for pragmas during compilation.
In the context of stack traces, this should be treated as a read-only value.

B<returns>:
The caller's C<%^H>, or C<undef> if it was empty.

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
