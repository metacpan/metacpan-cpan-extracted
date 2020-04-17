# Perl - Test OpenTracing Interface

Testing Implementations


## SYNOPSIS

### Testing Interface Methods

```perl
use Test::OpenTracing::Interface::SpanContext;

can_all_ok( 'MyImplementation::SpanContext',
    "'MyImplementation' class implements required methods for 'SpanContext'";

```

### Testing Implementation Typechecks

```perl
use Test::OpenTracing::Interface::SpanContext;

my $test_object = MyImplementation::SpanContext->new();

interface_lives_ok( $test_object,
    "'MyImplementation' class is strict on typechecks for 'SpanContext'";

```


## DESCRIPTION

Test::OpenTracing::Interface is an easy way to check your OpenTracing compliant
implementations.

The `can_all_ok` test, basically run `can_ok` tests.

The `lives_ok` and `dies_ok` test run a series of test against each
(required) method, to see if they are fault tolerant or strict on accepting in
coming parameters and returned results.



## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This library is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
