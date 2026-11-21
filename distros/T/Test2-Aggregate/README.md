# NAME

Test2::Aggregate - Aggregate tests for increased speed

# SYNOPSIS

    use Test2::Aggregate;
    use Test2::V0; # Or 'use Test::More' etc if your suite uses an other framework

    Test2::Aggregate::run_tests(
        dirs => [@test_dirs_or_files]
    );

    done_testing();

# VERSION

See `$VERSION` in module.

# DESCRIPTION

Aggregates all tests specified with `dirs` (which can even be individual tests)
to avoid forking, reloading etc. that can help with performance (dramatically if
you have numerous small tests) and also facilitate group profiling. It is quite
common to have tests that take over a second of startup time for milliseconds of
actual runtime - [Test2::Aggregate](https://metacpan.org/pod/Test2%3A%3AAggregate) removes that overhead.
Test files are expected to end in **.t** and are run as subtests of a single
aggregate test.

A bit similar (mainly in intent) to [Test::Aggregate](https://metacpan.org/pod/Test%3A%3AAggregate), but no inspiration was
drawn from the specific module, so simpler in concept and execution, which
makes it much more likely to work with your test suite (especially if you use modern
tools like [Test2::Suite](https://metacpan.org/pod/Test2%3A%3ASuite)). It does not even try to package each test by default
(there is an option), which may be good or bad, depending on your requirements.

Generally, the way to use this module is to try to aggregate sets of quick tests
(e.g. unit tests). Try to iteratively add tests to the aggregator, using the `lists`
option, so you can easily edit and remove those that do not work. Trying an entire,
large, suite in one go is not a good idea, as an incompatible test can break the
run making the subsequent tests fail (especially when doing things like globally
redefining built-ins etc.) - see the module usage notes for help.

The module can work with [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder) / [Test::More](https://metacpan.org/pod/Test%3A%3AMore) suites, but you will
have less issues with [Test2::Suite](https://metacpan.org/pod/Test2%3A%3ASuite) (see notes).

# METHODS

## `run_tests`

    my $stats = Test2::Aggregate::run_tests(
        dirs          => \@dirs,              # optional if lists defined
        lists         => \@lists,             # optional if dirs defined
        exclude       => qr/exclude_regex/,   # optional
        include       => qr/include_regex/,   # optional
        root          => '/testroot/',        # optional
        load_modules  => \@modules,           # optional
        package       => 0,                   # optional
        shuffle       => 0,                   # optional
        sort          => 0,                   # optional
        reverse       => 0,                   # optional
        unique        => 1,                   # optional
        repeat        => 1,                   # optional, requires Test2::Plugin::BailOnFail for < 0
        slow          => 0,                   # optional
        test_warnings => 0,                   # optional
        override      => \%override,          # optional, requires Sub::Override
        stats_output  => $stats_output_path,  # optional
        extend_stats  => 0,                   # optional
        pass_only     => 0,                   # optional
        absolute      => 0,                   # optional
        bail_on_fail  => 0,                   # optional, requires Test2::Plugin::BailOnFail
        no_dot        => 0,                   # optional
        relative_root => 0,                   # optional
        allow_errors  => 0,                   # optional
        pre_eval      => $code_to_eval,       # optional
        dry_run       => 0,                   # optional
        recursion     => 0,                   # optional
        slurp_param   => {binmode => $mode}   # optional
    );

Runs the aggregate tests. Returns a hashref with stats like this:

    $stats = {
      'test.t' => {
        'test_no'   => 1,                 # numbering starts at 1
        'pass_perc' => 100,               # for single runs pass/fail is 100/0
        'timestamp' => '20190705T145043', # start of test
        'time'      => '0.1732',          # seconds - only with stats_output
        'warnings'  => $STDERR            # only with test_warnings on non empty STDERR
      }
    };

The parameters to pass:

- `dirs` (either this or `lists` is required)

    An arrayref containing directories which will be searched recursively, or even
    individual tests. The directories (unless `shuffle` or `reverse` are true)
    will be processed and tests run in order specified. Test files are expected to
    end in `.t`.

- `lists` (either this or `dirs` is required)

    Arrayref of flat files from which each line will be pushed to `dirs` (so they
    have a lower precedence - note `root` still applies, don't include it in the
    paths inside the list files). If the path does not exist, it will currently be
    silently ignored, however the "official" way to skip a line without checking it
    as a path is to start with a `#` to denote a comment.

    This option is nicely combined with the `--exclude-list` option of `yath` (the
    [Test2::Harness](https://metacpan.org/pod/Test2%3A%3AHarness)) to skip the individual runs of the tests you aggregated.

- `exclude` (optional)

    A regex to filter out tests that you want excluded.

- `include` (optional)

    A regex which the tests have to match in order to be included in the test run.
    Applied after `exclude`.

- `root` (optional)

    If defined, must be a valid root directory that will prefix all `dirs` and `lists`
    items. You may want to set it to `'./'` if you want dirs relative to the current
    directory and the dot is not in your `@INC`.

- `relative_root` (optional)

    Set to true if you want your root to be relative to the caller script's directory
    (based on `$0`). It is ignored if you use an absolute root path.

- `load_modules` (optional)

    Arrayref with modules to be loaded (with `eval "use ..."`) at the start of the
    test. Useful for testing modules with special namespace requirements.

- `package` (optional)

    Will package each test in its own namespace. While it may help avoid things like
    redefine warnings, from experience, it can break some tests, so it is disabled
    by default.

- `override` (optional)

    Pass [Sub::Override](https://metacpan.org/pod/Sub%3A%3AOverride) compatible key/values as a hashref.

- `repeat` (optional)

    Number of times to repeat the test(s) (default is 1 for a single run). If
    `repeat` is negative, [Test2::Plugin::BailOnFail](https://metacpan.org/pod/Test2%3A%3APlugin%3A%3ABailOnFail) is required, as the tests
    will repeat until they bail on a failure. It can be combined with `test_warnings`
    in which case a warning will also cause the test run to end.

- `unique` (optional)

    From v0.11, duplicate tests are by default removed from the running list as that
    could mess up the stats output. You can still define it as false to allow duplicate
    tests in the list.

- `sort` (optional)

    Sort tests alphabetically if set to true. Provides a way to fix the test order
    across systems.

- `shuffle` (optional)

    Random order of tests if set to true. Will override `sort`.
    Uses `List::Util::shuffle`, so is affected by the `$RAND` variable.

- `reverse` (optional)

    Reverse order of tests if set to true.

- `slow` (optional)

    When true, tests will be skipped if the environment variable `SKIP_SLOW` is set.

- `test_warnings` (optional)

    Tests for warnings over all the tests if set to true - this is added as a final
    test which expects zero as the number of tests which had STDERR output.
    The STDERR output of each test will be printed at the end of the test run (and
    included in the test run result hash), so if you want to see warnings the moment
    they are generated leave this option disabled.

- `allow_errors` (optional)

    If enabled, it will allow errors that exit tests prematurely (so they may return
    a pass if one of their subtests had passed). The option is available to enable
    old behaviour (version <= 0.12), before the module stopped allowing this.

- `dry_run` (optional)

    Instead of running the tests, will do `ok($testname)` for each one. Otherwise,
    test order, stats files etc. will be produced (as if all tests passed).

- `slurp_param` (optional)

    If you are using list files, by default, `Path::Tiny::slurp_utf8` will be used
    to read them.
    If you would like to use `slurp` with your own parameters instead, like a UTF16
    binmode etc, you can pass them here.

- `pre_eval` (optional)

    String with code to run with eval before each test. You might be inclined to do
    this for example:

        pre_eval => "no warnings 'redefine';"

    You might expect it to silence redefine warnings (when you have similarly named
    subs on many tests), but even if you don't set warnings explicitly in your tests,
    most test bundles will set warnings automatically for you (e.g. for [Test2::V0](https://metacpan.org/pod/Test2%3A%3AV0)
    you'd have to do `use Test2::V0 -no_warnings => 1;` to avoid it).

- `stats_output` (optional)

    `stats_output` specifies a path where a file will be created to print out
    running time per test (average if multiple iterations) and passing percentage.
    With `repeat == 1`, output is written after each test in execution order, so
    completed results survive an interrupted run. With `repeat > 1`, averages
    are written from slowest test to fastest after all iterations complete.
    On negative `repeat`, each iteration streams its own statistics.
    The name of the file is `caller_script-YYYYMMDDTHHmmss.txt`.
    If `'-'` is passed instead of a path, then the output will be written to STDOUT.
    The timing stats are useful because the test harness doesn't normally measure
    time per subtest (remember, your individual aggregated tests become subtests).
    If you prefer to capture the hash output of the function and use that for your
    reports, you still need to define `stats_output` to enable timing (just send
    the output to `/dev/null`, `/tmp` etc).

- `extend_stats` (optional)

    This option exist to make the default output format of `stats_output` be fixed,
    but still allow additions in future versions that will only be written with the
    `extend_stats` option enabled.
    Additions with `extend_stats` as of the current version:

    - starting date/time in ISO\_8601.

- `pass_only` (optional)

    Modifies `stats_output` by making it only print out a list of passing tests.
    Useful for creating lists of aggregateable tests. With `test_warnings`, tests
    that produced warnings are not considered passing.
    Has no effect if `stats_output` is not defined.

- `absolute` (optional)

    Matches pre-1.00 behaviour by including `root` in the output of stats.

- `no_dot` (optional)

    Current version will add a `./` at the start of a test file if the full path does
    not start with `/` or `.` to avoid the `'.' is no longer in @INC` error.
    Setting `no_dot` to true matches pre-1.00 behaviour that did not do this.

- `bail_on_fail` (optional)

    Will bail (exit) on first test failure. It is implied for repeat < 0.
    Requires [Test2::Plugin::BailOnFail](https://metacpan.org/pod/Test2%3A%3APlugin%3A%3ABailOnFail); a missing plugin is a fatal error.

- `recursion` (optional)

    Setting it to 1 will allow recursion. By default, if `$ENV{AGGREGATE_TESTS}` is
    true, `run_tests` will skip the tests to avoid running under a parent aggregator
    `run_tests`.

# HELPER SCRIPTS

## agg (Test2::Aggregate harness wrapper)

    agg [options] <file/dir1 ...>

Pass a list of Perl test files/directories and they will run aggregated via yath
(or prove if specified). It is not meant to be used for .t files that use Test2::Aggregate
themselves.

It is useful either to speed up a test run for tests you know can be aggregated,
or to check whether specific tests can run successfully under Test2::Aggregate.

    Options:
    --out <s>,          -o <s>  : Specify the test file to be created (tmp file by default).
    --lists,            -l      : Use files specified as lists.
    --prove,            -p      : Force prove (default is yath/Test2 if installed).
    --verbose,          -v      : Verbose (passed to yath/prove)
    --absolute,         -a      : Use absolute paths in generated files. Disabled with -r.
    --include_regex <s> -ir <s> : Regex for test paths to include.
    --exclude_regex <s> -er <s> : Regex for test paths to exclude.
    --root <s>          -r <s>  : Define a custom root dir (default is current dir).
    --include <s>,      -I <s>  : Library paths to include.
    --test_warnings,    -w      : Fail tests on warnings.
    --test_bundle <s>,  -t      : Test bundle (def: Test2::V0 or Test::More if -p). Can be comma-separated list.
    --pass_output <s>,  -po <s> : Output directory for list of 100% passing tests.
    --reverse                   : Reverse the test order.
    --shuffle                   : Shuffle the test order.
    --sort                      : Run the tests alphabetically.
    --stats_output <s>, -so <s> : Stats output directory (does not combine with pass_output).
    --help              -h      : Show basic help and exit.

## aggit (Test2::Aggregate iterative aggregator)

    aggit [options] <file/dir1 ...>

Runs tests through an aggregate test repeatedly. On each failed run, the active
test file is removed and the remaining set is tried again. Requires
[Test2::Plugin::BailOnFail](https://metacpan.org/pod/Test2%3A%3APlugin%3A%3ABailOnFail). Startup failures and failures after all test files
have completed abort the command with a nonzero exit status instead of removing
tests. This is a coarse way to discover a starting list of tests that can be
aggregated together, not proof that each removed test is independently broken.

`--sort`, `--shuffle`, and `--reverse` are applied once during discovery.
The resulting order is preserved across retries and in the generated runner.
By default, list entries are relative to the generated runner's directory;
`--absolute` writes absolute paths. `--root` resolves inputs against a custom
directory. `--exclude_regex` and `--exclude_list` filter the discovered tests.

`aggit` passes `--event_timeout SECONDS` (alias `-et`, default 10) to
`yath` as `--et SECONDS`. This is an inactivity timeout, not a total runtime
limit; Harness normally defaults to 60 seconds. The timeout applies to the
generated aggregate runner, so `# HARNESS-NO-TIMEOUT` comments in individual
aggregated files do not disable it. Under `--prove`, or automatic fallback to
`prove` when Harness is unavailable, this timeout is not provided and hung
tests require external supervision.

For `agg`, `--pass_output` takes precedence over `--stats_output` when both
are supplied.

## Common helper workflows

Try known-safe tests through the default [Test2::Harness](https://metacpan.org/pod/Test2%3A%3AHarness) runner:

    agg t/unit t/lib

Force `prove` and [Test::More](https://metacpan.org/pod/Test%3A%3AMore) compatibility mode:

    agg --prove t/unit

Generate a directory containing a list of tests that passed when aggregated:

    agg --root . --pass_output pass t

`--root .` makes the passing paths relative to the current project directory,
rather than the temporary aggregate runner's directory.

Iteratively discover an aggregateable list and generated aggregate test:

    aggit --out aggregate-candidate t

Run the generated aggregate test later (its list paths are runner-relative):

    yath test aggregate-candidate.t

# USAGE NOTES

Not all tests can be modified to run under the aggregator, it is not intended
for tests that require an isolated environment, do overrides etc. For other tests
which can potentially run under the aggregator, sometimes very simple changes may be
needed like giving unique names to subs (or not warning for redefines, or trying the
package option), replacing things that complain, restoring the environment at
the end of the test etc.

Unit tests are usually great for aggregating. You could use the hash that `run_tests`
returns in a script that tries to add more tests automatically to an aggregate list
to see which added tests passed and keep them, dropping failures. See later in the
notes for a detailed example.

Trying to aggregate too many tests into a single one can be counter-intuitive as
you would ideally want to parallelize your test suite (so a super-long aggregated
test continuing after the rest are done will slow down the suite). And in general
more tests will run aggregated if they are grouped so that tests that can't be
aggregated together are in different groups.

You can call `Test2::Aggregate::run_tests` multiple times in a test. Nested calls
are skipped unless the inner call enables `recursion`. Loading
[Test2::Plugin::BailOnFail](https://metacpan.org/pod/Test2%3A%3APlugin%3A%3ABailOnFail) through `bail_on_fail` or `repeat < 0` affects
subsequent tests too: a later failure will also trigger a bail-out.

## Version 1.00 path compatibility

Stats keys and warning labels are root-relative by default in 1.00. Set
`absolute` if you need the previous full rooted paths in stats output.

Relative test paths that do not start with `/`, `.`, or `./` are now executed
with a `./` prefix so they keep working on perls where `.` is not in `@INC`.
Set `no_dot` if you need the previous behaviour.

Nested aggregate runs are skipped by default when `$ENV{AGGREGATE_TESTS}` is
already set. Set `recursion` only for suites where nested aggregate execution is
intentional.

## Test::More

If you haven't switched to the [Test2::Suite](https://metacpan.org/pod/Test2%3A%3ASuite) you are generally advised to do so
for a number of reasons, compatibility with this module being only a very minor
one. If you are stuck with a [Test::More](https://metacpan.org/pod/Test%3A%3AMore) suite, [Test2::Aggregate](https://metacpan.org/pod/Test2%3A%3AAggregate) can still
probably help you more than the similarly-named `Test::Aggregate...` modules.

Although the module tries to load `Test2` with minimal imports to not interfere,
it is generally better to do `use Test::More;` in your aggregating test (i.e.
alongside with `use Test2::Aggregate`).

## Test::Builder

To avoid warnings, if you are importing [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder) in multiple aggregated
tests, you will want to import first on the aggregating test.
It might look like this:

    use Test::Builder;
    use Test2::V0;
    use Test2::Aggregate;

    Test2::Aggregate::run_tests( ... );

## BEGIN / END Blocks

`BEGIN` blocks run as each test file is compiled. `END` blocks are deferred
until the aggregate process exits, not the end of each individual test file.
Cleanup needed between files must therefore happen before the file returns.
Global overrides can affect later tests. One example is a
`*CORE::GLOBAL::exit` override to test scripts that can call `exit()`.
A solution is to use something like [Test::Trap](https://metacpan.org/pod/Test%3A%3ATrap): 

    BEGIN {
        unless ($Test::Trap::VERSION) { # Avoid warnings for multiple loads in aggregation
            require Test::Trap;
            Test::Trap->import();
        }
    }

## Test::Class

[Test::Class](https://metacpan.org/pod/Test%3A%3AClass) is sort of an aggregator itself. You make your tests into modules
and then load them on the same `.t` file, so ideally you will not end up with many
`.t` files that would require further aggregation. If you do, due to the [Test::Class](https://metacpan.org/pod/Test%3A%3AClass)
implementation specifics, those `.t` files won't run under [Test2::Aggregate](https://metacpan.org/pod/Test2%3A%3AAggregate).

## $0 variable

Remember the `$0` variable is the aggregate runner, not the test file.

## Mocks, CORE::GLOBAL::\* Overrides

Always prefer mocks (Test2::Mock) instead of global built-ins where possible for
aggregated tests. Remember to clear mocks at the end of test.

## $ENV{AGGREGATE\_TESTS}

The environment variable `AGGREGATE_TESTS` will be set while the tests are running
for your convenience. Example usage is making a test you know cannot run under the
aggregator check and croak if it was run under it, or a module that can only be loaded
once, so you load it on the aggregated test file and then use something like this in
the individual test files:

    eval 'use My::Module' unless $ENV{AGGREGATE_TESTS};

If you have a custom test bundle, you could use the variable to do things like
disable warnings on redefines only for tests that run aggregated:

    use Import::Into;

    sub import {
       ...
       'warnings'->unimport::out_of($package, 'redefine')
           if $ENV{AGGREGATE_TESTS};
    }

Another idea is to make the test die when it is run under the aggregator, if, at
design time, you know it is not supposed to run aggregated.

## Example aggregating strategy

There are many approaches you could do to use `Test2::Aggregate` with an existing
test suite, usually involving an iterative process of trying to run several tests
aggregated, seeing if you can fix the failing ones, otherwise you remove them from
the aggregation etc.

This process can be done with the help of the `agg` script. For example, to try
all tests under `t/` aggregated and a list of passing tests put under the `pass`
directory you would do:

    > agg --root . --pass_output pass t

(which will use `yath` & [Test2::V0](https://metacpan.org/pod/Test2%3A%3AV0), you can do
`agg --prove --root . --pass_output pass t` for `prove` & [Test::More](https://metacpan.org/pod/Test%3A%3AMore))

If the run completes, thanks to `--pass_output` you have a "starting point"
 i.e. a .txt list that can run under the aggregator with the `lists` option:

    Test2::Aggregate::run_tests(
        lists => ['pass/name_of_file.txt']
    );

If the run does not complete (e.g. signal 11 on some test), try fewer tests by
choosing just a subdirectory. If that's not possible, you'll probably have to go
to the more manual method of getting a full list of your tests
(`find t -name '*.t' > all.lst`) then trying to run parts of it, again with
the `lists` option.

After you have a starting point, you can try see if there is an obvious reason some
tests fail and address it to add them back to the pass list. You can even try adding
back some of the failed tests that were not among the first to fail - test failures
can sometimes be cascading, so some might be passing if added back, or have small
issues you can address.

Try adding `test_warnings => 1` to `run_tests` to fix warnings as well, unless
it is common for your tests to have `STDERR` output.

In the end, you will end up with part of your tests aggregated in (multiple if you
want to run them in parallel) list files, with the rest of your tests to be run
non-aggregated.

You don't actually have to move and separate aggregated/non-aggregated files when
using lists, you can still have your entire suite run the aggregated tests once and
not repeat them along with the other, non-aggregated tests, by taking advantage of
the `--exclude-list` option of the `Test2::Harness`.

Hopefully your tests can run in parallel (`prove/yath -j`), in which case you
would split your aggregated tests into multiple lists to have them run in parallel.
Here is an example of a wrapper around `yath`, to easily handle multiple lists:

    BEGIN {
        my @args = ();
        foreach (@ARGV) {
            if (/--exclude-lists=(\S+)/) {
                my $all = 't/aggregate/aggregated.tests';
                `awk '{print "t/"\$0}' $1 > $all`;
                push @args, "--exclude-list=$all";
            } else { push @args, $_ if $_; }
        }
        push @args, qw(-P...) # Preload module list (useful for non-aggregated tests)
            unless grep {/--cover/} @args;
        @ARGV = @args;
    }
    exec ('yath', @ARGV);

You would call it with something like `--exclude-lists=t/aggregate/*.lst`, and
the tests listed will be excluded (you will have them running aggregated through
their own `.t` files using [Test2::Aggregate](https://metacpan.org/pod/Test2%3A%3AAggregate)).

# WINDOWS SUPPORT

Only filesystems with the `/` separator are supported, simply because the author
does not expect Windows users (many test suites don't work under StrawberryPerl
etc). However, if you want Windows filesystems to be supported, it should be simple
enough as long as you are willing to help with testing - just ask.

# DEVELOPMENT AND RELEASES

`README.md` is generated from this module's POD using [Pod::Markdown](https://metacpan.org/pod/Pod%3A%3AMarkdown).
Install author dependencies, then run:

    perl Makefile.PL
    make readme
    AUTHOR_TESTING=1 prove -Ilib xt/author xt/integration
    make disttest

`make readme` refreshes the README. `make distdir` (also used by `make dist`
and `make disttest`) refreshes it automatically before copying distribution
files. These author targets require [Pod::Markdown](https://metacpan.org/pod/Pod%3A%3AMarkdown), but normal installation
and `make test` do not. The README author test detects stale generated content;
review and commit README changes alongside the POD. Set the release date in
`Changes` when preparing the final release.

# AUTHOR

Dimitrios Kechagias, [https://metacpan.org/author/DKECHAG](https://metacpan.org/author/DKECHAG)

# BUGS

Please report any bugs or feature requests to `bug-test2-aggregate at rt.cpan.org`,
or through the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test2-Aggregate](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test2-Aggregate).
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes. You could also submit issues or even pull requests to the
github repo (see below).

# GIT

[https://github.com/SpareRoom/Test2-Aggregate](https://github.com/SpareRoom/Test2-Aggregate)

# COPYRIGHT & LICENSE

Copyright (C) 2019, SpareRoom.com

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.
