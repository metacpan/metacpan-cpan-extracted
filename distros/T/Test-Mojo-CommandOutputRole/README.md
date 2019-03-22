Test::Mojo::CommandOutputRole
=============================

A role to extend [Test::Mojo][tm] to make [mojo command][mc] output tests easy.

[![Travis CI tests][travis-badge]][travis-report]

[tm]: https://mojolicious.org/perldoc/Test/Mojo
[mc]: https://mojolicious.org/perldoc/Mojolicious/Command
[travis-badge]: https://travis-ci.org/memowe/Test-Mojo-CommandOutputRole.svg?branch=master
[travis-report]: https://travis-ci.org/memowe/Test-Mojo-CommandOutputRole

Example
-------

```perl
my $t = Test::Mojo->new->with_roles('Test::Mojo::CommandOutputRole');

# Normal web tests
$t->get_ok('/')->content_is('Hello world');

# Test for string equality
$t->command_output(do_something => [qw(arg1 arg2)] => 'Expected output',
    'Correct do_something output');

# Test for regex matching
$t->command_output(do_something => [qw(arg1 arg2)] =>
    qr/^ \s* Expected\ answer\ is\ [3-5][1-3] \.? $/x,
    'Matching do_something output');

# Complex test
$t->command_output(do_something => [] => sub ($output) {
    ok defined($output), 'Output is defined';
    is length($output) => 42, 'Correct length';
}, 'Output test results OK');
```

**Test results**:

    ok 1 - GET /
    ok 2 - exact match for content
    # Subtest: Correct test_command output
        ok 1 - Command didn't die
        ok 2 - Correct output string
        1..2
    ok 3 - Correct test_command output
    # Subtest: Matching test_command output
        ok 1 - Command didn't die
        ok 2 - Output regex
        1..2
    ok 4 - Matching test_command output
    # Subtest: Output test results OK
        ok 1 - Command didn't die
        # Subtest: Handle command output
            ok 1 - Output is defined
            ok 2 - Correct length
            1..2
        ok 2 - Handle command output
        1..2
    ok 5 - Output test results OK

Dependencies
------------

- [perl][] 5.20
- [Mojolicious][mojo] 8.06
- [Capture::Tiny][cati] 0.48

[perl]: https://www.perl.org/get.html
[mojo]: https://metacpan.org/pod/Mojolicious
[cati]: https://metacpan.org/pod/Capture::Tiny

License and copyright
---------------------

Copyright (c) 2019 [Mirko Westermeier][mirko] ([\@memowe][mgh], [mirko@westermeier.de][mmail])

Released under the MIT (X11) license. See [LICENSE.txt][mit] for details.

[mirko]: http://mirko.westermeier.de
[mgh]: https://github.com/memowe
[mmail]: mailto:mirko@westermeier.de
[mit]: LICENSE.txt

Contributors
------------

- Renee Bäcker ([\@reneeb][reneeb])

[reneeb]: https://github.com/reneeb
