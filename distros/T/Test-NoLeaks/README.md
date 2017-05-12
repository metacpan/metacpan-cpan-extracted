# Test::NoLeaks

![Build status](https://api.travis-ci.org/binary-com/perl-Test-NoLeaks.png "Build status")
[![codecov](https://codecov.io/gh/binary-com/perl-Test-NoLeaks/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Test-NoLeaks)

# NAME

Test::NoLeaks - Memory and file descriptor leak detector

# VERSION

0.05

# SYNOPSYS

    use Test::NoLeaks;

    test_noleaks (
        code          => sub{
          # code that might leak
        },
        track_memory  => 1,
        track_fds     => 1,
        passes        => 2,
        warmup_passes => 1,
        tolerate_hits => 0,
    );

    Sample output:
    # pass 1, leaked: 225280 bytes 0 file descriptors
    # pass 36, leaked: 135168 bytes 0 file descriptors
    # pass 52, leaked: 319488 bytes 0 file descriptors
    # pass 84, leaked: 135168 bytes 0 file descriptors
    # pass 98, leaked: 155648 bytes 0 file descriptors
    not ok 1214 - Leaked 970752 bytes (5 hits) 0 file descriptors

    test_noleaks (
        code          => sub { ... },
        track_memory  => 1,
        passes        => 2,
    );

    # old-school way
    use Test::More;
    use Test::NoLeaks qw/noleaks/;
    ok noleaks(
        code          => sub { ... },
        track_memory  => ...,
        track_fds     => ...,
        passes        => ...,
        warmup_passes => ...,
      ), "non-leaked code description";

# DESCRIPTION

It is hard to track memory leaks. There are a lot of perl modules (e.g.
[Test::LeakTrace](https://metacpan.org/pod/Test::LeakTrace)), that try to **detect** and **point** leaks. Unfortunately,
they do not always work, and they are rather limited because they are not
able to detect leaks in XS-code or external libraries.

Instead of examining perl internals, this module offers a bit naive empirical
approach: let the suspicious code to be launched in infinite loop
some time and watch (via tools like `top`)if the memory consumption by
perl process increses over time. If it does, while it is expected to
be constant (stabilized), then, surely, there are leaks.

This approach is able only to **detect** and not able to **point** them. The
module `Test::NoLeaks` implements the general idea of the approach, which
might be enough in many cases.

# INTERFACE

### `test_noleaks`

### `noleaks`

The mandatory hash has the following members

- `code`

    Suspicious for leaks subroutine, that will be executed multiple times.

- `track_memory`
- `track_fds`

    Track memory or file descriptor leaks. At leas one of them should be
    specified.

    In **Unices**, every socket is file descriptor too, so, `track_fds`
    will be able to track unclosed sockets, i.e. network connections.

- `passes`

    How many times `code` should be executed. If memory leak is too small,
    number of passes should be large enough to trigger additional pages
    allocation for perl process, and the leak will be detected.

    Page size is 4kb on linux, so, if `code` leaks 4 bytes on every
    pass, then `1024` passes should be specified.

    In general, the more passes are specified, the more chance to
    detect possible leaks.

    It is good idea to initally define `passes` to some large number,
    e.g. `10_000` to be sure, that the suspicious code leaks, but then
    decrease to some smaller number, enough to produce test fail report,
    i.e. enough to produces 3-5 memory hits (additional pages allocations).
    This will speed up tests execution and will save CO2 atmospheric
    emissions a little bit.

    Default value is `100`. Minimal value is `2`.

- `warmup_passes`

    How many times the `code` should be executed before module starts
    tracking resources consumption on executing the `code` `passes`
    times.

    If you have caches, memoizes etc., then `warmup_passes` is your
    friend.

    Default value is `0`.

- `tolerate_hits`

    How many passes, which considered leaked, should be ingnored, i.e.
    maximal number of possible false leak reports.

    Even if your code has no leaks, it might cause perl interpreter
    allocate additional memory pages, e.g. due to memory fragmentation.
    Those allocations are legal, and should not be treated as leaks.

    Use this **only** when memory leaks are already fixed, but there
    are still false leak reports from `test_leak`. This value expected
    to be small enough, i.e. `1` or `2`. For additional assurance, please,
    increase `passes` value, if `tolarate_hits` is non-zero.

    Default value is `0`.

# MEMORY LEAKS TESTING TECHNIQUES

`Test::NoLeaks` can be used to test web applications for memory leaks.

Let's consider you have the following suspicious code

    sub might_leak {
      my $t = Test::Mojo->new('MyApp');
      $t->post_ok('/search.json' => form => {q => 'Perl'})
          ->status_is(200);
      ...;
    }

    test_noleaks (
        code          => \&might_leak,
        track_memory  => 1,
        track_fds     => 1,
        passes        => 1000,
    );

The `might_leak` subroutine isn't optimal for leak detection, because it
mixes infrastructure-related code (application) with request code. Let's
consider, that there is a leak: every request creates some data and puts
it into application, but forgets to do clean up. As soon as the application
is re-created on every pass, the leaked data might be destroyed together
with the application, and leak might remain undetected.

So, the code under test should look much more production like, i.e.

    my $t = Test::Mojo->new('MyApp');
    ok($t);
    sub might_leak {
      $t->post_ok('/search.json' => form => {q => 'Perl'})
          ->status_is(200);
      ...;
    }

That way web-application is created only once, and leaks will be tracked
on request-related code.

Anyway, `might_leak` still wrong, because it unintentionally leaks due to
use of direct or indirect [Test::More](https://metacpan.org/pod/Test::More) functions, like `ok` or
`post_ok`. They should not be used; if you still need to assert, that
`might_leak` works propertly, you can use `BAIL_OUT` subroutine,
to cancel any further testing, e.g.

    sub might_leak {
      my $got = some_function_might_leak;
      my $expected = "some_value";
      BAIL_OUT('some_function_might_leak does not work propertly!')
        unless $got eq $expected;
    }

Please, **do not** use `test_noleaks` more then once per test file. Consider
the following example:

    # (A)
    test_noleaks(
      code => &does_not_leak_but_consumes_large_amount_of_memory,
      ...,
    )

    # (B)
    test_noleaks(
      code => &leaks_but_consumes_small_amount_of_memory,
      ...
    )

In A-case OS already allocated large amount of memory for Perl interpreter.
In case-B perl might just re-use them, without allocating new ones, and
this will be false negative, i.e. memory leak might **not** be reported.

# LIMITATIONS

- Currently it works propertly only on **Linux**

    Patches or pull requests to support other OSes are welcome.

- The module will not work propertly in **fork**ed child

    It seems a little bit strange to use `test_noleaks` or
    `noleaks` in forked child, but if you really need that, please,
    send PR.

# SEE ALSO

[Test::MemoryGrowth](https://metacpan.org/pod/Test::MemoryGrowth)

# SOURCE CODE

[GitHub](https://github.com/binary-com/perl-Test-NoLeaks)

# AUTHOR

binary.com, `<perl at binary.com>`

# BUGS

Please report any bugs or feature requests to
[https://github.com/binary-com/perl-Test-NoLeaks/issues](https://github.com/binary-com/perl-Test-NoLeaks/issues).

# LICENSE AND COPYRIGHT

Copyright (C) 2015, 2016 binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
