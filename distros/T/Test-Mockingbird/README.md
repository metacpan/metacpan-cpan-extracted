# NAME

Test::Mockingbird - Advanced mocking library for Perl with support for dependency injection and spies.

# VERSION

Version 0.01

# SYNOPSIS

    use Test::Mockingbird;

    # Mocking
    Test::Mockingbird::mock('My::Module', 'method', sub { return 'mocked!' });

    # Spying
    my $spy = Test::Mockingbird::spy('My::Module', 'method');
    My::Module::method('arg1', 'arg2');
    my @calls = $spy->(); # Get captured calls

    # Dependency Injection
    Test::Mockingbird::inject('My::Module', 'Dependency', $mock_object);

    # Unmocking
    Test::Mockingbird::unmock('My::Module', 'method');

    # Restore everything
    Test::Mockingbird::restore_all();

# DESCRIPTION

Test::Mockingbird provides powerful mocking, spying, and dependency injection capabilities to streamline testing in Perl.

# METHODS

## mock($package, $method, $replacement)

Mocks a method in the specified package.

## unmock($package, $method)

Restores the original method for a mocked method.

## spy($package, $method)

Spies on a method, tracking calls and arguments.

## inject($package, $dependency, $mock\_object)

Injects a mock object for a dependency.

## restore\_all()

Restores all mocked methods and dependencies to their original state.
