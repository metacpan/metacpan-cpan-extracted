[![Actions Status](https://github.com/kfly8/Type-Equal/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kfly8/Type-Equal/actions?workflow=test) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Type-Equal/main.svg?style=flat)](https://coveralls.io/r/kfly8/Type-Equal?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Types-Equal.svg)](https://metacpan.org/release/Types-Equal)
# NAME

Types::Equal - type constraints for single value equality

# SYNOPSIS

```perl
use Types::Equal qw( Eq Equ );
use Types::Standard -types;
use Type::Utils qw( match_on_type );

# Check single string equality
my $Foo = Eq['foo'];
$Foo->check('foo'); # true
$Foo->check('bar'); # false

eval { Eq[undef]; };
ok $@; # dies


# Check single string equality with undefined
my $Bar = Equ['bar'];
$Bar->check('bar'); # true

my $Undef = Equ[undef];
$Undef->check(undef);


# Can combine with other types
my $Baz = Eq['baz'];
my $ListBaz = ArrayRef[$Baz];
my $Type = $ListBaz | $Baz;

$Type->check(['baz']); # true
$Type->check('baz'); # true

# Easily use pattern matching
my $Publish = Eq['publish'];
my $Draft = Eq['draft'];

my $post = {
    status => 'publish',
    title => 'Hello World',
};

match_on_type($post->{status},
    $Publish => sub { "Publish!" },
    $Draft => sub { "Draft..." },
) # => Publish!;


# Create simple Algebraic Data Types(ADT)
my $LoginUser = Dict[
    _type => Eq['LoginUser'],
    id => Int,
    name => Str,
];

my $Guest = Dict[
    _type => Eq['Guest'],
    name => Str,
];

my $User = $LoginUser | $Guest;

my $user = { _type => 'Guest', name => 'ken' };
$User->assert_valid($user);

match_on_type($user,
    $LoginUser => sub { "You are LoginUser!" },
    $Guest => sub { "You are Guest!" },
) # => 'You are Guest!';
```

# DESCRIPTION

Types::Equal provides type constraints for single string equality like TypeScript's string literal types.

## Eq

`Eq` is function of a type constraint [Type::Tiny::Eq](https://metacpan.org/pod/Type%3A%3ATiny%3A%3AEq) which is for single string equality.

## Equ

`Equ` is function of a type constraint [Type::Tiny::Equ](https://metacpan.org/pod/Type%3A%3ATiny%3A%3AEqu) which is for single string equality with undefined.

## NumEq

`NumEq` is function of a type constraint [Type::Tiny::NumEq](https://metacpan.org/pod/Type%3A%3ATiny%3A%3ANumEq) which is for single number equality.

## NumEqu

`NumEqu` is function of a type constraint [Type::Tiny::NumEqu](https://metacpan.org/pod/Type%3A%3ATiny%3A%3ANumEqu) which is for single number equality with undefined.

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kfly@cpan.org>
