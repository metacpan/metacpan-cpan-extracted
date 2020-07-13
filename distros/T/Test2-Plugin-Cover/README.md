# NAME

Test2::Plugin::Cover - Fast and Minimal file coverage info.

# DESCRIPTION

This plugin will collect minimal file coverage info, and will do so with
minimal performance impact.

Every time a subroutine is called this tool will do its best to find the
filename the subroutine was defined in, and add it to a list. Also, anytime you
attempt to open a file with `open()` or `sysopen()` the file will be added to
the list. This list will be attached to a test2 event just before the test
exits. In most formaters the event will only show up as a comment on STDOUT
` # This test covered N source files. `. However tools such as
[Test2::Harness::UI](https://metacpan.org/pod/Test2%3A%3AHarness%3A%3AUI) can make full use of the coverage information contained
in the event.

## NOTE: SYSOPEN HOOK DISABLED

The sysopen hook is currently disabled because of an unknown segv error on some
platforms. I am not certain if it will be enabled again. calls to subs, and
calls to open are still hooked.

# INTENDED USE CASE

This tool is not intended to record comprehensive coverage information, if you
want that use [Devel::Cover](https://metacpan.org/pod/Devel%3A%3ACover).

This tool is intended to obtain and maintain lists of files that were opened,
or which define subs which were executed by any given test. This information is
useful if you want to determine what test files to run after any given code
change.

The collected coverage data is contained in test2 events, if you use
[Test2::Harness](https://metacpan.org/pod/Test2%3A%3AHarness) aka `yath` then this data can be logged and consumed by
other tools such as [Test2::Harness::UI](https://metacpan.org/pod/Test2%3A%3AHarness%3A%3AUI).

# PERFORMANCE

Unlike tools that need to record comprehensive coverage ([Devel::Cover](https://metacpan.org/pod/Devel%3A%3ACover)), This
module is only concerned about what files you open, or defined subs executed
directly or indirectly by a given test file. As a result this module can get
away with a tiny bit of XS code that only fires when a subroutine is called.
Most coverage tools fire off XS for every statement.

# LIMITATIONS

This tool uses XS to inject a little bit of C code that runs every time a
subroutine is called, or every time `open()` or `sysopen()` is called. This C
code obtains the next op that will be run and tries to pull the filename from
it. `eval`, XS, Moose, and other magic can sometimes mask the filename, this
module only makes a minimal attempt to find the filename in these cases.

This tool DOES NOT cover anything beyond files in which subs executed by the
test were defined. If you want sub names, lines executed, and more, use
[Devel::Cover](https://metacpan.org/pod/Devel%3A%3ACover).

## REAL EXAMPLES

The following data was gathered using prove to run the full [Moose](https://metacpan.org/pod/Moose) test suite:

    # Prove on its own
    Files=478, Tests=17326, 64 wallclock secs ( 1.62 usr  0.46 sys + 57.27 cusr  4.92 csys = 64.27 CPU)

    # Prove with Test2::Plugin::Cover (no coverage event)
    Files=478, Tests=17326, 67 wallclock secs ( 1.61 usr  0.46 sys + 60.98 cusr  5.31 csys = 68.36 CPU)

    # Prove with Devel::Cover
    Files=478, Tests=17324, 963 wallclock secs ( 2.39 usr  0.58 sys + 929.12 cusr 31.98 csys = 964.07 CPU)

_no coverage event_ - No report was generated. This was done to only measure
the effect of the XS that adds the data collection overhead, and not the cost
of the perl code that generates the report event at the end of every test.

The [Moose](https://metacpan.org/pod/Moose) test suite was also run using [Test2::Harness](https://metacpan.org/pod/Test2%3A%3AHarness) aka `yath`

    # Without Test2::Plugin::Cover
    Wall Time: 62.51 seconds CPU Time: 69.13 seconds (usr: 1.84s | sys: 0.08s | cusr: 60.77s | csys: 6.44s)

    # With Test2::Plugin::Cover (no coverage event)
    Wall Time: 75.46 seconds CPU Time: 82.00 seconds (usr: 1.96s | sys: 0.05s | cusr: 72.64s | csys: 7.35s)

As you can see, there is a performance hit, but it is fairly small, specially
compared to [Devel::Cover](https://metacpan.org/pod/Devel%3A%3ACover). This is not to say anything bad about
[Devel::Cover](https://metacpan.org/pod/Devel%3A%3ACover) which is amazing, but a bad choice for the use case
[Test2::Plugin::Cover](https://metacpan.org/pod/Test2%3A%3APlugin%3A%3ACover) was written to address.

# SYNOPSIS

## INLINE

    use Test2::Plugin::Cover;

    ...

    # Arrayref of files covered so far
    my $covered_files = Test2::Plugin::Cover->files;

## COMMAND LINE

You can tell prove to use the module this way:

    HARNESS_PERL_SWITCHES=-MTest2::Plugin::Cover prove ...

This also works for [Test2::Harness](https://metacpan.org/pod/Test2%3A%3AHarness) aka `yath`, but yath may have a flag to
enable this for you by the time you are reading these docs.

## SUPPRESS REPORT

You can suppess the final report (only collect data, do not send the Test2
event)

CLI:

    HARNESS_PERL_SWITCHES=-MTest2::Plugin::Cover=no_event,1 prove ...

INLINE:

    use Test2::Plugin::Cover no_event => 1;

# CLASS METHODS

- $arrayref = $class->files()
- $arrayref = $class->files(filter => \\&filter, extract => \\&extract)

    This will return an arrayref of all files touched so far. If no `filter` or
    `extract` callbacks are provided then `$class->filter()` and
    `$class->extract()` will be used as defaults.

    The list of files will be sorted alphabetically, and duplicates will be
    removed.

    Custom filter callbacks should match the interface for
    `$class->filter()`.

    Custom extract callbacks should match the interface for
    `$class->extract()`.

- $event = $class->report(%options)

    This will send a Test2 event containing coverage information. It will also
    return the event.

    Options:

    - root => Path::Tiny->new("...")

        Normally this is set to the current directory at module load-time. This is used
        to filter out any source files that do not live under the current directory.
        This **MUST** be a [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) instance, passing a string will not work.

    - filter => sub { ... }

        Normally `$class->filter()` is used.

    - extract => sub { ... }

        Normally `$class->extract()` is used.

    - verbose => $BOOL

        If this is set to true then the comment stating how many source files were
        touched will be printed as a diagnostics message instead so that it shows up
        without a verbose harness.

    - ctx => DO NOT USE

        This is used ONLY when the [Test2::API](https://metacpan.org/pod/Test2%3A%3AAPI) is doing its final book-keeping. Most
        users will never want to use this.

- $class->clear()

    This will completely clear all coverage data so far.

- $file\_or\_undef = $class->filter($file)
- $file\_or\_undef = $class->filter($file, root => Path::Tiny->new('...'))

    This method is used as a callback when getting the final list of covered source
    files. The default implementation removes any files that are not under the
    current directory which lets you focus on files in the distribution you are
    testing. You may return a modified filename if you wish to normalize it here,
    the default implementation will turn it into a relative path.

    If you provide a custom `root` parameter, it **MUST** be a [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny)
    instance, passing a string will not work.

    A custom filter callback should look something like this:

        sub {
            my $class = shift;
            my ($file, %params) = @_;

            # clean_filename() does not exist, it is just an example
            $file = clean_filename($file, %params);

            # should_show() does not exist, it is just an example
            return $file if should_show(%params);

            # Return undef or an empty list if you do NOT want to show the file.
            return;
        }

    Please take a look at the source to see what and how `filter()` is implemented
    if you want all the details on how it works.

- $file\_or\_undef = $class->extract($file)
- $file\_or\_undef = $class->extract($file, %params)

    This method is responsible for extracting a sensible filename from whatever the
    XS found. Some magic such as `eval` or [Moose](https://metacpan.org/pod/Moose) can set the `filename` to
    strings like `'(eval 123)'` or `'foo bar (defined at FILE line LINE)'` or
    even nonsensical strings, or text with no filenames.

    If a sensible file name can be extracted it will be returned, otherwise undef
    (or an empty list) is returned.

    The default implementation does not use any parameters, but they are passed in
    for custom implementations to use.

    A custom extract callback should look something like this:

        sub {
            my $class = shift;
            my ($file, %params) = @_;

            # It is a valid file
            return $file if -e $file;

            # Do not use this, just an example
            return $1 if $file =~ m/($VALID_FILE_REGEX)/;

            # Cannot find a file here
            return;
        }

# SEE ALSO

[Devel::Cover](https://metacpan.org/pod/Devel%3A%3ACover) is by far the best and most complete coverage tool for perl. If
you need comprehensive coverage use [Devel::Cover](https://metacpan.org/pod/Devel%3A%3ACover). [Test2::Plugin::Cover](https://metacpan.org/pod/Test2%3A%3APlugin%3A%3ACover) is
only better for a limited use case.

# SOURCE

The source code repository for Test2-Plugin-Cover can be found at
`https://github.com/Test-More/Test2-Plugin-Cover`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2020 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
