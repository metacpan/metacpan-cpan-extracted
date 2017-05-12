# NAME

Test::SharedFork - fork test

# SYNOPSIS

    use Test::More tests => 200;
    use Test::SharedFork;

    my $pid = fork();
    if ($pid == 0) {
        # child
        ok 1, "child $_" for 1..100;
    } elsif ($pid) {
        # parent
        ok 1, "parent $_" for 1..100;
        waitpid($pid, 0);
    } else {
        die $!;
    }

# DESCRIPTION

Test::SharedFork is utility module for Test::Builder.

This module makes [fork(2)](http://man.he.net/man2/fork) safety in your test case.

This module merges test count with parent process & child process.

# LIMITATIONS

This version of the Test::SharedFork does not support ithreads, because [threads::shared](http://search.cpan.org/perldoc?threads::shared) conflicts with [Storable](http://search.cpan.org/perldoc?Storable).

# AUTHOR

Tokuhiro Matsuno <tokuhirom  slkjfd gmail.com>

yappo

# THANKS TO

kazuhooku

konbuizm

# SEE ALSO

[Test::TCP](http://search.cpan.org/perldoc?Test::TCP), [Test::Fork](http://search.cpan.org/perldoc?Test::Fork), [Test::MultipleFork](http://search.cpan.org/perldoc?Test::MultipleFork)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
