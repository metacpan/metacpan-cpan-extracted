# NAME

Test::Mockingbird - Advanced mocking library for Perl with support for dependency injection and spies

# VERSION

Version 0.03

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
Supports two forms:

    mock('My::Module', 'method', sub { ... });

or the shorthand:

    mock 'My::Module::method' => sub { ... };

## unmock($package, $method)

Restores the original method for a mocked method.
Supports two forms:

    unmock('My::Module', 'method');

or the shorthand:

    unmock 'My::Module::method';

## mock\_scoped

Creates a scoped mock that is automatically restored when it goes out of scope.

This behaves like `mock`, but instead of requiring an explicit call to
`unmock` or `restore_all`, the mock is reverted automatically when the
returned guard object is destroyed.

This is useful when you want a mock to apply only within a lexical block:

    {
        my $g = mock_scoped 'My::Module::method' => sub { 'mocked' };
        My::Module::method();   # returns 'mocked'
    }

    My::Module::method();       # original behaviour restored

Supports both the longhand and shorthand forms:

    my $g = mock_scoped('My::Module', 'method', sub { ... });

    my $g = mock_scoped 'My::Module::method' => sub { ... };

Returns a guard object whose destruction triggers automatic unmocking.

## spy($package, $method)

Wraps a method so that all calls and arguments are recorded.
Supports two forms:

    spy('My::Module', 'method');

or the shorthand:

    spy 'My::Module::method';

Returns a coderef which, when invoked, returns the list of captured calls.
The original method is preserved and still executed.

## inject($package, $dependency, $mock\_object)

Injects a mock dependency. Supports two forms:

    inject('My::Module', 'Dependency', $mock_object);

or the shorthand:

    inject 'My::Module::Dependency' => $mock_object;

The injected dependency can be restored with `restore_all` or `unmock`.

## restore\_all()

Restores mocked methods and injected dependencies.

Called with no arguments, it restores everything:

    restore_all();

You may also restore only a specific package:

    restore_all 'My::Module';

This restores all mocked methods whose fully qualified names begin with
`My::Module::`.

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-test-mockingbird at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mockingbird](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mockingbird).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Test::Mockingbird
