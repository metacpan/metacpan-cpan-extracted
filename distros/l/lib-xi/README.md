# NAME

lib::xi - Installs missing modules on demand

# VERSION

This document describes lib::xi version 1.03.

# SYNOPSIS

    # to install missing libaries automatically
    $ perl -Mlib::xi script.pl

    # with cpanm options
    $ perl -Mlib::xi=-q script.pl

    # to install missing libaries to extlib/ (with cpanm -l extlib)
    $ perl -Mlib::xi=extlib script.pl

    # with cpanm options
    $ perl -Mlib::xi=extlib,-q script.pl

    # with cpanm options via env
    $ PERL_CPANM_OPT='-l extlib -q' perl -Mlib::xi script.pl

# DESCRIPTION

When you execute a script found in, for example, `gist`, you'll be annoyed
at missing libraries and will install those libraries by hand with a CPAN
client. We have repeated such a task, which violates the great virtue of
Laziness. Stop doing it, making computers do it!

`lib::xi` is a pragma to install missing libraries automatically if and only
if they are required.

The mechanism, using `@INC hook`, is that when the perl interpreter cannot
find a library required, this pragma try to install it with `cpanm(1)` and
tell it to the interpreter.

# INTERFACE

## The import method

### `use lib::xi ?$install_dir, ?@cpanm_opts`

Setups the `lib::xi` hook into `@INC`.

If _$install\_dir_ is specified, it is used as the install directory as
`cpanm --local-lib $install_dir`, adding `$install_dir/lib/perl5` to `@INC`
Note that _$install\_dir_ will be expanded to the absolute path based on
where the script is. That is, in the point of `@INC`, `use lib::xi 'extlib'` is almost the same as the following code:

    use FindBin;
    use lib "$FindBin::Bin/extlib/lib/perl5";

_@cpanm\_opts_ are passed directly to `cpanm(1)`. Note that if the first argument starts with `-`, it is regarded as `@cpanm_opts`, so you can simply omit
the _$install\_dir_ if it's not needed.

# COMPARISON

There are similar modules to `lib::xi`, namely `CPAN::AutoINC` and
`Module::AutoINC`, which use `CPAN.pm` to install modules; the difference
is that `lib::xi` supports `local::lib` (via `cpanm -l`) and has little
overhead.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[cpanm](https://metacpan.org/pod/cpanm) (App::cpanminus)

["require" in perlfunc](https://metacpan.org/pod/perlfunc#require) for the `@INC` hook specification details

[CPAN::AutoINC](https://metacpan.org/pod/CPAN::AutoINC)

[Module::AutoINC](https://metacpan.org/pod/Module::AutoINC)

# AUTHOR

Fuji, Goro (gfx) <gfuji@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
