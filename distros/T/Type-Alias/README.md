[![Actions Status](https://github.com/kfly8/Type-Alias/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Type-Alias/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Type-Alias/main.svg?style=flat)](https://coveralls.io/r/kfly8/Type-Alias?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Type-Alias.svg)](https://metacpan.org/release/Type-Alias)
# NAME

Type::Alias - type alias for type constraints

# SYNOPSIS

```perl
use Types::Standard -types;
use Type::Alias
    -alias => [qw(ID User Guest LoginUser UserList)],
    -fun => [qw(List)];

type ID => Str;

type LoginUser => {
    _type => 'LoginUser',
    id   => ID,
    name => Str,
    age  => Int,
};

type Guest => {
    _type => 'Guest',
    name => Str,
};

type User => LoginUser | Guest;

type List => sub {
    my ($R) = @_;
    $R ? ArrayRef[$R] : ArrayRef;
};

type UserList => List[User];

UserList->check([
    { _type => 'LoginUser', id => '1', name => 'foo', age => 20 },
    { _type => 'Guest', name => 'bar' },
]); # => OK

# Internally UserList is equivalent to the following type:
#
# ArrayRef[
#     Dict[
#         _type => Eq['LoginUser'],
#         age => Int,
#         id => Str,
#         name => Str
#     ] |
#     Dict[
#         _type => Eq['Guest'],
#         name => Str
#     ]
# ]
```

# DESCRIPTION

Type::Alias creates type aliases and type functions for existing type constraints such as Type::Tiny, Moose, Mouse. The aim of this module is to enhance the reusability of types and make it easier to express types.

## IMPORT OPTIONS

### -alias

`-alias` is an array reference that defines type aliases. The default is `[]`.

```perl
use Type::Alias -alias => [qw(ID User)];

type ID => Str;

type User => {
    id   => ID,
    name => Str,
    age  => Int,
};
```

### -fun

`-fun` is an array reference that defines type functions. The default is `[]`.

```perl
use Type::Alias -fun => [qw(List)];

type List => sub($R) {
   $R ? ArrayRef[$R] : ArrayRef;
};
```

### type

The `type` option is used to configure the type function that defines type aliases and type functions.

```perl
# Rename type function:
use Type::Alias type => { -as => 'mytype' };

mytype ID => Str; # declare type alias
```

## EXPORTED FUNCTIONS

### type($alias\_name, $type\_args)

`type` is a function that defines a type alias and a type function.
It recursively generates type constraints based on `$type_args`.

#### `$type_args` is a type constraint

Given a type constraint in `$type_args`, it returns the type constraint as is.
Type::Alias treats objects with `check` and `get_message` methods as type constraints.

```perl
type ID => Str;

ID->check('foo'); # OK
```

Internally `ID` is equivalent to the following type:

```perl
sub ID() { Str }
```

#### `$type_args` is an undefined value

Given a undefined value in `$type_args`, it returns the type constraint defined by Type::Tiny's Undef type.

```perl
type Foo => Undef;

Foo->check(undef); # OK
```

Internally `Foo` is equivalent to the following type:

```perl
sub Foo() { Undef }
```

#### `$type_args` is a string value

Given a string value in `$type_args`, it returns the type constraint defined by [Types::Equal::Eq](https://metacpan.org/pod/Types%3A%3AEqual%3A%3AEq) type.

```perl
type ID => 'foo';

ID->check('foo'); # OK

type Published => 'published';
type Draft => 'draft';
type Status => Published | Draft;

Status->check('published'); # ok
Status->check('draft'); # ok
```

Internally `Status` is equivalent to the following type:

```perl
sub Status() { Eq['published'] | Eq['draft'] }
```

#### `$type_args` is a number value

**Available at v5.36 above. Less than v5.36, converts to Eq.**

Given a number value in `$type_args`, it returns the type constraint defined by [Types::Equal::NumEq](https://metacpan.org/pod/Types%3A%3AEqual%3A%3ANumEq) type.

```perl
type Foo => 123;
# Foo is NumEq[123]; v5.36 above
# Foo is Eq[123]; # less than v5.36
```

#### `$type_args` is a boolean value

**Available at v5.36 above. Less than v5.36, converts to Eq.**

Given a boolean value in `$type_args`, it returns the type constraint defined by Type::Tiny's Bool type.

```perl
type Foo => !!1;
# Foo is Type::Alias::True; v5.36 above
# Foo is Eq[!!1]; # less than v5.36
```

#### `$type_args` is a hash reference

Given a hash reference in `$type_args`, it returns the type constraint defined by Type::Tiny's Dict type.

```perl
type Point => {
    x => Int,
    y => Int,
};

Point->check({
    x => 1,
    y => 2
}); # OK
```

Internally `Point` is equivalent to the following type:

```perl
sub Point() { Dict[x=>Int,y=>Int] }
```

#### `$type_args` is an array reference

Given an array reference in `$type_args`, it returns the type constraint defined by Type::Tiny's Tuple type.

```perl
type Option => [Str, Int];

Option->check('foo', 1); # OK
```

Internally `Option` is equivalent to the following type:

```perl
sub Option() { Tuple[Str,Int] }
```

#### `$type_args` is a code reference

Given a code reference in `$type_args`, it defines a type function that accepts a type constraint as an argument and returns the type constraint.

```perl
type List => sub($R) {
   $R ? ArrayRef[$R] : ArrayRef;
};

type Points => List[{ x => Int, y => Int }];

Points->check([
    { x => 1, y => 2 },
    { x => 3, y => 4 },
]); # OK
```

Internally `List` is equivalent to the following type:

```perl
sub List :prototype(;$) {
   my @args = map { Type::Alias::to_type($_) } @{$_[0]};

    sub($R) {
       $R ? ArrayRef[$R] : ArrayRef;
    }->(@args);
}
```

And `Points` is equivalent to the following type:

```perl
sub Points() { List[Dict[x=>Int,y=>Int]] }
```

# COOKBOOK

## Exporter

Type::Alias is designed to be used with Exporter. The following is an example of using Type::Alias with Exporter.

```perl
package MyService {

    use Exporter 'import';
    our @EXPORT_OK = qw(hello Message);

    use Type::Alias -alias => [qw(Message)];
    use Types::Common -types;

    type Message => StrLength[1, 100];

    sub hello { ... }
}

package MyApp {

    use MyService qw(Message);
    Message->check('World!');
}
```

## Class builders

Type::Alias is designed to be used with class builders such as [Moose](https://metacpan.org/pod/Moose), [Moo](https://metacpan.org/pod/Moo) and [Mouse](https://metacpan.org/pod/Mouse).

```perl
package Sample {
    use Moose;

    use Exporter 'import';
    our @EXPORT_OK = qw( UserName );

    use Type::Alias -alias => [qw( UserName )];
    use Types::Standard qw( Str );

    type UserName => Str & sub { length $_ > 1 };

    has 'name' => (is => 'rw', isa => UserName);
}

package MyApp {

    use Sample qw( UserName );

    my $sample = Sample->new(name => 'hello');
    $sample->hello; # => 'hello'
    $sample->hello(''); # ERROR!

    UserName->check('hello'); # OK
}
```

## Validation modules

Type::Alias is designed to be used with validation modules such as [Type::Params](https://metacpan.org/pod/Type%3A%3AParams), [Smart::Args::TypeTiny](https://metacpan.org/pod/Smart%3A%3AArgs%3A%3ATypeTiny) and [Data::Validator](https://metacpan.org/pod/Data%3A%3AValidator):

```perl
use Type::Alias -alias => [qw( Message )];
use Types::Standard qw( Str );
use Type::Params -sigs;

type Message => Str & sub { length($_) > 1 };

signature_for hello => (
    positional => [ Message ],
);

sub hello {
    my ($message) = @_;
    return "HELLO " . $message;
}

hello('World') # => 'HELLO World';
hello('') # => Error!
```

### NOTE

[Function::Parameters](https://metacpan.org/pod/Function%3A%3AParameters) works using type aliases from outside.

```perl
package Sample {

    use Exporter 'import';
    our @EXPORT_OK = qw(User);

    use Type::Alias -alias => [qw(User)];
    use Types::Standard -types;

    type User => {
        name => Str,
    };
}

use Types::Standard -types;
use Function::Parameters;

use Sample qw(User);

fun hello (User $user) {
    return "Hello, $user->{name}!";
}

hello({ name => 'foo' }) # => 'Hello, foo!';
```

However, if you write a type alias inline as follows, the current implementation will not work.

```perl
use Type::Alias -alias => [qw(Gorilla)];

type Gorilla => Dict[ name => Str ];

fun ooh(Gorilla $user) { # => ERROR: type Gorilla is not defined at compile time
    return "ooh ooh, $user->{name}!";
}

ooh({ name => 'gorilla' }) # => 'ooh ooh, gorilla!';
```

# SEE ALSO

[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny)

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kfly@cpan.org>
