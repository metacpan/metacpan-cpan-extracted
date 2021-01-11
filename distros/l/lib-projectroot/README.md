# NAME

lib::projectroot - easier loading of a project's local libs

# VERSION

version 1.008

# SYNOPSIS

    # your_project/bin/somewhere/deep/down/script.pl
    use strict;
    use warnings;
    # look up from the file's location until we find a directory
    # containing a directory named 'lib'. Add this dir to @INC
    use lib::projectroot qw(lib);

    # look up until we find a dir that contains both 'lib' and 'foo',
    # add both to @INC
    use lib::projectroot qw(lib foo);

    # look up until we find 'lib' and 'local'. Add 'lib' to @INC,
    # load 'local' via local::lib
    use lib::projectroot qw(lib local::lib=local);

    # based on the dir we found earlier, go up one dir and try to add
    # 'Your-OtherModule/lib' and 'Dark-PAN/lib' to @INC
    lib::projectroot->load_extra(Your-OtherModule Dark-PAN);

    # the same as above
    use lib::projectroot qw(lib local::lib=local extra=Your-OtherModule,Dark-PAN);

    # if you want to know where the project-root is:
    say $lib::projectroot::ROOT;  # /home/domm/jobs/Some-Project

    # also load local::libs installed in extras
    use lib::projectroot qw(lib local::lib=local extra_with_local=Your-OtherModule,Dark-PAN);

# DESCRIPTION

I'm usually using a setup like this:

    .
    ├── AProject
    │   ├── bin
    │   │   ├── db
    │   │   │   └── init.pl
    │   │   ├── onetime
    │   │   │   ├── fixup
    │   │   │   │   └── RT666_fix_up_fubared_data.pl
    │   │   │   └── import_data.pl
    │   │   └── web.psgi
    │   ├── lib
    │   └── local
    ├── MyHelperStuff
    │   └── lib
    └── CoolLib-NotYetOnCPAN
        └── lib

There is `AProject`, which is the actual code I'm working on. There
is also probably `BProject`, e.g. another microservice for the same
customer. `AProject` has its own code in `lib` and its CPAN
dependencies in `local` (managed via `Carton` and used via
`local::lib`). There are a bunch of scripts / "binaries" in `bin`,
in a lot of different directories of varying depth.

I have some generic helper code I use in several projects in
`MyHelperStuff/lib`. It will never go to CPAN. I have some other code
in `CoolLib-NotYetOnCPAN/lib` (but it might end up on CPAN if I ever
get to clean it up...)

`lib::projectroot` makes it easy to add all these paths to `@INC` so
I can use the code.

In each script, I just have to say:

    use lib::projectroot qw(lib local::lib=local);

`lib` is added to the beginning of <@INC>, and `local` is loaded via
`local::lib`, without me having to know how deep in `bin` the
current script is located.

I can also add

    lib::projectroot->load_extra(qw(MyHelperStuff CoolLib-NotYetOnCPAN));

to get my other code pushed to `@INC`. (Though currently I put this
line, and some other setup code like initialising `Log::Any` into
`AProject::Run`, and just `use AProject::Run;`)

You can also define extra dists directly while loading `lib::projectroot`:

    use lib::projectroot qw(
        lib
        local::lib=local
        extra=MyHelperStuff,CoolLib-NotYetOnCPAN
    );

If your extra dists themselves have deps which are installed into their `local::lib`, you can add those via `extra_with_local`:

    use lib::projectroot qw(
        lib
        local::lib=local
        extra=MyHelperStuff
        extra_with_local=CoolLib-NotYetOnCPAN
    );

You can access `$lib::projectroot::ROOT` if you need to know where the projectroot actually is located (e.g. to load some assets)

# TODOs

Some ideas for future releases:

- what happens if `$PERL5LIB` is already set?
- think about the security issues raised by Abraxxa (http://prepan.org/module/nY4oajhgzJN 2014-12-02 18:42:07)

# SEE ALSO

- [FindBin](https://metacpan.org/pod/FindBin) - find out where the current binary/script is located, but no `@INC` manipulation. In the Perl core since forever. Also used by `lib::projectroot`.
- [Find::Lib](https://metacpan.org/pod/Find%3A%3ALib) - combines `FindBin` and `lib`, but does not search for the actual location of `lib`, so you'll need to know where your scripts is located relative to `lib`.
- [FindBin::libs](https://metacpan.org/pod/FindBin%3A%3Alibs) - finds the next `lib` directory and uses it, but no [local::lib](https://metacpan.org/pod/local%3A%3Alib) support. But lots of other features
- [File::FindLib](https://metacpan.org/pod/File%3A%3AFindLib) - find and use a file or dir based on the script location. Again no [local::lib](https://metacpan.org/pod/local%3A%3Alib) support.
- and probably more...

# THANKS

Thanks to `eserte`, `Smylers` & Ca&lt;abraxxa> for providing feedback
at [http://prepan.org/module/nY4oajhgzJN|prepan.org](http://prepan.org/module/nY4oajhgzJN|prepan.org). Meta-thanks to
[http://twitter.com/kentaro|kentaro](http://twitter.com/kentaro|kentaro) for running prepan, a very handy
service!

Thanks to `koki`, `farhad` and `Jozef` for providing face-to-face
feedback.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
