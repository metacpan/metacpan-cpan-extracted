# NAME

Test::Mock::Simple - A simple way to mock out parts of or a whole module.

# SYNOPSIS

```perl5
    use Test::Mock::Simple;

    my $total = 0;

    # Original::Module has methods increase, decrease, and sum
    my $mock = Test::Mock::Simple->new(module => 'Original::Module');
    $mock->add(increase => sub { shift; return $total += shift; });
    $mock->add(decrease => sub { shift; return $total -= shift; });

    my $obj = Original::Module->new();
    $obj->increase(5);
    $obj->decrease(2);
    print $obj->sum . "\n"; # prints 3
```

# DESCRIPTION

This is a simple way of overriding any number of methods for a given object/class.

Can be used directly in test (or any) files, but best practice (IMHO) is to
create a 'Mock' module and using it instead of directly using the module in any
tests. The goal is to write a test which passes whether Mocking is being used or
not. See TEST\_MOCK\_SIMPLE\_DISABLE below.

The default behavior is to not allow adding methods that do not exist.  This
should stop mistyped method names when attempting to mock existing methods.
See allow\_new\_methods below to change this behavior.

Why another Mock module?  I needed something simple with no bells or whistles
that only overrode certain methods of a given module. It's more work, but there
aren't any conflicts.

This module can not do anything about BEGIN, END, or other special name code
blocks.  To changes these see B's (The Perl Compiler Backend) begin\_av, end\_av,
etc. methods.

### Environmental Variables

- TEST\_MOCK\_SIMPLE\_DISABLE

    If set to true (preferably 1) then 'add' is disabled.

### Methods

- new

    Create a new mock simple object.

    - module

        The name of the module that is being mocked.  The module will be loaded
        immediately (by requiring it).

        NOTE: since require is being used to load the module it's import method is not
        being called.  This may change in later versions.

    - module\_location

        module\_location expects a PATHNAME to the file (relative to the @INC paths) which
        contains the namespace (or module) that you want to mock.

        This is useful when a single file declares multiple namespaces or in the event of bad
        coding where the module's namespace does not map to the module's location.

        Example:

        ```perl5
        use Test::Mock::Simple;

        my $mock = Test::Mock::Simple->new(
          module          => 'Original::Module',
          module_location => 'Modules/Orignal/Module.pm',
        );
        ```

    - allow\_new\_methods

        To create methods that do not exist in the module that is being mocked.

        The default behavior is to not allow adding methods that do not exist.  This
        should stop mistyping method names when attempting to mock existing methods.

    - no\_load

        Default behavior is to load the real module before overriding individual methods.

        If this is not desired set no\_load to 1 which will stop this from happening.

        If set then you are required to mock the whole module (or at least every command
        required for code to work).

        Setting no\_load to 1 will force allow\_new\_methods to 1 as well. This is done since
        without the module actually loaded there is no way of knowing what methods the
        module has.

- add

    This allows for the creation of a new method (subroutine) that will override the
    existing one. Think of it as 'add'ing a mocked method to override the existing
    one.

# AUTHOR

Erik Tank, <tank@jundy.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2020 by Erik Tank

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
