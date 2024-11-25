[![Actions Status](https://github.com/kfly8/kura/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/kura/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/kura/main.svg?style=flat)](https://coveralls.io/r/kfly8/kura?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/kura.svg)](https://metacpan.org/release/kura)
# NAME

kura - Store constraints for Data::Checks, Type::Tiny, Moose, and more.

# SYNOPSIS

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

# DESCRIPTION

Kura - means "Traditional Japanese storehouse" - stores constraints, such as [Data::Checks](https://metacpan.org/pod/Data%3A%3AChecks), [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Moose::Meta::TypeConstraint](https://metacpan.org/pod/Moose%3A%3AMeta%3A%3ATypeConstraint), [Mouse::Meta::TypeConstraint](https://metacpan.org/pod/Mouse%3A%3AMeta%3A%3ATypeConstraint), [Specio](https://metacpan.org/pod/Specio), and more. It can even be used with [Moo](https://metacpan.org/pod/Moo) when combined with [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) constraints.

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

# HOW TO USE

## Declaring a constraint

It's easy to use to store constraints in a package:

```perl
use kura NAME => CONSTRAINT;
```

This constraint must be a any object that has a `check` method or a code reference that returns true or false.
The following is an example of a constraint declaration:

```perl
use Exporter 'import';
use Types::Standard -types;

use kura Name  => Str & sub { qr/^[A-Z][a-z]+$/ };
use kura Level => Int & sub { $_[0] >= 1 && $_[0] <= 100 };

use kura Character => Dict[
    name  => Name,
    level => Level,
];
```

When declaring constraints, it is important to define child constraints before their parent constraints to avoid errors. For example:

```perl
# Bad order
use kura Parent => Dict[ name => Child ]; # => Bareword "Child" not allowed
use kura Child => Str;

# Good order
use kura Child => Str;
use kura Parent => Dict[ name => Child ];
```

If constraints are declared in the wrong order, you might encounter errors like “Bareword not allowed.” Ensure that all dependencies are declared beforehand to prevent such issues.

## Export a constraint

You can export the declared constraints by your favorite Exporter package such as [Exporter](https://metacpan.org/pod/Exporter), [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny), and more.
Internally, Kura automatically adds the declared constraint to `@EXPORT_OK`, so you just put `use Exporter 'import';` in your package:

```perl
package MyFoo {
    use Exporter 'import';

    use Data::Checks qw(StrEq);
    use kura Foo => StrEq('foo');
}

use MyFoo qw(Foo);
Foo->check('foo'); # true
Foo->check('bar'); # false
```

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

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
