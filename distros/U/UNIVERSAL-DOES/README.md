# NAME

UNIVERSAL::DOES - Provides UNIVERSAL::DOES() method for older perls

# VERSION

This document describes UNIVERSAL::DOES version 0.005.

# SYNOPSIS

	# if you require UNIVERSAL::DOES, you can say the following:
	require UNIVERSAL::DOES
		 unless defined &UNIVERSAL::DOES;

	# you can call DOES() in any perls
	$class->DOES($role);
	$object->DOES($role);

	# also, this provides a does() function
	use UNIVERSAL::DOES qw(does);

	# use does($thing, $role), instead of UNIVERSAL::isa($thing, $role)
	does($thing, $role);   # $thing can be non-invocant
	does($thing, 'ARRAY'); # also ok, $think may have overloaded @{}

# DESCRIPTION

`UNIVERSAL::DOES` provides a `UNIVERSAL::DOES()` method for
compatibility with perl 5.10.x.

This module also provides a `does()` function that checks something
does some roles, suggested in [perltodo](https://metacpan.org/pod/perltodo).

# FUNCTIONS

- `does($thing, $role)`

    `does` checks if _$thing_ performs the role _$role_. If the thing
    is an object or class, it simply checks `$thing->DOES($role)`. Otherwise
    it tells whether the thing can be dereferenced as an array/hash/etc.

    Unlike `UNIVERSAL::isa()`, it is semantically correct to use `does` for
    something unknown and to use it for `reftype`.

    This function handles overloading. For example, `does($thing, 'ARRAY')`
    returns true if the thing is an array reference, or if the thing is an object
    with overloaded `@{}`.

    This is not exported by default.

# METHODS

The following description is just copied from [UNIVERSAL](https://metacpan.org/pod/UNIVERSAL) in perl 5.10.1.

- `$obj->DOES( $ROLE )`
- `CLASS->DOES( $ROLE )`

    `DOES` checks if the object or class performs the role `ROLE`.  A role is a
    named group of specific behavior (often methods of particular names and
    signatures), similar to a class, but not necessarily a complete class by
    itself.  For example, logging or serialization may be roles.

    `DOES` and `isa` are similar, in that if either is true, you know that the
    object or class on which you call the method can perform specific behavior.
    However, `DOES` is different from `isa` in that it does not care _how_ the
    invocant performs the operations, merely that it does.  (`isa` of course
    mandates an inheritance relationship.  Other relationships include aggregation,
    delegation, and mocking.)

    By default, classes in Perl only perform the `UNIVERSAL` role, as well as the
    role of all classes in their inheritance.  In other words, by default `DOES`
    responds identically to `isa`.

    There is a relationship between roles and classes, as each class implies the
    existence of a role of the same name.  There is also a relationship between
    inheritance and roles, in that a subclass that inherits from an ancestor class
    implicitly performs any roles its parent performs.  Thus you can use `DOES` in
    place of `isa` safely, as it will return true in all places where `isa` will
    return true (provided that any overridden `DOES` _and_ `isa` methods behave
    appropriately).

# NOTES

- ["UNIVERSAL::DOES()" in perl5100delta](https://metacpan.org/pod/perl5100delta#UNIVERSAL::DOES) says:

    The `UNIVERSAL` class has a new method, `DOES()`. It has been added to
    solve semantic problems with the `isa()` method. `isa()` checks for
    inheritance, while `DOES()` has been designed to be overridden when
    module authors use other types of relations between classes (in addition
    to inheritance).

- ["A does() built-in" in perltodo](https://metacpan.org/pod/perltodo#A-does-built-in) says:

    Like ref(), only useful. It would call the `DOES` method on objects; it
    would also tell whether something can be dereferenced as an
    array/hash/etc., or used as a regexp, etc.
    [http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2007-03/msg00481.html](http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2007-03/msg00481.html)

# DEPENDENCIES

Perl 5.5.3 or later.

# BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

# AUTHOR

Goro Fuji (gfx) <gfuji(at)cpan.org>

# SEE ALSO

[UNIVERSAL](https://metacpan.org/pod/UNIVERSAL).

# LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
