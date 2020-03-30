# NAME

ore

# ABSTRACT

Sugar for Perl 5 one-liners

# SYNOPSIS

    BEGIN {
      $ENV{New_File_Temp} = 'ft';
    }

    use ore;

    $ft

    # "File::Temp"

# DESCRIPTION

This package provides automatic package handling and object instantiation based
on environment variables. This is not a toy, but it's also not a joke. This
package exists because I was bored, shut-in due to the COVID-19 epidemic of
2020, and inspired by [new](https://metacpan.org/pod/new) and the ravings of a madman (mst). Though you
could use this package in a script it's meant to be used from the command-line.

## new-example

Simple command-line example using env vars to drive object instantiation:

    $ New_File_Temp=ft perl -More -e 'dd $ft'

    # "File::Temp"

## use-example

Another simple command-line example using env vars to return a
[Data::Object::Space](https://metacpan.org/pod/Data::Object::Space) object which calls `children` and returns an arrayref
of [Data::Object::Space](https://metacpan.org/pod/Data::Object::Space) objects:

    $ Use_DBI=dbi perl -More -e 'dd $dbi->children'

    # [
    #   ...,
    #   "DBI/DBD",
    #   "DBI/Profile",
    #   "DBI/ProfileData",
    #   "DBI/ProfileDumper",
    #   ...,
    # ]

## arg-example

Here's another simple command-line example using args as env vars with ordered
variable interpolation:

    $ perl -More -E 'dd $pt' New_File_Temp=ft New_Path_Tiny='pt; $ft'

    # /var/folders/pc/v4xb_.../T/JtYaKLTTSo

## etc-example

Here's a command-line example using the aforementioned sugar with the
ever-awesome [Reply](https://metacpan.org/pod/Reply) repl:

    $ New_Path_Tiny='pt; /tmp' reply -More

    0> $pt

    # $res[0] = bless(['/tmp', '/tmp'], 'Path::Tiny')

Or, go even further and hack together your own environment vars driven
[Dotenv](https://metacpan.org/pod/Dotenv), [Reply](https://metacpan.org/pod/Reply), and `perl -More` based REPL:

    #!/usr/bin/env perl

    use Dotenv -load => "$0.env";

    use ore;

    my $reply = `which reply`;

    chomp $reply;

    require $reply;

Then, provided you've the set appropriate env vars in `reply.env`, you could
use your custom REPL at the command-line as per usual:

    $ ./reply

    0> $pt

    # $res[0] = bless(['/tmp', '/tmp'], 'Path::Tiny')

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/ore/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/ore/wiki)

[Project](https://github.com/iamalnewkirk/ore)

[Initiatives](https://github.com/iamalnewkirk/ore/projects)

[Milestones](https://github.com/iamalnewkirk/ore/milestones)

[Contributing](https://github.com/iamalnewkirk/ore/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/ore/issues)
