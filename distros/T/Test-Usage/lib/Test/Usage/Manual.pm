=head1

=head1 DESCRIPTION

This module approaches testing differently from the standard Perl way.
Its first versions go back to 1998, when I was reading about what is
now called "Test Driven Development".

It was designed to make it easy to run only selected tests from a test
file that may contain many more. Also, by default, it only reports on
tests that fail, and keeps quiet about successes. It also by default
displays test results using color, in a "Green: passed; Red: failed"
manner.

I usually have a test file named *_T.pm for each ordinary *.pm file in
my projects. For example, the test file for Foo.pm would be named
Foo_T.pm. I place Foo_T.pm in the same directory as Foo.pm.  Foo_T.pm
has a conventional structure, like the one shown in the SYNOPSIS
section of Test/Usage.pm.  Basically, it just names the module, loads
Test::Usage and defines a bunch of examples.  Each example(),
identified by its label, adds to the tests that the module can run,
upon request.

The ok() function is a bit different from the one in Perl's standard
test modules. The standard ok() takes two arguments: a boolean and a
label. Test::Usage's ok() takes three: a boolean (which I prefer to
call a predicate), a "success" message, and a "failure" message. It is
most useful when those messages describe expected results and help
debug when a test fails.  One problem with this (which occurs rarely
in practice, but is annoying to work around) is that we might not
want to evaluate the failure message if the test succeeds; for
example, the failure message might refer to a variable that is defined
only if the test fails, leading to "Undefined variable..." warnings
when the test succeeds.

Still, compare the following examples:

=over 4

=item Useful

    ok(! defined($got = foo()),
        'foo() should return undef if no arguments are given.',
        "But returned '$got' instead."
    );

Whether it succeeds of fails, the following messages are informative:

    ok a1
        # foo() should return undef if no arguments are given.

    not ok a1
        # foo() should return undef if no arguments are given.
        # But returned '' instead.

=item Less useful

    ok(! defined(my $got = foo()),
        'Result is undefined.',
        'Didn\'t work.'
    );

Whether it succeeds of fails, we don't really know what exactly went
right, or wrong:

    ok a1
        # Result is undefined.

    not ok a1
        # Result is undefined.
        # Didn't work.

=back

The recommended approach leads to messages that are more verbose, but
I believe that makes them more useful for maintenance.

=head1 AUTHOR

Luc St-Louis, E<lt>lucs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Luc St-Louis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

