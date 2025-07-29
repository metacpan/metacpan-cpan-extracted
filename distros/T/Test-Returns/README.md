# NAME

Test::Returns - Verify that a method's output agrees with its specification

# SYNOPSIS

    use Test::More;
    use Test::Returns;

    returns_ok(42, { type => 'integer' }, 'Returns valid integer');
    returns_ok([], { type => 'arrayref' }, 'Returns valid arrayref');
    returns_not_ok("bad", { type => 'arrayref' }, 'Fails (expected arrayref)');

# DESCRIPTION

Exports the function `returns_ok`, which asserts that a value satisfies a schema as defined in [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict).
Integrates with [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder) for use alongside [Test::Most](https://metacpan.org/pod/Test%3A%3AMost) and friends.

# METHODS

## returns\_is($value, $schema, $test\_name)

Passes if `$value` satisfies `$schema` using `Return::Set`.
Fails otherwise.

## returns\_isnt

Opposite of returns\_is

## returns\_ok($value, $schema, $test\_name)

Alias for `returns_is`.
Provided for naming symmetry and clarity.

## returns\_not\_ok

Synonym of returns\_isnt

# AUTHOR

Nigel Horne &lt;njh at nigelhorne.com>

# SEE ALSO

[Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder), [Returns::Set](https://metacpan.org/pod/Returns%3A%3ASet), [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)

# SUPPORT

This module is provided as-is without any warranty.

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
