# NAME

Types::SQL - a library of SQL types

# VERSION

version v0.2.0

# SYNOPSIS

```perl
use Types::SQL -types;

my $type = Varchar[16];
```

# DESCRIPTION

This module provides a type library of SQL types.  These are
[Type::Tiny](https://metacpan.org/pod/Type::Tiny) objects that are augmented with a `dbic_column_info`
method that returns column information for use with
[DBIx::Class](https://metacpan.org/pod/DBIx::Class).

# TYPES

The following types are provided:

## `Blob`

```perl
my $type = Blob;
```

Returns a `blob` data type.

## `Text`

```perl
my $type = Text;
```

Returns a `text` data type.

## `Varchar`

```perl
my $type = Varchar[ $size ];
```

Returns a `varchar` data type, with an optional size parameter.

## `Char`

```perl
my $type = Char[ $size ];
```

Returns a `char` data type, with an optional size parameter.

## `Integer`

```perl
my $type = Integer[ $precision ];
```

Returns a `integer` data type, with an optional precision parameter.

## `Serial`

```perl
my $type = Serial[ $precision ];
```

Returns a `serial` data type, with an optional precision parameter.

## `Numeric`

```perl
my $type = Numeric[ $precision, $scale ];
```

Returns a `integer` data type, with optional precision and scale parameters.

If `$scale` is omitted, then it is assumed to be `0`.

# CUSTOM TYPES

Any type that has these types as a parent can have column information
extracted using [Types::SQL::Util](https://metacpan.org/pod/Types::SQL::Util).

Alternatively, you can specify a custom `dbic_column_info` method in
a type, e.g.:

```perl
my $type = Type::Tiny->new(
  name       => 'MyType',
  my_methods => {
    dbic_column_info => sub {
      my ($self) = @_;
      return (
         data_type    => 'custom',
         parameter    => 1234,
      );
    },
  },
  ...
);
```

The method should return a hash of values that are passed to the
`add_column` method of [DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx::Class::ResultSource).

# SEE ALSO

[Type::Tiny](https://metacpan.org/pod/Type::Tiny).

[Types::SQL::Util](https://metacpan.org/pod/Types::SQL::Util), which provides a utility function for translating
these types and other types from [Types::Standard](https://metacpan.org/pod/Types::Standard) into column
information for [DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx::Class::ResultSource).

# SOURCE

The development version is on github at [https://github.com/robrwo/Types-SQL](https://github.com/robrwo/Types-SQL)
and may be cloned from [git://github.com/robrwo/Types-SQL.git](git://github.com/robrwo/Types-SQL.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Types-SQL/issues](https://github.com/robrwo/Types-SQL/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
