# Perl - Test OpenTracing

Make integration testing easy, for all you care about are spans!


## SYNOPSIS

### Testing Traces

```perl
use Test::OpenTracing;

$ENV{OPENTRACING_IMPLEMENTATATION} = 'Test';

... # run your test-requests

cmp_deeply_global_tracer (
    [
        superhashof => {
            operation_name  => 'request',
            start_time      => 0.0,
            child_spans     => [
                superhash       => {
                    operation_name  => 'setup',
                    finish_time     => 0.1,
                },
                superhash       => {
                    operation_name  => 'run',
                    start_time      => 0.1,
                    child_spans     => ignore(),
                },
                
            ],
            duration        => 0.3,
        },
    ],
    "Looks like we did create all the expected spans on the right timing"
);

```

### Testing Interface Methods

```perl
use Test::OpenTracing;

opentracing_interface_ok_span_context( 'MyImplementation::SpanContext',
    "'MyImplementation' class implements required methods for 'SpanContext'";

```

### Testing Implementation Typechecks

```perl
use Test::OpenTracing;

opentracing_implementation_ok_span_context( 'MyImplementation::SpanContext',
    "'MyImplementation' class is strict on typechecks for 'SpanContext'";

```


## DESCRIPTION

Test::OpenTracing is an easy way to check your OpenTracing compliant framework
integrations and implementations.

The `cmp_deeply_global_tracer` is a `cmp_deeply` like test, that works on a
special tracer implementation: `OpenTracing::Implementation::Test`.

The `opentracing_interface_ok` test, basically run `can_ok` tests.

The `opentracing_implementation_ok` test run a series of test against each
(required) method, to see if they are fault tolerant or strict on accepting in
coming parameters and returned results.


## EXPORTED SUBROUTINES

### cmp_deeply_global_tracer

### opentracing_interface_ok

### opentracing_implementation_ok


## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This library is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
