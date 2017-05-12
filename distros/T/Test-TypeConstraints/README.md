# NAME

Test::TypeConstraints - testing whether some value is valid as (Moose|Mouse)::Meta::TypeConstraint

# SYNOPSIS

    use Test::TypeConstraints qw(type_isa);

    type_isa($got, "ArrayRef[Int]", "type should be ArrayRef[Int]");

# DESCRIPTION

Test::TypeConstraints is for testing whether some value is valid as (Moose|Mouse)::Meta::TypeConstraint.

# METHODS

## type\_isa

    type_isa($value, $type);
    type_isa($value, $type, $test_name);
    type_isa($value, $type, $test_name, %options);

Performs a type check against the $value using the $type.

$type can be a class name, a Moose/Mouse type name,
Moose/Mouse::Meta::TypeConstraint object or
Moose/Mouse::Meta::TypeConstraint::Class object.

$test\_name is the description of the test.  If not given, one will be provided.

%options control optional behaviors.  Its keys can be the following...

### coerce

If true, coercion will be used when performing the type check.

If a code ref is given, it will be run and passed in the coerced value
for additional testing.

    type_isa $value, "Some::Class", "coerce to Some::Class", coerce => sub {
        isa_ok $_[0], "Some::Class";
        is $_[0]->value, $value;
    };

## type\_does

    type_does($value, $role);
    type_does($value, $role, $test_name);
    type_does($value, $role, $test_name, %options);

Tests that the $value does the $role.

Works like `type_isa`, but for roles instead of classes and types.
The $value must have consumed the given $role.

## type\_isnt

## type\_doesnt

The opposites of `type_isa` and `type_does`.  They take the same
arguments and options.

Checks that the value is _not_ of the given type or role.

# AUTHOR

Keiji Yoshimi <walf443 at gmail dot com>

# THANKS TO

- schwern
- gfx
- tokuhirom

# SEE ALSO

[Mouse::Util::TypeConstraints](http://search.cpan.org/perldoc?Mouse::Util::TypeConstraints), [Moose::Util::TypeConstraints](http://search.cpan.org/perldoc?Moose::Util::TypeConstraints)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
