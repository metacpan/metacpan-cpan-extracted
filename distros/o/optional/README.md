# NAME

optional - Pragma to optionally load a module (or pick from a list of modules)
and provide a constant and some tools for taking action depending on if it
loaded or not.

# DESCRIPTION

Helps write code that has optional dependencies. Will load (or not load) the
module, then provide you with some tools that help you write logic that depends
on the result.

If a module fails to load for any reason other than its absence then the
exception will be rethrown to show the error.

# SYNOPSIS

    # Will try to load Optional::Module::Foo, naming tools with the 'opt_foo' name
    use optional opt_foo => qw/Optional::Module::Foo/;

    # Will try to load Optional::Module::Bar first, but will fallback to
    # Optional::Module::Foo if the first is not installed.
    use optional opt_any => qw/Optional::Module::Bar Optional::Module::Foo/;

    # You get a constant (capitlized version of name) that you can use in conditionals
    if (OPT_FOO) { ... }

    # The constant will return the module name that was loaded, if any, undef
    # if it was not loaded.
    if (my $mod = OPT_FOO) { ... }

    # Quickly write code that will only execute if the module was loaded
    # If the module was not loaded this always returns undef, so it is safe to
    # use in a hash building list.
    my $result = if_opt_foo { ... };

    # Quickly write code that will only execute if the module was NOT loaded If
    # the module was loaded this always returns undef, so it is safe to use in
    # a hash building list.
    my $result = unless_opt_foo { ... };

    sub feature_that_requires_foo {
        need_opt_foo();                                       # Throws an error telling the user they need to install Optional::Module::Foo to use this feature
        need_opt_foo(feature => 'widget');                    # Same, but names the feature
        need_opt_foo(trace   => 1);                           # Add a stack trace
        need_opt_foo(message => ...);                         # Write a custom message
        need_opt_foo(message => ..., append_modules => 1);    # Write a custom message, and add the module/s that need to be installed
    }

# EXPORTS

For each use of this module you will get 4 subs exported into your namespace, all contain the NAME intially provided.

- $module\_or\_undef = NAME()

    All caps version of the name. It is a constant, it always returns either the
    used modules name, or undef if the optional module is not installed.

- $res = if\_NAME { ... }

    Run a block if the module was installed and loaded. Returns undef if the module
    was not loaded, otherwise it returns what your sub returns.

- $res = unless\_NAME { ... }

    Run a block if the module was NOT installed and loaded. Returns undef if the module
    was loaded, otherwise it returns what your sub returns.

- need\_NAME()
- need\_NAME(message => $MSG, trace => $BOOL, append\_modules => $BOOL, feature => $FEATURE\_NAME)

    No-op if the module was loaded.

    If the module was not loaded it will throw an exception like this:

        "You must install one of the following modules to use this feature [Module::A]\n"
        "You must install one of the following modules to use this feature [Preferred::Module, Backup::Module]\n"

    You can also specify a feature name for a message like:

        "You must install one of the following modules to use the 'My Feature' feature [Module::A]\n"

    You can also add a custom message, and optionally append the module names by
    setting `append_modules` to true.

    In all forms you can set `trace` to true to use confess for a stack trace.

# SOURCE

The source code repository for 'optional' can be found at
[https://github.com/exodist/optional/](https://github.com/exodist/optional/).

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/)
