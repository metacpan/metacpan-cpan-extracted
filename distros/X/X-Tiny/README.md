# NAME

X::Tiny - Base class for a bare-bones exception factory

# SYNOPSIS

    package My::Module::X;

    use parent qw( X::Tiny );

    #----------------------------------------------------------------------

    package My::Module::X::Base;

    use parent qw( X::Tiny::Base );

    #----------------------------------------------------------------------

    package My::Module::X::IO;

    use parent qw( My::Module::X::Base );

    #----------------------------------------------------------------------

    package My::Module::X::Blah;

    use parent qw( My::Module::X::Base );

    sub _new {
        my ($class, @args) = @_;

        my $self = $class->SUPER::_new('Blah blah', @args);

        return bless $self, $class;
    }

    #----------------------------------------------------------------------

    package main;

    local $@;   #always!
    eval {
        die My::Module::X->create('IO', 'The message', key1 => val1, … );
    };

    if ( my $err = $@ ) {
        print $err->get('key1');
    }

    die My::Module::X->create('Blah', key1 => val1, … );

# DESCRIPTION

This stripped-down exception framework provides a baseline
of functionality for distributions that want to expose exception
hierarchies with minimal fuss. It’s a pattern that I implemented in some
other distributions I created and didn’t want to copy/paste around.

# BENEFITS OF EXCEPTIONS

Exceptions are better for error reporting in Perl than the
C-style “return in failure” pattern. In brief,
you should use exceptions because they are a logical, natural way to report
failures: if you’re given a set of instructions, and something goes wrong
in one of those instructions, it makes sense to stop and go back to see what
to do in response to the problem.

Perl’s built-ins unwisely make the caller responsible for error checking—as
a result of which much Perl code fails to check for failures from those
built-ins, which makes for far more difficult debugging when some code down
the line just mysteriously produces an unexpected result.
The more sensible pattern is for an exception to be thrown at the spot where
the error occurred.

Perl’s default exceptions are just scalars. A more useful pattern is to throw
exception objects whose type and attributes can facilitate meaningful
error checking; for example, you may not care if a call to `unlink()` fails
with `ENOENT`, so you can just ignore that failure. Or, you might care, but
you might prefer just to `warn()` rather than to stop what you’re doing.

X::Tiny is one of many CPAN modules that facilitates this pattern. What
separates X::Tiny from other such modules is its light weight: the only
“heavy” dependency is [overload](https://metacpan.org/pod/overload), which is (in my experience) a reasonable
trade-off for the helpfulness of having stack traces on uncaught exceptions.
(The stack trace is custom logic, much lighter than [Carp](https://metacpan.org/pod/Carp).)

# FEATURES

- Super-lightweight: No exceptions are loaded until they’re needed.
- Simple, flexible API
- String overload with stack trace
- Minimal code necessary

# USAGE

You’ll first create a factory class that subclasses `X::Tiny`.
(In the SYNOPSIS’s example, this module is `My::Module::X`.) All of your
exceptions **must** exist under that factory class’s namespace.

You’ll then create a base exception class for your distribution.
In the SYNOPSIS’s example, this module is `My::Module::X::Base`.
Your distribution’s other exceptions should all subclass this one.

# METHODS

There’s only one method in the factory class:

## _CLASS_->create( TYPE, ARG1, ARG2, .. )

To create an exception, call the `create()` method of your factory class.
This will load the exception class if it’s not already in memory.
The TYPE you pass in is equivalent to the exception class’s module name but
with the factory class’s name chopped off the left part. So, if you call:

    My::Module::X->create('BadInput', 'foo', 'bar')

… this will instantiate and return an instance of `My::Module::X::BadInput`,
with the arguments `foo` and `bar`.

# EXCEPTION OBJECTS

See [X::Tiny::Base](https://metacpan.org/pod/X::Tiny::Base) for more information about the features that that
module exposes to subclasses.

# DESIGN CONSIDERATIONS

Admittedly, the lazy-loading behavior here embodies a generally-unwise
practice of doing failure-prone work (i.e., loading a module at runtime)
in the process of reporting a failure.
In my own experience, though, that’s a reasonable tradeoff for the
expressiveness of typed exceptions.

Do be sure that any failure-prone work you do as part of exception
instantiation has its own failure-checking mechanism. There really are not
meant to be “sub-failures” here!

# REPOSITORY

[https://github.com/FGasper/p5-X-Tiny](https://github.com/FGasper/p5-X-Tiny)

# AUTHOR

Felipe Gasper (FELIPE)

# COPYRIGHT

Copyright 2017-2019 by [Gasper Software Consulting](http://gaspersoftware.com)

# LICENSE

This distribution is released under the same license as Perl.
