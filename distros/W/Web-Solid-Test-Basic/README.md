# NAME

Web::Solid::Test::Basic - Basic Solid Tests

# SYNOPSIS

```perl
use Test::FITesque::RDF;
my $suite = Test::FITesque::RDF->new(source => $file, base_uri => $ENV{SOLID_REMOTE_BASE})->suite;
$suite->run_tests;
done_testing;
```

See `tests/basic.t` for a full example.

# DESCRIPTION

## Introduction

The basic idea with these tests is to simplify reuse and formulation
of fixture tables using the Resource Description Framework (RDF). It
is in a very early stage, but there are running tests in this module.

This system is built on [Test::FITesque::RDF](https://metacpan.org/pod/Test::FITesque::RDF), which adds RDF fixture
tables to [Test::FITesque](https://metacpan.org/pod/Test::FITesque).

Then, the idea is that modules such as this will provide a reusable
implementation of certain tests, and that they can be adapted to
concrete test scenarios by either passing parameters from the RDF
tables (for both input variables and expected outcomes), or using
environment variables.

To run the actual tests, test scripts will be made, but they should be
terse as their only mission is to initialize the test framework, see
the synopsis for an example of such a script. The script can then be
invoked by e.g. CI systems or used in development.

The RDF fixture tables and the small wrapper scripts can exist
independently of the module, and modules can be installed easily so
that they can be reused. Nevertheless, it is also natural to package
these together, like it has been done in this package.

Each module like this one will need to document the tests it
implements, consider the below an example of how this should be done.

# IMPLEMENTED TESTS

## Test scripts

This package provides `tests/basic.t` which runs tests over the
fixture table in `tests/data/basic.ttl`. The test script requires the
environment variable `SOLID_REMOTE_BASE` to be set to the base URL
that any relative URLs in the fixture tables will be resolved
against. Thus, the fixture tables themselves are independent of the
host that will run them.

To run the test script in the clone of this package, invoke it like this:

```
SOLID_REMOTE_BASE="https://kjetiltest4.dev.inrupt.net/" prove -l tests/basic.t
```

## `http_read_unauthenticated`

Some basic tests for HTTP reads.

### Parameters

- `url`

    The URL to request.

### Environment

None

### Implements

- 1. That an HTTP HEAD request to the given URL succeeds.
- 2. That an HTTP GET request to the given URL succeeds.
- 3. That the HEAD and GET requests had the same header fields.
- 4. That the values of the header fields are the same.

## `http_write_with_bearer`

Test for successful HTTP PUT authenticated with a Bearer token

### Parameters

- `url`

    The URL to request.

### Environment

Set `SOLID_BEARER_TOKEN` to the bearer token to be used in the authorization header.

### Implements

- 1. That an HTTP PUT request to the given URL with a short Turtle payload succeeds.

# NOTE

The parameters above are in the RDF formulated as actual full URIs,
but where the local part is used here and resolved by the
[Test::FITesque::RDF](https://metacpan.org/pod/Test::FITesque::RDF) framework, see its documentation for details.

# TODO

The namespaces used in the current fixture tables are examples, and
will be changed before an 1.0 release of the system.

# BUGS

Please report any bugs to
[https://github.com/kjetilk/p5-web-solid-test-basic/issues](https://github.com/kjetilk/p5-web-solid-test-basic/issues).

# SEE ALSO

# AUTHOR

Kjetil Kjernsmo <kjetilk@cpan.org>.

# COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

```
The MIT (X11) License
```

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
