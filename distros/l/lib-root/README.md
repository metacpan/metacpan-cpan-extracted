[![Actions Status](https://github.com/hernan604/lib-root/actions/workflows/test.yml/badge.svg)](https://github.com/hernan604/lib-root/actions)
# NAME

lib::root - find perl root and push lib modules path to @INC

# VERSION

version 0.10

# SYNOPSIS

lib::root looks for a .libroot file on parent directories and pushes ./\*/lib to @INC.

When a file does `use lib::root`, lib::root will try to read the file parent directories and look for a rootfile (default is .libroot) that is usually located inside a /some/dir/perl that contains many modules used by your app. Many apps have a /some/dir/perl/.perl-version file inside a perl directory, when that is the case, the app can piggy back on that filename and look for that file instead of .libroot with the example below:

    use lib::root rootfile => '.perl-version';

To use the defaults, create an empty file named .libroot and place it in your /app/dir/perl/.libroot

    use lib::root;

    ... or use another custom file to determine a libroot

    use lib::root; # rootfile defaults to .libroot
    use lib::root rootfile => '.perl-version';

    ... or add a callback if needed

    use lib::root callback => sub { ... };

    ... or look for a given file in approot and use a perl root dir to push to inc

    use lib::root rootfile => '.app-root', perldir => 'perl';

# WHY IS THIS USEFUL

lib::root can be useful when your application perl modules are not installed globally.

When your app uses lib::root, the lib::root will look for the .libroot file into parent directories relative to the file using it.

For example, your app has the following structure:

    /dir/myapp/perl/MyApp-Thing/lib/...
    /dir/myapp/perl/MyApp-Another/lib/...
    /dir/myapp/perl/MyApp-Stuff/lib/...
    /dir/myapp/perl/.perl-version
    /dir/myapp/bin/some_script.pl
    /dir/myapp/bin/another_script.pl
    /dir/myapp/.app-root

... and the app needs to push all those perl/\*/lib to @INC. There are some ways to do that

Add the directory to env PERLLIB

    PERLLIB=$PERLLIB:/dir/myapp/perl/MyApp-Thing/lib:/dir/myapp/perl/MyApp-Another/lib

Or use -I

    perl -I/dir/myapp/perl/MyApp-Thing/lib -I/dir/myapp/perl/MyApp-Another/lib

Or use a BEGIN block:

    BEGIN { push @INC, glob "/dir/myapp/perl/*/lib"; }

Or use lib::root:

    use lib::root rootfile => '.perl_is_here';

lib::root can also be instructed to look in a cousin dir relative to `bin` in the structure above

    use lib::root perldir => '../perl';

Or use lib

    use FindBin qw($Bin);
    use lib "$Bin/../lib";
    use lib "/home/user/MyApp/lib";

Or some other way ...

## USAGE

For a project with the following strucutre:

    /dir/myapp/perl/MyApp-Thing/lib/MyApp/Thing.pm
    /dir/myapp/perl/MyApp-Another/lib/MyApp/Another.pm
    /dir/myapp/perl/MyApp-Stuff/lib/MyApp/Stuff.pm
    /dir/myapp/perl/.libroot
    /dir/myapp/perl/.perl-version
    /dir/myapp/bin/some_script.pl
    /dir/myapp/bin/another_script.pl
    /dir/myapp/.app-root

### EXAMPLE 1 - DEFAULT USAGE

When using /dir/myapp/perl/MyApp-Thing/lib/MyApp/Thing.pm its possible to include perl/\*/lib to @INC by adding the following to Thing.pm

    use lib::root;

The above will detect the location of Thing.pm and go recursively to parent directories and look for the default `.libroot` file. Given that the .libroot file exists under /dir/myapp/perl/.libroot (/dir/myapp/perl/) , lib::root will do: push @INC, glob "/dir/myapp/perl/\*/lib";

### EXAMPLE 2 - CUSTOM lib::root FILE

Some plenv projects have a `.perl-version` file sitting under the perl dir ie. /perl/.perl-version (see structure above). If thats the case, lib::root can piggy back on the .perl-version file with:

    use lib::root rootfile => '.perl-version';

### EXAMPLE 3 - CALLING FROM SCRIPT OUTSIDE perl DIRECTORY

If the project has `bin` directories like the structure above, and the file /dir/myapp/bin/some\_script.pl needs to use lib::root, the file is outside the `perl` dir. It will use the `.app-root` file with a custom perl `perldir` to push libs to @INC, ie:

    use lib::root rootfile => '.app-root', perldir => 'perl';

The lib::root call insite the script in `bin` will look for a directory that contains `.app-root` and then it will use the child directory `perl` (the perldir option) to push the modules to @INC;

The same could be done to make the .pm files above also use the `.app-root` instead of the `.libroot`. Or, also, use `.libroot` with a custom `perldir`, ie:

    use lib::root perldir => 'perl';
    use lib::root perldir => 'dir1/dir2/dir3/perl';
    use lib::root perldir => '../perl';

### EXAMPLE 4 - CALLBACKS

If necessary, lib::root also accepts a callback as an option. The callback is executed after libs are pushed to @INC ie:

    use lib::root callback => sub { ... };

### EXAMPLE 5 - GET ROOT DIR

IT is also possible to get the root dir calling the root sub:

    my $rootdir = lib::root->root;

### EXAMPLE 5 - GET ROOT DIR

IT is also possible to get the root dir calling the root sub:

    my $rootdir = lib::root->root;

## ACCEPTED PARAMETERS

All the parameters are optional. The default libroot file is `.libroot`

### rootfile parameter

The `rootfile` parameter defines the which file lib::root must look for in parent directories.

That file (.libroot or other) must exist inside a perl $directory because lib::root will use that $dir to push to @INC.

Once lib::root finds the .libroot file inside $dir, it will push $dir/\*/lib to @INC.

The default libroot file is `.libroot`, however you may override it with a different name, or maybe use one that already exists, for example the very used `cpanfile` or `.perl-version`

    use lib::root rootfile => '.perl-version';
    use lib::root rootfile => 'cpanfile';
    use lib::root; #defaults to .libroot

The file must exists or lib::root will throw a warning and will not be able to push to @INC.

Example of such warning:

    lib::root error: Could not find rootfile [ .libroot ]. lib::root loaded from [ /home/user/myapp/perl/MyApp/lib/MyApp.pm ].

### perldir parameter

As mentioned in "rootfile parameter" section, lib::root will find the $dir that contains .libroot. Then push $dir/\*/lib to @INC. However, your app might have a different structure and needs some extra directories ie. `$dir/some/extra/dir/perl/*/lib` to @INC.

You can add that extra dir with the perldir parameter:

    use lib::root perldir => 'some/extra/dir/perl'; #push $librootdir/some/extra/dir/perl/*/lib to @INC
    use lib::root rootfile => 'cpanfile', perldir => 'local/myapp'; #push $dir/local/myapp/*/lib

### callback parameter

lib::root accepts a callback that will be executed after paths are pushed to @INC. However the callback will only execute if libroot found the rootfile and pushed to @INC.

    use lib::root callback => sub { warn "lib::root pushed to @INC" };

### rootdir function

After using `lib::root` it is possible to retrieve the directory that contains the rootfile.

Use the `root` function to get the rootdir. returns a Path::Tiny object. ie:

    use lib::root;
    print lib::root->rootdir; # /home/user/myapp/perl/ (Path::Tiny object)

`rootdir` function is an alias for the `root` function. If you prefer to use root:

    use lib::root;
    print lib::root->root; # /home/user/myapp/perl/ (Path::Tiny object)

## INSTALLATION

To install this module via cpanm:

    cpanm lib::root

Or via cpan shell:

    cpan> install lib::root

## SEE ALSO

Similar ideas have been implemented before in the modules below and possibly others

- RepRoot

    [https://metacpan.org/pod/RepRoot](https://metacpan.org/pod/RepRoot)

- lib::glob

    [https://metacpan.org/pod/lib::glob](https://metacpan.org/pod/lib::glob)

# LICENSE

Copyright (C) Hernan Lopes.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hernan Lopes
