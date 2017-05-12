[![Build Status](https://travis-ci.org/moznion/p5-Test-Fluent-Logger.svg?branch=master)](https://travis-ci.org/moznion/p5-Test-Fluent-Logger)
# NAME

Test::Fluent::Logger - A mock implementation of Fluent::Logger for testing

# SYNOPSIS

    use Test::More;
    use Test::Fluent::Logger; # Enable the function of this library just by using
                              # (Activate intercepting the fluentd log payload)

    use Fluent::Logger;

    my $logger = Fluent::Logger->new(
        host       => '127.0.0.1',
        port       => 24224,
        tag_prefix => 'prefix',
    );

    $logger->post("tag1", {foo => 'bar'}); # Don't post to fluentd, it puts the log content on internal stack
    $logger->post("tag2", {buz => 'qux'}); # ↑Either

    # Get internal stack (array)
    my @fluent_logs = get_fluent_logs;
    is_deeply \@fluent_logs, [
        {
            'tag_prefix' => 'prefix',
            'time' => '1485443191.94598',
            'message' => {
                'foo' => 'bar'
            }
        },
        {
            'tag_prefix' => 'prefix',
            'time' => '1485443191.94599',
            'message' => {
                'buz' => 'qux'
            }
        }
    ];

    # Clear internal stack (array)
    clear_fluent_logs;

    @fluent_logs = get_fluent_logs;
    is_deeply \@fluent_logs, [];

# DESCRIPTION

Test::Fluent::Logger is a mock implementation of Fluent::Logger for testing.

This library intercepts the log payload of fluentd and puts that on stack.
You can pickup log\[s\] from stack and it can be used to testing.

# FUNCTIONS

## `get_fluent_logs(): Array[HashRef]`

Get fluentd logs from stack as array.

Item of the array is hash reference. The hash reference is according to following format;

    {
        'tag_prefix' => 'prefix',
        'time' => '1485443191.94599', # <= timestamp
        'message' => {
            'buz' => 'qux'
        }
    }

## `clear_fluent_logs()`

Clear stack of fluentd logs.

## `activate()`

Activate intercepting the log payload.

## `deactivate()`

Deactivate intercepting the log payload.

# SEE ALSO

- [Fluent::Logger](https://metacpan.org/pod/Fluent::Logger)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
