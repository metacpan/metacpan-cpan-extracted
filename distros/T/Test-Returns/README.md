## Name

Test::Returns - Verify that a method's output agrees with its specification

## Synopsis

```perl
use Test::More;
use Test::Returns;

returns_ok(42, { type => 'integer' }, 'Returns valid integer');
returns_ok([], { type => 'arrayref' }, 'Returns valid arrayref');
returns_not_ok("bad", { type => 'arrayref' }, 'Fails (expected arrayref)');
```

## Version

Version 0.05

## Description

Exports the function `returns_ok`, which asserts that a value satisfies a schema as defined in [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict).
Integrates with [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder) for use alongside [Test::Most](https://metacpan.org/pod/Test%3A%3AMost) and friends.

## Methods

### Returns\_Is($Value, $Schema, $Test\_Name)

Passes if `$value` satisfies `$schema` using `Return::Set`.
Fails otherwise.

`$schema` is passed directly to [Return::Set](https://metacpan.org/pod/Return%3A%3ASet) and on to [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict).
As a convenience, `type => 'array'` is accepted as a synonym for
`type => 'arrayref'`: because a bare Perl array cannot be stored as a hash
value, [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) only defines the `arrayref` type, but callers
may capture a list-returning function as an arrayref and validate it with
`type => 'array'`.

Schema keys prefixed with `_` (such as `_error_return` and `_error_handling`
as emitted by [App::Test::Generator](https://metacpan.org/pod/App%3A%3ATest%3A%3AGenerator)) are passed through unchanged;
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) ignores unknown keys in a rule hash.

### Returns\_Isnt($Value, $Schema, $Test\_Name)

Opposite of `returns_is`: passes if `$value` does **not** satisfy `$schema`.

Accepts `type => 'array'` as a synonym for `type => 'arrayref'`, for
the same reasons as `returns_is`.

### Returns\_Ok($Value, $Schema, $Test\_Name)

Alias for `returns_is`.
Provided for naming symmetry and clarity.

### Returns\_Not\_Ok

Synonym of returns\_isnt

## Author

Nigel Horne &lt;njh at nigelhorne.com>

## See Also

[Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder), [Return::Set](https://metacpan.org/pod/Return%3A%3ASet), [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)

## Support

This module is provided as-is without any warranty.

## Licence and Copyright

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
