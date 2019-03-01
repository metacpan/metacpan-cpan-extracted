# NAME

Test::Starch - Test core features of starch.

# SYNOPSIS

    use Test2::V0;
    use Test::Starch;
    
    my $tester = Test::Starch->new(
        plugins => [ ... ],
        store => ...,
        ...,
    );
    $tester->test();
    
    done_testing;

# DESCRIPTION

This class runs the core [Starch](https://metacpan.org/pod/Starch) test suite by testing public
interfaces of [Starch::Manager](https://metacpan.org/pod/Starch::Manager), [Starch::State](https://metacpan.org/pod/Starch::State), and
[Starch::Store](https://metacpan.org/pod/Starch::Store).  These are the same tests that Starch runs
when you install it from CPAN.

This module is used by stores and plugins to ensure that they have
not broken any of the core features of Starch.  All store and plugin
authors are highly encouraged to run these tests as part of their
test suite.

Along the same lines, it is recommended that if you use Starch that
you make a test in your in-house test-suite which runs these tests
against your configuration.

This class takes all the same arguments as [Starch](https://metacpan.org/pod/Starch) and saves them
to be used when ["new\_manager"](#new_manager) is called by the tests.  Unlike [Starch](https://metacpan.org/pod/Starch),
if the `store` argument is not passed it will defailt to a Memory store.

# METHODS

## new\_manager

Creates a new [Starch::Manager](https://metacpan.org/pod/Starch::Manager) object and returns it.  Any arguments
you specify to this method will override those specified when creating
the [Test::Starch](https://metacpan.org/pod/Test::Starch) object.

## test

Calls ["test\_manager"](#test_manager), ["test\_state"](#test_state), and ["test\_store"](#test_store).

## test\_manager

Tests [Starch::Manager](https://metacpan.org/pod/Starch::Manager).

## test\_state

Test [Starch::State](https://metacpan.org/pod/Starch::State).

## test\_store

Tests the [Starch::Store](https://metacpan.org/pod/Starch::Store).

# SUPPORT

Please submit bugs and feature requests to the
Test-Starch GitHub issue tracker:

[https://github.com/bluefeet/Test-Starch/issues](https://github.com/bluefeet/Test-Starch/issues)

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
