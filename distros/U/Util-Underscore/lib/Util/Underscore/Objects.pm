package Util::Underscore::Objects;

#ABSTRACT: Functions for introspecting and manipulating objects and classes

use strict;
use warnings;


## no critic (ProhibitMultiplePackages)
package    # hide from PAUSE
    _;

## no critic (RequireArgUnpacking, RequireFinalReturn, ProhibitSubroutinePrototypes)

sub blessed(_) {
    goto &Scalar::Util::blessed;
}

{
    no warnings 'once';    ## no critic (ProhibitNoWarnings)
    *class = \&blessed;
}

sub is_object(_) {
    defined blessed $_[0];
}

sub class_isa($$) {
    is_package($_[0])
        && $_[0]->isa($_[1]);
}

sub class_does($$) {
    is_package($_[0])
        && $_[0]->DOES($_[1]);
}

sub class_can($$) {
    is_package($_[0])
        && $_[0]->can($_[1]);
}

sub isa($$) {
    blessed $_[0]
        && $_[0]->isa($_[1]);
}

sub does($$) {
    blessed $_[0]
        && $_[0]->DOES($_[1]);
}

{
    no warnings 'once';    ## no critic (ProhibitNoWarnings)
    *is_instance = \&does;
}

sub can($$) {
    blessed $_[0]
        && $_[0]->can($_[1]);
}

sub safecall($$@) {
    my $self = shift;
    my $meth = shift;
    return if not blessed $self;
    $self->$meth(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Util::Underscore::Objects - Functions for introspecting and manipulating objects and classes

=head1 VERSION

version v1.4.1

=head1 FUNCTION REFERENCE

=over 4

=item C<$str = _::blessed $obj>

=item C<$str = _::blessed>

=item C<$str = _::class $obj>

=item C<$str = _::class>

Accesses the class of the provided object.

Wrapper for C<Scalar::Util::blessed>.

B<$obj>:
the object of which the class is to be determined.
If omitted, uses C<$_>.

B<returns>:
The class of C<$obj> if that is a blessed scalar, else returns C<undef>.

=item C<$bool = _::is_object $scalar>

=item C<$bool = _::is_object>

Checks that the argument is a blessed object.
It's just an abbreviation for C<defined _::blessed $scalar>.

B<$scalar>:
the scalar which may or may not be a blessed object.

B<returns>:
a boolean indicating whether the C<$scalar> is a blessed object.

=item C<$bool = _::class_isa $class, $supertype>

Checks that the C<$class> inherits from the given C<$supertype>, both given as strings.
In most cases, one should use C<_::class_does> instead.

B<$class>:
the name of the class.

B<$supertype>:
the name of another class.

B<returns>:
a boolean indicating whether C<$class> inherits from C<$supertype>.

=item C<$bool = _::class_does $class, $role>

Checks that the C<$class> performs the given C<$role>, both given as strings.
This means that the C<$class> has a compatible interface to the C<$role>.
However, this does not require that the C<$class> inherits from the C<$role>.

B<$class>:
the name of the class.

B<$role>:
the name of a role.

B<returns>:
a boolean indicating whether C<$class> conforms to the C<$role>.

=item C<$bool = _::isa $object, $class>

Checks that the C<$object> inherits from the given class.
In most cases, one should use C<_::does> or C<_::is_instance> instead.

B<$object>:
a scalar possibly containing an object.

B<$class>:
the name of a class:

B<returns>:
a boolean indicating whether the C<$object> inherits from the given C<$class>.
Returns false if the C<$object> parameter isn't actually an object.

=item C<$code = _::can $object, $method>

Checks that the object can perform the given method.

    if (my $code = _::can $object, $method) {
        $object->$method(@args);
    }

B<$object>:
a scalar.

B<$method>:
the name of the method to search.

B<returns>:
if the C<$object> can perform the C<$method>, this returns a reference to that method.
A false value is returned in all other cases (the object doesn't know about that method, or the C<$object> argument doesn't actually hold an object).

=item C<$bool = _::is_instance $object, $role>

=item C<$bool = _::does $object, $role>

Checks that the given C<$object> can perform the C<$role>.

B<$object>:
a scalar possibly containing an object.

B<$role>:
the name of a role.

B<returns>:
a boolean value indicating whether the given C<$object> conforms to the C<$role>.

=item C<< any = $maybe_object->_::safecall(method => @args) >>

This will call the C<method> only if the C<$maybe_object> is a blessed object.
We do not check that the object C<can> perform the method, so this might still raise an exception.

Context is propagated correctly to the method call.
If the C<$maybe_object> is not an object, this will simply return.
In scalar context, this evaluates to C<undef>, in list context this is the empty list.

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
