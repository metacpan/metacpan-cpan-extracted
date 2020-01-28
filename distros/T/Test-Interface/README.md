# Perl - Test Interface

Test if a class implements an interface, using Role::Inspector

## SYNOPSIS

To create an Interface:

```perl
    package MyProject::Foo::Interface;
    
    use Role::MethodReturns;
    
    around my_foo_method => class_method ( Str, $foo, Int $bar ) {
        returns_object_does_interface( 'MyProject::Bar::Interface'(
            $original->( $class => ( $foo, $bar ) )
    }
```

And in some implementation:

```perl
    package MyProject::Foo
    
    sub my_foo_method { ... }
    
    ...
```

And in tests:

```perl
    use Test::Most;
    use Test::Interface;
    
    interface_ok('MyProject::Foo', 'MyProject::Foo::Interface',
        "huray! We implemented all methods!!"
    
    done_testing();
```

## LICENSE INFORMATION

This package is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
