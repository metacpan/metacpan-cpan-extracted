[![Build Status](https://travis-ci.org/karupanerura/Test-SharedObject.svg?branch=master)](https://travis-ci.org/karupanerura/Test-SharedObject) [![Coverage Status](https://img.shields.io/coveralls/karupanerura/Test-SharedObject/master.svg)](https://coveralls.io/r/karupanerura/Test-SharedObject?branch=master)
# NAME

Test::SharedObject - Data sharing in multi process.

# SYNOPSIS

    use strict;
    use warnings;

    use Test::More tests => 2;
    use Test::SharedFork;
    use Test::SharedObject;

    my $shared = Test::SharedObject->new(0);
    is $shared->get, 0;

    my $pid = fork;
    die $! unless defined $pid;
    if ($pid == 0) {# child
        $shared->txn(sub {
            my $counter = shift;
            $counter++;
            return $counter;
        });
        exit;
    }
    wait;

    is $shared->get, 1;

# DESCRIPTION

Test::SharedObject provides atomic data operation between multiple process.

# METHODS

- my $shared = Test::SharedObject->new($value)

    Creates a new Test::SharedObject instance.
    And set `$value` as initial value.

    Internally, Creates temporary file, and serialize `$value` by [Storable](https://metacpan.org/pod/Storable), and save.

- $shared->txn(\\&coderef)

    Provides atomic data operation between multiple process in `\&coderef`.
    Set shared value as first arguments in `\&coderef`, and return value as new shared value.

    Internally:

    - Lock temporary file.
    - Read shared value.
    - Executes `\&coderef`. (Set shared value as first arguments)
    - Write return value as shared value.
    - Unlock temporary file.

    Good Example:

        $shared->txn(sub {
            my $counter = shift;
            $counter++; # atomic!!
            return $counter;
        });

    Bad Example:

        my $counter;
        $shared->txn(sub {
            $counter = shift;
        });
        $counter++; # *NOT* atomic!!
        $shared->txn(sub {
            return $counter;
        });

- $shared->set($value)

    Set `$value` as shared value.
    The syntactic sugar for `$shared->txn()`.

- my $value = $shared->get()

    Get shared value.
    The syntactic sugar for `$shared->txn()`.

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
