package Test2::Aggregate;

use strict;
use warnings;

use File::Basename;
use File::Find;
use File::Path;
use File::Spec;
use Path::Tiny;

use Test2::V0 'subtest';

=head1 NAME

Test2::Aggregate - Aggregate tests for increased speed

=head1 SYNOPSIS

    use Test2::Aggregate;
    use Test2::V0; # Or 'use Test::More' etc if your suite uses an other framework

    Test2::Aggregate::run_tests(
        dirs => [@test_dirs_or_files]
    );

    done_testing();

=head1 VERSION

See C<$VERSION> in module.

=cut

our $VERSION = '1.01';

=head1 DESCRIPTION

Aggregates all tests specified with C<dirs> (which can even be individual tests)
to avoid forking, reloading etc. that can help with performance (dramatically if
you have numerous small tests) and also facilitate group profiling. It is quite
common to have tests that take over a second of startup time for milliseconds of
actual runtime - L<Test2::Aggregate> removes that overhead.
Test files are expected to end in B<.t> and are run as subtests of a single
aggregate test.

A bit similar (mainly in intent) to L<Test::Aggregate>, but no inspiration was
drawn from the specific module, so simpler in concept and execution, which
makes it much more likely to work with your test suite (especially if you use modern
tools like L<Test2::Suite>). It does not even try to package each test by default
(there is an option), which may be good or bad, depending on your requirements.

Generally, the way to use this module is to try to aggregate sets of quick tests
(e.g. unit tests). Try to iteratively add tests to the aggregator, using the C<lists>
option, so you can easily edit and remove those that do not work. Trying an entire,
large, suite in one go is not a good idea, as an incompatible test can break the
run making the subsequent tests fail (especially when doing things like globally
redefining built-ins etc.) - see the module usage notes for help.

The module can work with L<Test::Builder> / L<Test::More> suites, but you will
have less issues with L<Test2::Suite> (see notes).

=head1 METHODS
 
=head2 C<run_tests>

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

=over 4
 
=item * C<dirs> (either this or C<lists> is required)

An arrayref containing directories which will be searched recursively, or even
individual tests. The directories (unless C<shuffle> or C<reverse> are true)
will be processed and tests run in order specified. Test files are expected to
end in C<.t>.

=item * C<lists> (either this or C<dirs> is required)

Arrayref of flat files from which each line will be pushed to C<dirs> (so they
have a lower precedence - note C<root> still applies, don't include it in the
paths inside the list files). If the path does not exist, it will currently be
silently ignored, however the "official" way to skip a line without checking it
as a path is to start with a C<#> to denote a comment.

This option is nicely combined with the C<--exclude-list> option of C<yath> (the
L<Test2::Harness>) to skip the individual runs of the tests you aggregated.

=item * C<exclude> (optional)

A regex to filter out tests that you want excluded.

=item * C<include> (optional)

A regex which the tests have to match in order to be included in the test run.
Applied after C<exclude>.

=item * C<root> (optional)

If defined, must be a valid root directory that will prefix all C<dirs> and C<lists>
items. You may want to set it to C<'./'> if you want dirs relative to the current
directory and the dot is not in your C<@INC>.

=item * C<relative_root> (optional)

Set to true if you want your root to be relative to the caller script's directory
(based on C<$0>). It is ignored if you use an absolute root path.

=item * C<load_modules> (optional)

Arrayref with modules to be loaded (with C<eval "use ...">) at the start of the
test. Useful for testing modules with special namespace requirements.

=item * C<package> (optional)

Will package each test in its own namespace. While it may help avoid things like
redefine warnings, from experience, it can break some tests, so it is disabled
by default.

=item * C<override> (optional)

Pass L<Sub::Override> compatible key/values as a hashref.

=item * C<repeat> (optional)

Number of times to repeat the test(s) (default is 1 for a single run). If
C<repeat> is negative, L<Test2::Plugin::BailOnFail> is required, as the tests
will repeat until they bail on a failure. It can be combined with C<test_warnings>
in which case a warning will also cause the test run to end.

=item * C<unique> (optional)

From v0.11, duplicate tests are by default removed from the running list as that
could mess up the stats output. You can still define it as false to allow duplicate
tests in the list.

=item * C<sort> (optional)

Sort tests alphabetically if set to true. Provides a way to fix the test order
across systems.

=item * C<shuffle> (optional)

Random order of tests if set to true. Will override C<sort>.
Uses C<List::Util::shuffle>, so is affected by the C<$RAND> variable.

=item * C<reverse> (optional)

Reverse order of tests if set to true.

=item * C<slow> (optional)

When true, tests will be skipped if the environment variable C<SKIP_SLOW> is set.

=item * C<test_warnings> (optional)

Tests for warnings over all the tests if set to true - this is added as a final
test which expects zero as the number of tests which had STDERR output.
The STDERR output of each test will be printed at the end of the test run (and
included in the test run result hash), so if you want to see warnings the moment
they are generated leave this option disabled.

=item * C<allow_errors> (optional)

If enabled, it will allow errors that exit tests prematurely (so they may return
a pass if one of their subtests had passed). The option is available to enable
old behaviour (version <= 0.12), before the module stopped allowing this.

=item * C<dry_run> (optional)

Instead of running the tests, will do C<ok($testname)> for each one. Otherwise,
test order, stats files etc. will be produced (as if all tests passed).

=item * C<slurp_param> (optional)

If you are using list files, by default, C<Path::Tiny::slurp_utf8> will be used
to read them.
If you would like to use C<slurp> with your own parameters instead, like a UTF16
binmode etc, you can pass them here.

=item * C<pre_eval> (optional)

String with code to run with eval before each test. You might be inclined to do
this for example:

  pre_eval => "no warnings 'redefine';"

You might expect it to silence redefine warnings (when you have similarly named
subs on many tests), but even if you don't set warnings explicitly in your tests,
most test bundles will set warnings automatically for you (e.g. for L<Test2::V0>
you'd have to do C<use Test2::V0 -no_warnings =E<gt> 1;> to avoid it).

=item * C<stats_output> (optional)

C<stats_output> specifies a path where a file will be created to print out
running time per test (average if multiple iterations) and passing percentage.
With C<repeat == 1>, output is written after each test in execution order, so
completed results survive an interrupted run. With C<repeat E<gt> 1>, averages
are written from slowest test to fastest after all iterations complete.
On negative C<repeat>, each iteration streams its own statistics.
The name of the file is C<caller_script-YYYYMMDDTHHmmss.txt>.
If C<'-'> is passed instead of a path, then the output will be written to STDOUT.
The timing stats are useful because the test harness doesn't normally measure
time per subtest (remember, your individual aggregated tests become subtests).
If you prefer to capture the hash output of the function and use that for your
reports, you still need to define C<stats_output> to enable timing (just send
the output to C</dev/null>, C</tmp> etc).

=item * C<extend_stats> (optional)

This option exist to make the default output format of C<stats_output> be fixed,
but still allow additions in future versions that will only be written with the
C<extend_stats> option enabled.
Additions with C<extend_stats> as of the current version:

=over 4

=item * starting date/time in ISO_8601.

=back

=item * C<pass_only> (optional)

Modifies C<stats_output> by making it only print out a list of passing tests.
Useful for creating lists of aggregateable tests. With C<test_warnings>, tests
that produced warnings are not considered passing.
Has no effect if C<stats_output> is not defined.

=item * C<absolute> (optional)

Matches pre-1.00 behaviour by including C<root> in the output of stats.

=item * C<no_dot> (optional)

Current version will add a C<./> at the start of a test file if the path is
not absolute (e.g. C</...>, or C<C:/...> on Windows) and does not start with
C<.>, to avoid the C<'.' is no longer in @INC> error.
Setting C<no_dot> to true matches pre-1.00 behaviour that did not do this.

=item * C<bail_on_fail> (optional)

Will bail (exit) on first test failure. It is implied for repeat < 0.
Requires L<Test2::Plugin::BailOnFail>; a missing plugin is a fatal error.

=item * C<recursion> (optional)

Setting it to 1 will allow recursion. By default, if C<$ENV{AGGREGATE_TESTS}> is
true, C<run_tests> will skip the tests to avoid running under a parent aggregator
C<run_tests>.

=back

=cut

sub run_tests {
    my %args = @_;

    Test2::V0::plan skip_all => 'Skipping slow tests.'
        if $args{slow} && $ENV{SKIP_SLOW};

    Test2::V0::plan skip_all => 'Skipping aggregator recursion.'
        if !$args{recursion} && $ENV{AGGREGATE_TESTS};

    eval "use $_;" foreach @{$args{load_modules}};
    local $ENV{AGGREGATE_TESTS} = 1;

    my $override = $args{override} ? _override($args{override}) : undef;
    my @dirs     = ();
    $args{root} ||= '';
    my @tests;

    @dirs = @{$args{dirs}} if $args{dirs};
    $args{root} .= '/' unless !$args{root} || $args{root} =~ m#/$#;
    $args{root} = dirname($0) . "/$args{root}"
        if $args{relative_root} && $args{root} && !File::Spec->file_name_is_absolute($args{root});

    if ($args{root} && ! -e $args{root}) {
        warn "Root '$args{root}' does not exist, no tests are loaded."
    } else {
        foreach my $file (@{$args{lists}}) {
            push @dirs,
                map {/^\s*(?:#|$)/ ? () : $_}
                split(/\r?\n/,
                _read_file($args{root}, $file, $args{slurp_param}));
        }

        find(
            sub {push @tests, $File::Find::name if /\.t$/},
            grep {-e} map {_check_abs_path($args{root}, $_)} @dirs
        )
            if @dirs;
    }

    $args{unique} = 1 unless defined $args{unique};
    $args{repeat} ||= 1;

    _process_run_order(\@tests, \%args);

    my @stack = caller();
    $args{caller} = $stack[1] || 'aggregate';
    $args{caller} =~ s#^.*?([^/]+)$#$1#;

    my $warnings = [];
    if ($args{bail_on_fail} || $args{repeat} < 0) {
        eval 'use Test2::Plugin::BailOnFail; 1' or die $@;
    }
    if ($args{repeat} < 0) {
        my $iter = 0;
        while (!@$warnings) {
            $iter++;
            print "Test suite iteration $iter\n";
            if ($args{test_warnings}) {
                $warnings = _process_warnings(
                    Test2::V0::warnings{_run_tests(\@tests, \%args)},
                     \%args
                );
            } else {
                _run_tests(\@tests, \%args);
            }
        }
    } elsif ($args{test_warnings}) {
        $warnings = _process_warnings(
            Test2::V0::warnings { _run_tests(\@tests, \%args) },
            \%args
        );
        Test2::V0::is(
            @$warnings,
            0,
            'No warnings in the aggregate tests.'
        );
    } else {
        _run_tests(\@tests, \%args);
    }

    warn "Test warning output:\n".join("\n", @$warnings)."\n"
        if @$warnings;

    return $args{stats};
}

sub _check_abs_path {
    my $root = shift;
    my $path = shift;
    # Can't use path() below as it removes ./ (required by absolute option)
    $path = "$root$path" unless !$root || File::Spec->file_name_is_absolute($path);
    return $path;
}

sub _read_file {
    my $root  = shift;
    my $path  = shift;
    my $param = shift;
    my $file  = path(_check_abs_path($root, $path));

    return $param ? $file->slurp($param) : $file->slurp_utf8;
}

sub _process_run_order {
    my $tests = shift;
    my $args  = shift;

    @$tests = grep(!_path_match($_, $args->{exclude}, $args->{root}), @$tests)
        if $args->{exclude};
    @$tests = grep(_path_match($_, $args->{include}, $args->{root}), @$tests)
        if $args->{include};

    @$tests = _uniq(@$tests)  if $args->{unique};

    if ($args->{shuffle}) {
        require List::Util;
        @$tests = List::Util::shuffle @$tests;
    } elsif ($args->{sort}) {
        @$tests = sort @$tests;
    }

    @$tests = reverse @$tests if $args->{reverse};
}

sub _path_match {
    my ($test, $regex, $root) = @_;

    return 1 if $test =~ /$regex/;
    return _test_name($test, $root) =~ /$regex/;
}

sub _process_warnings {
    my $warnings = shift;
    my $args     = shift;
    my @warnings = split(/<-Test2::Aggregate\n/, join('',@$warnings));
    my @clean    = ();

    foreach my $warn (@warnings) {
        if ($warn =~ m/(.*)->Test2::Aggregate\n(.*\S.*)/s) {
            push @clean, "<$1>\n$2";
            $args->{stats}->{$1}->{warnings} = $2;
            $args->{stats}->{$1}->{pass_perc} = 0;
        }
    }
    return \@clean;
}

sub _run_tests {
    my $tests = shift;
    my $args  = shift;

    my $repeat = $args->{repeat};
    $repeat = 1 if $repeat < 0;
    my (%stats, %warned, $start, $warned);

    # Track warnings per test, so stats written before the final warning
    # processing (e.g. streamed pass_only) already see them. Installed once per
    # run, not per test, so handlers that tests install (e.g. NoWarnings on
    # first load) stay in place for the following tests.
    local $SIG{__WARN__} = _warn_tracker(\$warned) if $args->{test_warnings};

    require Time::HiRes if $args->{stats_output};
    my $fh = _stats_fh($args);

    for my $i (1 .. $repeat) {
        my $iter = $repeat > 1 ? "Iter: $i/$repeat - " : '';
        my $count = 1;
        foreach my $test (@$tests) {
            my $test_nm =
                $args->{absolute} ? $test : _test_name($test, $args->{root});

            warn  "$test_nm->Test2::Aggregate\n" if $args->{test_warnings};

            $stats{$test_nm}{test_no} = $count unless $stats{$test_nm}{test_no};
            $start = Time::HiRes::time() if $args->{stats_output};
            $stats{$test_nm}{timestamp} = _timestamp();

            my $exec_error;
            $warned = 0;
            # aggit uses this marker to distinguish an interrupted test from
            # harness startup errors and failures after the suite has finished.
            path($args->{_progress_file})->spew_utf8("$test_nm\n")
                if $args->{_progress_file};
            my $result = subtest $iter. "Running test $test_nm" => sub {
                eval $args->{pre_eval} if $args->{pre_eval};

                if ($args->{dry_run}) {
                    Test2::V0::ok($test);
                } else {
                    my $t= $test;
                    $t = "./$test"
                        unless $args->{no_dot} || $test =~ m#^\.# || File::Spec->file_name_is_absolute($test);
                    $args->{package}
                        ? eval "package Test::$i" . '::' . "$count; do '$t';"
                        : do $t;
                    $exec_error = $@;
                }
                Test2::V0::is($exec_error, '', 'Execution should not fail/warn')
                        if !$args->{allow_errors} && $exec_error;
            };

            $warned{$test_nm} = 1 if $warned;
            warn "<-Test2::Aggregate\n" if $args->{test_warnings};

            $stats{$test_nm}{time} += (Time::HiRes::time() - $start)/$repeat
                if $args->{stats_output};
            $stats{$test_nm}{pass_perc} += $result ? 100/$repeat : 0;
            # Matches _process_warnings, which zeroes pass_perc on warnings
            $stats{$test_nm}{pass_perc} = 0 if $warned{$test_nm};
            $count++;

            # If we have single iteration, no need to collect stats so write
            # per line to avoid losing them in case of SIG
            _print_stats($fh, \%stats, $args, $test_nm)
                if $args->{stats_output} && $repeat == 1;
            path($args->{_progress_file})->spew_utf8('')
                if $args->{_progress_file};
        }
    }

    if ($args->{stats_output}) {
        # Write all stats for many iterations
        _print_stats($fh, \%stats, $args) if $repeat > 1;
        _close_stats($fh, $args);
    }
    $args->{stats} = \%stats;
}

sub _warn_tracker {
    my $warned = shift;
    my $outer  = $SIG{__WARN__};

    return sub {
        $$warned = 1 if join('', @_) =~ /\S/;
        return $outer->(@_) if ref $outer eq 'CODE';
        print STDERR @_;
    };
}

sub _test_name {
    my $test = shift;
    my $root = shift;

    $test =~ s/^\Q$root\E// if $root;

    return $test;
}

sub _override {
    my $replace = shift;

    require Sub::Override;

    my $override = Sub::Override->new;
    $override->replace($_, $replace->{$_}) for (keys %{$replace});

    return $override;
}

sub _stats_fh {
    my $args = shift;

    return unless $args->{stats_output};

    my $fh;
    if ($args->{stats_output} =~ /^-$/) {
        $fh = *STDOUT
    } else {
        unless (-e $args->{stats_output}) {
            my @create = mkpath($args->{stats_output});
            unless (scalar @create) {
                warn "Could not create ".$args->{stats_output};
                return;
            }
        }
        my $file = $args->{stats_output}."/".$args->{caller}."-"._timestamp().".txt";
        open($fh, '>', $file) or die "Can't open > $file: $!";
    }
    select($fh); $| = 1; select(STDOUT);

    $args->{total_time} = 0;
    my $extra = $args->{extend_stats} ? ' TIMESTAMP' : '';
    print $fh "TIME PASS%$extra TEST\n" unless $args->{pass_only};

    return $fh;
}

sub _close_stats {
    my ($fh, $args) = @_;

    return unless $fh;

    printf $fh "TOTAL TIME: %.1f sec\n", $args->{total_time}
        unless $args->{pass_only};
    close $fh unless $args->{stats_output} =~ /^-$/;
}

sub _print_stats {
    my ($fh, $stats, $args, $test) = @_;

    return unless $fh;

    my @tests = $test ? $test : keys %$stats;
    my $extra = '';

    foreach my $test (sort {$stats->{$b}->{time}<=>$stats->{$a}->{time}} @tests) {
        if ($args->{pass_only}) {
            print $fh "$test\n" if $stats->{$test}->{pass_perc} > 99;
            next;
        }
        $extra = ' '.$stats->{$test}->{timestamp} if $args->{extend_stats};
        $args->{total_time} += $stats->{$test}->{time};
        printf $fh "%.2f %d$extra $test\n",
            $stats->{$test}->{time}, $stats->{$test}->{pass_perc};
    }
}

sub _uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub _timestamp {
    my ($s, $m, $h, $D, $M, $Y) = localtime(time);
    return sprintf "%04d%02d%02dT%02d%02d%02d", $Y+1900, $M+1, $D, $h, $m, $s;
}

=head1 HELPER SCRIPTS

=head2 agg (Test2::Aggregate harness wrapper)

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
 --root <s>          -r <s>  : Define a custom root dir.
 --include <s>,      -I <s>  : Library path to include (repeatable).
 --test_warnings,    -w      : Fail tests on warnings.
 --test_bundle <s>,  -t      : Test bundle (def: Test2::V0 or Test::More if -p). Comma-separated list.
 --pass_output <s>,  -po <s> : Output directory for list of 100% passing tests.
 --reverse                   : Reverse the test order.
 --shuffle                   : Shuffle the test order.
 --sort                      : Run the tests alphabetically.
 --stats_output <s>, -so <s> : Stats output directory (does not combine with pass_output).
 --help              -h      : Show basic help and exit.

=head2 aggit (Test2::Aggregate iterative aggregator)

 aggit [options] <file/dir1 ...>

Runs tests through an aggregate test repeatedly. On each failed run, the active
test file is removed and the remaining set is tried again. Requires
L<Test2::Plugin::BailOnFail>. Startup failures and failures after all test files
have completed abort the command with a nonzero exit status instead of removing
tests. This is a coarse way to discover a starting list of tests that can be
aggregated together, not proof that each removed test is independently broken.

 Options:
 --out <s>,          -o <s>  : Specify the test file to be created (tmp file by default).
 --lists,            -l      : Use files specified as lists.
 --prove,            -p      : Force prove (default is yath/Test2 if installed).
 --verbose,          -v      : Verbose (passed to yath/prove)
 --absolute,         -a      : Use absolute paths in generated files. Disabled with -r.
 --exclude_regex <s> -er <s> : Regex for test paths to exclude.
 --exclude_list <s>  -el <s> : File with test paths to exclude (one per line).
 --event_timeout <i> -et <i> : Event timeout for yath (to determine hung tests). Default 10.
 --root <s>          -r <s>  : Define a custom root dir (default is current dir).
 --include <s>,      -I <s>  : Library path to include (repeatable).
 --test_bundle <s>,  -t      : Test bundle (def: Test2::V0 or Test::More if -p). Comma-separated list.
 --reverse                   : Reverse the test order.
 --shuffle                   : Shuffle the test order.
 --sort                      : Run the tests alphabetically.
 --help              -h      : Show basic help and exit.

C<--sort>, C<--shuffle>, and C<--reverse> are applied once during discovery.
The resulting order is preserved across retries and in the generated runner.
By default, list entries are relative to the generated runner's directory;
C<--absolute> writes absolute paths. C<--root> resolves inputs against a custom
directory. C<--exclude_regex> and C<--exclude_list> filter the discovered tests.

C<aggit> passes C<--event_timeout SECONDS> (alias C<-et>, default 10) to
C<yath> as C<--et SECONDS>. This is an inactivity timeout, not a total runtime
limit; Harness normally defaults to 60 seconds. The timeout applies to the
generated aggregate runner, so C<# HARNESS-NO-TIMEOUT> comments in individual
aggregated files do not disable it. Under C<--prove>, or automatic fallback to
C<prove> when Harness is unavailable, this timeout is not provided and hung
tests require external supervision.

For C<agg>, C<--pass_output> takes precedence over C<--stats_output> when both
are supplied.

=head2 Common helper workflows

Try known-safe tests through the default L<Test2::Harness> runner:

 agg t/unit t/lib

Force C<prove> and L<Test::More> compatibility mode:

 agg --prove t/unit

Generate a directory containing a list of tests that passed when aggregated:

 agg --root . --pass_output pass t

C<--root .> makes the passing paths relative to the current project directory,
rather than the temporary aggregate runner's directory.

Iteratively discover an aggregateable list and generated aggregate test:

 aggit --out aggregate-candidate t

Run the generated aggregate test later (its list paths are runner-relative):

 yath test aggregate-candidate.t

=head1 USAGE NOTES

Not all tests can be modified to run under the aggregator, it is not intended
for tests that require an isolated environment, do overrides etc. For other tests
which can potentially run under the aggregator, sometimes very simple changes may be
needed like giving unique names to subs (or not warning for redefines, or trying the
package option), replacing things that complain, restoring the environment at
the end of the test etc.

Unit tests are usually great for aggregating. You could use the hash that C<run_tests>
returns in a script that tries to add more tests automatically to an aggregate list
to see which added tests passed and keep them, dropping failures. See later in the
notes for a detailed example.

Trying to aggregate too many tests into a single one can be counter-intuitive as
you would ideally want to parallelize your test suite (so a super-long aggregated
test continuing after the rest are done will slow down the suite). And in general
more tests will run aggregated if they are grouped so that tests that can't be
aggregated together are in different groups.

You can call C<Test2::Aggregate::run_tests> multiple times in a test. Nested calls
are skipped unless the inner call enables C<recursion>. Loading
L<Test2::Plugin::BailOnFail> through C<bail_on_fail> or C<repeat E<lt> 0> affects
subsequent tests too: a later failure will also trigger a bail-out.

=head2 Version 1.00 path compatibility

Stats keys and warning labels are root-relative by default in 1.00. Set
C<absolute> if you need the previous full rooted paths in stats output.

Relative test paths that do not start with C</>, C<.>, or C<./> are now executed
with a C<./> prefix so they keep working on perls where C<.> is not in C<@INC>.
Set C<no_dot> if you need the previous behaviour.

Nested aggregate runs are skipped by default when C<$ENV{AGGREGATE_TESTS}> is
already set. Set C<recursion> only for suites where nested aggregate execution is
intentional.

=head2 Test::More

If you haven't switched to the L<Test2::Suite> you are generally advised to do so
for a number of reasons, compatibility with this module being only a very minor
one. If you are stuck with a L<Test::More> suite, L<Test2::Aggregate> can still
probably help you more than the similarly-named C<Test::Aggregate...> modules.

Although the module tries to load C<Test2> with minimal imports to not interfere,
it is generally better to do C<use Test::More;> in your aggregating test (i.e.
alongside with C<use Test2::Aggregate>).

=head2 Test::Builder

To avoid warnings, if you are importing L<Test::Builder> in multiple aggregated
tests, you will want to import first on the aggregating test.
It might look like this:

 use Test::Builder;
 use Test2::V0;
 use Test2::Aggregate;

 Test2::Aggregate::run_tests( ... );

=head2 BEGIN / END Blocks

C<BEGIN> blocks run as each test file is compiled. C<END> blocks are deferred
until the aggregate process exits, not the end of each individual test file.
Cleanup needed between files must therefore happen before the file returns.
Global overrides can affect later tests. One example is a
C<*CORE::GLOBAL::exit> override to test scripts that can call C<exit()>.
A solution is to use something like L<Test::Trap>: 

 BEGIN {
     unless ($Test::Trap::VERSION) { # Avoid warnings for multiple loads in aggregation
         require Test::Trap;
         Test::Trap->import();
     }
 }

=head2 Test::Class

L<Test::Class> is sort of an aggregator itself. You make your tests into modules
and then load them on the same C<.t> file, so ideally you will not end up with many
C<.t> files that would require further aggregation. If you do, due to the L<Test::Class>
implementation specifics, those C<.t> files won't run under L<Test2::Aggregate>.

=head2 $0 variable

Remember the C<$0> variable is the aggregate runner, not the test file.

=head2 Mocks, CORE::GLOBAL::* Overrides

Always prefer mocks (Test2::Mock) instead of global built-ins where possible for
aggregated tests. Remember to clear mocks at the end of test.

=head2 $ENV{AGGREGATE_TESTS}

The environment variable C<AGGREGATE_TESTS> will be set while the tests are running
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

=head2 Example aggregating strategy

There are many approaches you could do to use C<Test2::Aggregate> with an existing
test suite, usually involving an iterative process of trying to run several tests
aggregated, seeing if you can fix the failing ones, otherwise you remove them from
the aggregation etc.

This process can be done with the help of the C<agg> script. For example, to try
all tests under C<t/> aggregated and a list of passing tests put under the C<pass>
directory you would do:

 > agg --root . --pass_output pass t

(which will use C<yath> & L<Test2::V0>, you can do
C<agg --prove --root . --pass_output pass t> for C<prove> & L<Test::More>)

If the run completes, thanks to C<--pass_output> you have a "starting point"
 i.e. a .txt list that can run under the aggregator with the C<lists> option:

 Test2::Aggregate::run_tests(
     lists => ['pass/name_of_file.txt']
 );

If the run does not complete (e.g. signal 11 on some test), try fewer tests by
choosing just a subdirectory. If that's not possible, you'll probably have to go
to the more manual method of getting a full list of your tests
(C<find t -name '*.t' E<gt> all.lst>) then trying to run parts of it, again with
the C<lists> option.

After you have a starting point, you can try see if there is an obvious reason some
tests fail and address it to add them back to the pass list. You can even try adding
back some of the failed tests that were not among the first to fail - test failures
can sometimes be cascading, so some might be passing if added back, or have small
issues you can address.

Try adding C<test_warnings =E<gt> 1> to C<run_tests> to fix warnings as well, unless
it is common for your tests to have C<STDERR> output.

In the end, you will end up with part of your tests aggregated in (multiple if you
want to run them in parallel) list files, with the rest of your tests to be run
non-aggregated.

You don't actually have to move and separate aggregated/non-aggregated files when
using lists, you can still have your entire suite run the aggregated tests once and
not repeat them along with the other, non-aggregated tests, by taking advantage of
the C<--exclude-list> option of the C<Test2::Harness>.

Hopefully your tests can run in parallel (C<prove/yath -j>), in which case you
would split your aggregated tests into multiple lists to have them run in parallel.
Here is an example of a wrapper around C<yath>, to easily handle multiple lists:

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

You would call it with something like C<--exclude-lists=t/aggregate/*.lst>, and
the tests listed will be excluded (you will have them running aggregated through
their own C<.t> files using L<Test2::Aggregate>).

=head1 WINDOWS SUPPORT

Only filesystems with the C</> separator are supported, simply because the author
does not expect Windows users (many test suites don't work under StrawberryPerl
etc). However, if you want Windows filesystems to be supported, it should be simple
enough as long as you are willing to help with testing - just ask.

=head1 DEVELOPMENT AND RELEASES

C<README.md> is generated from this module's POD using L<Pod::Markdown>.
Install author dependencies, then run:

 perl Makefile.PL
 make readme
 AUTHOR_TESTING=1 prove -Ilib xt/author xt/integration
 make disttest

C<make readme> refreshes the README. C<make distdir> (also used by C<make dist>
and C<make disttest>) refreshes it automatically before copying distribution
files. These author targets require L<Pod::Markdown>, but normal installation
and C<make test> do not. The README author test detects stale generated content;
review and commit README changes alongside the POD. Set the release date in
C<Changes> when preparing the final release.

=head1 AUTHOR

Dimitrios Kechagias, L<https://metacpan.org/author/DKECHAG>
 
=head1 BUGS

Please report any bugs or feature requests to C<bug-test2-aggregate at rt.cpan.org>,
or through the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test2-Aggregate>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes. You could also submit issues or even pull requests to the
github repo (see below).

=head1 GIT

L<https://github.com/SpareRoom/Test2-Aggregate>
 
=head1 COPYRIGHT & LICENSE

Copyright (C) 2019, SpareRoom.com

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
