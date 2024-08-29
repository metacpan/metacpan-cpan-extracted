# NAME

lazy - Lazily install missing Perl modules

# VERSION

version 1.000000

# SYNOPSIS

    # At the command line
    # --------------------------------------------------

    # Auto-install missing modules globally
    perl -Mlazy foo.pl

    # Auto-install missing modules into ./local
    perl -Mlazy='-Llocal' foo.pl

    # Auto-install missing modules into ./some-other-dir
    perl -Mlazy='-Lsome-other-dir' foo.pl

    # In your code
    # --------------------------------------------------

    # Auto-install missing modules globally
    use lazy;

    # Auto-install missing modules into ./local
    use local::lib;
    use lazy qw( -L local );

    # Auto-install missing modules into ./some-other-dir
    use local::lib qw( some-other-dir );
    use lazy qw( -L some-other-dir );

    # Auto-install missing modules into ./some-other-dir and pass more options to App::cpm
    use local::lib qw( some-other-dir );
    use lazy qw( -L some-other-dir --man-pages --verbose --no-color );

    # In a one-liner?
    # --------------------------------------------------

    # Install App::perlimports via a one-liner, but why would you want to?
    perl -Mlazy -MApp::perlimports -E 'say "ok"'

## DESCRIPTION

Your co-worker sends you a one-off script to use.  You fire it up and realize
you haven't got all of the dependencies installed in your work environment.
Now you fire up the script and one by one, you find the missing modules and
install them manually.

Not anymore!

`lazy` will try to install any missing modules automatically, making your day
just a little less long.  `lazy` uses [App::cpm](https://metacpan.org/pod/App%3A%3Acpm) to perform this magic in the
background.

## USAGE

    perl -Mlazy foo.pl

Or use a local lib:

    perl -Mlazy='-Llocal' foo.pl

You can pass arguments directly to [App::cpm](https://metacpan.org/pod/App%3A%3Acpm) via the import statement.

    use lazy qw( --verbose );

Or

    use lazy qw( --man-pages --with-recommends --verbose );

You get the idea.

This module uses [App::cpm](https://metacpan.org/pod/App%3A%3Acpm)'s defaults, with the exception being that we
default to global installs rather than local.

So, the default usage would be:

    use lazy;

If you want to install to a local lib, use [local::lib](https://metacpan.org/pod/local%3A%3Alib) first:

    use local::lib qw( my-local-lib );
    use lazy    q( -L my-local-lib );

## CAVEATS

\* Remove `lazy` before you put your work into production.

## SEE ALSO

[Acme::Intraweb](https://metacpan.org/pod/Acme%3A%3AIntraweb), [Acme::Magic::Pony](https://metacpan.org/pod/Acme%3A%3AMagic%3A%3APony), [CPAN::AutoINC](https://metacpan.org/pod/CPAN%3A%3AAutoINC), [lib::xi](https://metacpan.org/pod/lib%3A%3Axi), [Module::AutoINC](https://metacpan.org/pod/Module%3A%3AAutoINC), [Module::AutoLoad](https://metacpan.org/pod/Module%3A%3AAutoLoad), [The::Net](https://metacpan.org/pod/The%3A%3ANet) and [Class::Autouse](https://metacpan.org/pod/Class%3A%3AAutouse)

## ACKNOWLEDGEMENTS

This entire idea was ripped off from [Acme::Magic::Pony](https://metacpan.org/pod/Acme%3A%3AMagic%3A%3APony).  The main difference
is that we use [App::cpm](https://metacpan.org/pod/App%3A%3Acpm) rather than [CPAN::Shell](https://metacpan.org/pod/CPAN%3A%3AShell).

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
