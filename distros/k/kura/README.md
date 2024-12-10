[![Actions Status](https://github.com/kfly8/kura/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/kura/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/kura/main.svg?style=flat)](https://coveralls.io/r/kfly8/kura?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/kura.svg)](https://metacpan.org/release/kura)
# NAME

kura - Store constraints for Data::Checks, Type::Tiny, Moose, and more.

# SYNOPSIS

```perl
use Exporter 'import';

use Types::Common -types;
use Email::Valid;

use kura Name  => StrLength[1, 255];
use kura Email => sub { Email::Valid->address($_[0]) };
```

# DESCRIPTION

Kura - means "Traditional Japanese storehouse" - stores constraints, such as [Data::Checks](https://metacpan.org/pod/Data%3A%3AChecks), [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Moose::Meta::TypeConstraint](https://metacpan.org/pod/Moose%3A%3AMeta%3A%3ATypeConstraint), [Mouse::Meta::TypeConstraint](https://metacpan.org/pod/Mouse%3A%3AMeta%3A%3ATypeConstraint), [Specio](https://metacpan.org/pod/Specio), and more.
This module is useful for storing constraints in a package and exporting them to other packages. Following are the features of Kura:

- Simple Declaration
- Export Constraints
- Store Multiple Constraints

## FEATURES

### Simple Declaration

Kura makes it easy to store constraints in a package.

```perl
use kura NAME => CONSTRAINT;
```

`CONSTRAINT` must be a any object that has a `check` method or a code reference that returns true or false.
The following is an example of a constraint declaration:

```perl
use kura Name => StrLength[1, 255];
```

### Export Constraints

Kura allows you to export constraints to other packages using your favorite exporter such as [Exporter](https://metacpan.org/pod/Exporter), [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny), and more.

```perl
package MyPkg {
    use parent 'Exporter::Tiny';
    use Data::Checks qw(StrEq);

    use kura Foo => StrEq('foo');
}

use MyPkg qw(Foo);
Foo->check('foo'); # true
Foo->check('bar'); # false
```

### Store Multiple Constraints

Kura supports multiple constraints such as [Data::Checks](https://metacpan.org/pod/Data%3A%3AChecks), [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Moose::Meta::TypeConstraint](https://metacpan.org/pod/Moose%3A%3AMeta%3A%3ATypeConstraint), [Mouse::Meta::TypeConstraint](https://metacpan.org/pod/Mouse%3A%3AMeta%3A%3ATypeConstraint), [Specio](https://metacpan.org/pod/Specio), and more.

```
Data::Checks -----------------> +--------+
                                |        |
Type::Tiny -------------------> |        |
                                |  Kura  | ---> Named Value Constraints!
Moose::Meta::TypeConstraint --> |        |
                                |        |
YourFavoriteConstraint -------> +--------+
```

If your project uses multiple constraint libraries, kura allows you to simplify your codes and making it easier to manage different constraint systems. This is especially useful in large projects or when migrating from one constraint system to another.
Here is an example of using multiple constraints:

```perl
package MyFoo {
    use Exporter 'import';
    use Data::Checks qw(StrEq);
    use kura Foo => StrEq('foo');
}

package MyBar {
    use Exporter 'import';
    use Types::Standard -types;
    use kura Bar => Str & sub { $_[0] eq 'bar' };
}

package MyBaz {
    use Exporter 'import';
    use Moose::Util::TypeConstraints;
    use kura Baz => subtype as 'Str' => where { $_[0] eq 'baz' };
}

package MyQux {
    use Exporter 'import';
    use kura Qux => sub { $_[0] eq 'qux' };
}

use MyFoo qw(Foo);
use MyBar qw(Bar);
use MyBaz qw(Baz);
use MyQux qw(Qux); # CodeRef converted to Type::Tiny

ok  Foo->check('foo') && !Foo->check('bar') && !Foo->check('baz') && !Foo->check('qux');
ok !Bar->check('foo') &&  Bar->check('bar') && !Bar->check('baz') && !Bar->check('qux');
ok !Baz->check('foo') && !Baz->check('bar') &&  Baz->check('baz') && !Baz->check('qux');
ok !Qux->check('foo') && !Qux->check('bar') && !Qux->check('baz') &&  Qux->check('qux');
```

## WHY USE KURA

Kura serves a similar purpose to [Type::Library](https://metacpan.org/pod/Type%3A%3ALibrary) which is bundled with [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) but provides distinct advantages in specific use cases:

- Built-in Class Support

    While Type::Library tightly integrates with Type::Tiny, Kura works with built-in classes.

    ```perl
    class Fruit {
        use Exporter 'import';
        use Types::Common -types;

        # kura meets built-in class!
        use kura Name => StrLength[1, 255];

        field $name :param :reader;
    }
    ```

- Simpler Declaration

    Kura simplifies type constraint declarations. Unlike Type::Library, there's no need to write name twice.

    Kura:

    ```perl
    use Exporter 'import';
    use Types::Common -types;

    use kura Name => StrLength[1, 255];
    use kura Level => IntRange[1, 100];
    use kura Player => Dict[ name => Name, level => Level ];
    ```

    Type::Library:

    ```perl
    use Types::Library -declare => [qw(Name Level Player)]; # Need to write name twice
    use Types::Common -types;
    use Type::Utils -all;

    declare Name, as StrLength[1, 255];
    declare Level, as IntRange[1, 100];
    declare Player, as Dict[ name => Name, level => Level ];
    ```

- Minimal Exported Functions

    Kura avoids the extra `is_*`, `assert_*`, and `to_*` functions exported by Type::Library.
    This keeps your namespace cleaner and focuses on the essential `check` method.

- Multiple Constraints

    Kura is not limited to Type::Tiny. It supports multiple constraint libraries such as Moose, Mouse, Specio, and Data::Checks.
    This flexibility allows consistent management of type constraints in projects that mix different libraries.

While Type::Library is powerful and versatile, Kura stands out for its simplicity, flexibility, and ability to integrate with multiple constraint systems.
It’s particularly useful in projects where multiple type constraint libraries coexist or when leveraging built-in class syntax.

## NOTE

### Order of declaration

When declaring constraints, it is important to define child constraints before their parent constraints to avoid errors.
If constraints are declared in the wrong order, you might encounter errors like **Bareword not allowed**. Ensure that all dependencies are declared beforehand to prevent such issues.
For example:

```perl
# Bad order
use kura Parent => Dict[ name => Child ]; # => Bareword "Child" not allowed
use kura Child => Str;

# Good order
use kura Child => Str;
use kura Parent => Dict[ name => Child ];
```

### Need to load Exporter

If you forget to put `use Exporter 'import';`, you get an error like this:

```perl
package MyFoo {
    # use Exporter 'import'; # Forgot to load Exporter!!
    use Data::Checks qw(StrEq);
    use kura Foo => StrEq('foo');
}

use MyFoo qw(Foo);
# => ERROR!
Attempt to call undefined import method with arguments ("Foo" ...) via package "MyFoo"
(Perhaps you forgot to load the package?)
```

## `@EXPORT_OK` and `@KURA` are automatically set

Package variables `@EXPORT_OK` and `@KURA` are automatically set when you use `kura` in your package:

```perl
package MyFoo {
    use Exporter 'import';
    use Types::Common -types;
    use kura Foo1 => StrLength[1, 255];
    use kura Foo2 => StrLength[1, 1000];

    our @EXPORT_OK;
    push @EXPORT_OK, qw(hello);

    sub hello { 'Hello, Foo!' }
}

# Automatically set the caller package to MyFoo
MyFoo::EXPORT_OK # => ('Foo1', 'Foo2', 'hello')
MyFoo::KURA      # => ('Foo1', 'Foo2')
```

It is useful when you want to export constraints. For example, you can tag `@KURA` with `%EXPORT_TAGS`:

```perl
package MyBar {
    use Exporter 'import';
    use Types::Common -types;
    use kura Bar1 => StrLength[1, 255];
    use kura Bar2 => StrLength[1, 1000];

    our %EXPORT_TAGS = (
        types => \@MyBar::KURA,
    );
}

use MyBar qw(:types);
# => Bar1, Bar2 are exported
```

If you don't want to export constraints, put a prefix `_` to the constraint name:

```perl
use kura _PrivateFoo => Str;
# => "_PrivateFoo" is not exported
```

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
