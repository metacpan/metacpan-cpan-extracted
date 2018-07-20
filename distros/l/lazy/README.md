# NAME

lazy - Lazily install missing Perl modules

# VERSION

version 0.000006

# SYNOPSIS

    # Auto-install missing modules globally
    perl -Mlazy foo.pl

    # Auto-install missing modules into local_foo/.  Note local::lib needs to
    # precede lazy in this scenario in order for the script to compile on the
    # first run.
    perl -Mlocal::lib=local_foo -Mlazy foo.pl

    # Auto-install missing modules into local/
    use local::lib 'local';
    use lazy;

    # Auto-install missing modules globally
    use lazy;

    # Same as above, but explicity auto-install missing modules globally
    use lazy qw( -g );

    # Use a local::lib and get verbose, uncolored output
    perl -Mlocal::lib=foo -Mlazy=-v,--no-color

## DESCRIPTION

Your co-worker sends you a one-off script to use.  You fire it up and realize
you haven't got all of the dependencies installed in your work environment.
Now you fire up the script and one by one, you find the missing modules and
install them manually.

Not anymore!

`lazy` will try to install any missing modules automatically, making your day
just a little less long.  `lazy` uses [App::cpm](https://metacpan.org/pod/App::cpm) to perform this magic in the
background.

## USAGE

You can pass arguments directly to [App::cpm](https://metacpan.org/pod/App::cpm) via the import statement.

    use lazy qw( --verbose );

Or

    use lazy qw( --man-pages --with-recommends --verbose );

You get the idea.

This module uses [App::cpm](https://metacpan.org/pod/App::cpm)'s defaults, with the exception being that we
default to global installs rather than local.

So, the default usage would be:

    use lazy;

If you want to use a local lib:

    use local::lib qw( my_local_lib );
    use lazy;

Lazy will automatically pick up on your chosen local::lib and install there.
Just make sure that you `use local::lib` before you `use lazy`.

## CAVEATS

\* If not installing globally, `use local::lib` before you `use lazy`

\* Don't pass the `-L` or `--local-lib-contained` args directly to `lazy`.  Use [local::lib](https://metacpan.org/pod/local::lib) directly to get the best (and least confusing) results.

\* Remove `lazy` before you put your work into production.

## SEE ALSO

[Acme::Magic::Pony](https://metacpan.org/pod/Acme::Magic::Pony), [lib::xi](https://metacpan.org/pod/lib::xi), [CPAN::AutoINC](https://metacpan.org/pod/CPAN::AutoINC), [Module::AutoINC](https://metacpan.org/pod/Module::AutoINC)

## ACKNOWLEDGEMENTS

This entire idea was ripped off from [Acme::Magic::Pony](https://metacpan.org/pod/Acme::Magic::Pony).  The main difference
is that we use [App::cpm](https://metacpan.org/pod/App::cpm) rather than [CPAN::Shell](https://metacpan.org/pod/CPAN::Shell).

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
