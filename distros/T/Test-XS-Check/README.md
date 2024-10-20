# NAME

Test::XS::Check - Test that your XS files are problem-free with XS::Check

# VERSION

version 0.02

# SYNOPSIS

    use Test2::V0;
    use Test::XS::Check qw( xs_ok );

    xs_ok('path/to/File.xs');

    done_testing();

# DESCRIPTION

This module wraps Ben Bullock's [XS::Check](https://metacpan.org/pod/XS%3A%3ACheck) module in a test module that you
can incorporate into your distribution's test suite.

# EXPORTS

This module exports one subroutine on request.

## xs\_ok($path)

Given a path to an XS file, this subroutine will run that file through
[XS::Check](https://metacpan.org/pod/XS%3A%3ACheck). If any XS issues are found, the test fails and the problems are
emitted as diagnostics. If no issues are found, the test passes.

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Test-XS-Check/issues](https://github.com/houseabsolute/Test-XS-Check/issues).

# SOURCE

The source code repository for Test-XS-Check can be found at [https://github.com/houseabsolute/Test-XS-Check](https://github.com/houseabsolute/Test-XS-Check).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [https://houseabsolute.com/foss-donations/](https://houseabsolute.com/foss-donations/).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 - 2024 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
