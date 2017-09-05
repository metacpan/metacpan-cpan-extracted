# NAME

lazy - Lazily install missing Perl modules

# VERSION

version 0.000001

# SYNOPSIS

    # Auto-install missing modules into local/.  Note local::lib needs to
    # precede lazy in this scenario in order for the script to compile on the
    # first run.
    perl -Mlocal::lib=local -Mlazy foo.pl

    # Auto-install missing modules globally
    perl -Mlocal::lib -Mlazy=--global foo.pl

    # Auto-install missing modules into local/
    use local::lib 'local';
    use lazy;

    # Auto-install missing modules globally
    use lazy qw( --global );

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

    use lazy qw( --global --verbose );

You get the idea.

This module uses [App::cpm](https://metacpan.org/pod/App::cpm)'s defaults, so by default modules will be
installed to a folder called `local` in your current working directory.  This
folder will be created on demand.

So, the default usage would be:

    use local::lib 'local';
    use lazy;

If you want the module available generally, use the `--global` switch.

    use lazy qw( --global );

## CAVEATS

Be sure to remove `lazy` before you put your work into production.

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
