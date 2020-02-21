package Test2::Aggregate;

use strict;
use warnings;

use File::Find;
use File::Path;
use File::Slurp;

use Test2::V0 'subtest';

=head1 NAME

Test2::Aggregate - Aggregate tests for increased speed

=head1 SYNOPSIS

    use Test2::Aggregate;

    Test2::Aggregate::run_tests(
        dirs => \@test_dirs
    );

    done_testing();

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 DESCRIPTION

Aggregates all tests specified with C<dirs> (which can even be individual tests)
to avoid forking, reloading etc that can help with performance (dramatically if
you have numerous small tests) and also facilitate group profiling.
Test files are expected to end in B<.t> and are run as subtests of a single
aggregate test.

A bit similar (mainly in intent) to L<Test::Aggregate>, but no inspiration was
drawn from the specific module, so simpler in concept and execution, which
makes it more likely to work with your test suite (especially if you use modern
tools like Test2). It does not even try to package each test by default, which may
be good or bad (e.g. redefines), depending on your requirements.

Generally, the way to use this module is to try to aggregate sets of quick tests
(e.g. unit tests). Try to iterativelly add tests to the aggregator, dropping those
that do not work. Trying an entire suite in one go is a bad idea, an incompatible
test can break the run failing all the subsequent tests (especially when doing
things like globally redefining built-ins etc). The module can usually work with
L<Test::More> suites, but will have more issues than when you use the more modern
L<Test2::Suite> (see notes).

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
        override      => \%override,          # optional, requires Sub::Override
        stats_output  => $stats_output_path,  # optional
        extend_stats  => 0,                   # optional
        test_warnings => 0,                   # optional
        pre_eval      => $code_to_eval,       # optional
        dry_run       => 0                    # optional
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
paths inside the list files). If the path does not exist, it will be silently
ignored, however the "official" way to skip a line without checking it as a path
is to start with a C<#> to denote a comment.

=item * C<exclude> (optional)

A regex to filter out tests that you want excluded.

=item * C<include> (optional)

A regex which the tests have to match in order to be included in the test run.
Applied after C<exclude>.

=item * C<root> (optional)

If defined, must be a valid root directory that will prefix all C<dirs> and
C<lists> items. You may want to set it to C<'./'> if you want dirs relative
to the current directory and the dot is not in your C<@INC>.

=item * C<load_modules> (optional)

Arrayref with modules to be loaded (with C<eval "use ...">) at the start of the
test. Useful for testing modules with special namespace requirements.

=item * C<package> (optional)

Will package each test in its own namespace. While it may help avoid things like
redefine warnings, from experience it doesn't often prove helpful (it may break
tests when aggregating them), so it is disabled by default.

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

=item * C<dry_run> (optional)

Instead of running the tests, will do C<ok($testname)> for each one. Otherwise,
test order, stats files etc. will be produced (as if all tests passed).

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
Output is sorted from slowest test to fastest. On negative C<repeat> the stats
of each successful run will be written separately instead of the averages.
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

- starting date/time in ISO_8601.

=back

=back

=cut

sub run_tests {
    my %args = @_;
    Test2::V0::plan skip_all => 'Skipping slow tests.'
        if $args{slow} && $ENV{SKIP_SLOW};

    eval "use $_;" foreach @{$args{load_modules}};
    local $ENV{AGGREGATE_TESTS} = 1;

    my $override = $args{override} ? _override($args{override}) : undef;
    my @dirs     = ();
    my $root     = $args{root} || '';
    my @tests;

    @dirs = @{$args{dirs}} if $args{dirs};
    $root .= '/' unless !$root || $root =~ m#/$#;

    if ($root && ! -e $root) {
        warn "Root '$root' does not exist, no tests are loaded."
    } else {
        foreach my $file (@{$args{lists}}) {
            push @dirs,
              map { /^\s*#/ ? () : $_ }
              split( /\r?\n/, read_file("$root$file") );
        }

        find(
            sub {push @tests, $File::Find::name if /\.t$/},
            grep {-e} map {$root . $_} @dirs
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
    if ($args{repeat} < 0) {
        eval 'use Test2::Plugin::BailOnFail';
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

sub _process_run_order {
    my $tests = shift;
    my $args  = shift;

    @$tests = grep(!/$args->{exclude}/, @$tests) if $args->{exclude};
    @$tests = grep(/$args->{include}/, @$tests) if $args->{include};

    @$tests = _uniq(@$tests)  if $args->{unique};
    @$tests = reverse @$tests if $args->{reverse};

    if ($args->{shuffle}) {
        require List::Util;
        @$tests = List::Util::shuffle @$tests;
    } elsif ($args->{sort}) {
        @$tests = sort @$tests;
    }
}

sub _process_warnings {
    my $warnings = shift;
    my $args     = shift;
    my @warnings = split(/<-Test2::Aggregate\n/, join('',@$warnings));
    my @clean    = ();

    foreach my $warn (@warnings) {
        if ($warn =~ m/(.*)->Test2::Aggregate\n(.*\S.*)/) {
            push @clean, "<$1>\n$2";
            $args->{stats}->{$1}->{warnings} = $2;
            $args->{stats}->{$1}->{pass_perc} = 0;
        }
    }
    return \@clean;
}

sub _run_tests {
    my $tests  = shift;
    my $args   = shift;

    my $repeat = $args->{repeat};
    $repeat = 1 if $repeat < 0;
    my (%stats, $start);

    require Time::HiRes if $args->{stats_output};

    for my $i (1 .. $repeat) {
        my $iter = $repeat > 1 ? "Iter: $i/$repeat - " : '';
        my $count = 1;
        foreach my $test (@$tests) {

            warn "$test->Test2::Aggregate\n" if $args->{test_warnings};

            $stats{$test}{test_no} = $count unless $stats{$test}{test_no};
            $start = Time::HiRes::time() if $args->{stats_output};
            $stats{$test}{timestamp} = _timestamp();

            my $result = subtest $iter. "Running test $test" => sub {
                eval $args->{pre_eval} if $args->{pre_eval};

                $args->{dry_run} ? Test2::V0::ok($test)
                  : $args->{package}
                  ? eval "package Test::$i" . '::' . "$count; do '$test';"
                  : do $test;
            };

            warn "<-Test2::Aggregate\n" if $args->{test_warnings};

            $stats{$test}{time} += (Time::HiRes::time() - $start)/$repeat
                if $args->{stats_output};
            $stats{$test}{pass_perc} += $result ? 100/$repeat : 0;
            $count++;
        }
    }

    _print_stats(\%stats, $args) if $args->{stats_output};
    $args->{stats} = \%stats;
}

sub _override {
    my $replace = shift;

    require Sub::Override;

    my $override = Sub::Override->new;
    $override->replace($_, $replace->{$_}) for (keys %{$replace});

    return $override;
}

sub _print_stats {
    my ($stats, $args) = @_;

    unless (-e $args->{stats_output}) {
        my @create = mkpath($args->{stats_output});
        unless (scalar @create) {
            warn "Could not create ".$args->{stats_output};
            return;
        }
    }

    my $fh;
    if ($args->{stats_output} =~ /^-$/) {
        $fh = *STDOUT
    } else {
        my $file = $args->{stats_output}."/".$args->{caller}."-"._timestamp().".txt";
        open($fh, '>', $file) or die "Can't open > $file: $!";
    }

    my $total = 0;
    my $extra = $args->{extend_stats} ? ' TIMESTAMP' : '';
    print $fh "TIME PASS%$extra TEST\n";

    foreach my $test (sort {$stats->{$b}->{time}<=>$stats->{$a}->{time}} keys %$stats) {
        $extra = ' '.$stats->{$test}->{timestamp} if $args->{extend_stats};
        $total += $stats->{$test}->{time};
        printf $fh "%.2f %d$extra $test\n",
            $stats->{$test}->{time}, $stats->{$test}->{pass_perc};
    }

    printf $fh "TOTAL TIME: %.1f sec\n", $total;
    close $fh unless $args->{stats_output} =~ /^-$/;
}

sub _uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub _timestamp {
    my ($s, $m, $h, $D, $M, $Y) = localtime(time);
    return sprintf "%04d%02d%02dT%02d%02d%02d", $Y+1900, $M+1, $D, $h, $m, $s;
}

=head1 USAGE NOTES

Not all tests can be modified to run under the aggregator, it is not intended
for tests that require an isolated environment, do overrides etc. For other tests
which can potentially run under the aggregator, sometimes very simple changes may be
needed like giving unique names to subs (or not warning for redefines, or trying the
package option), replacing things that complain, restoring the environment at
the end of the test etc.

Unit tests are usually great for aggregating. You could use the hash that C<run_tests>
returns in a script that tries to add more tests automatically to an aggregate list
to see which added tests passed and keep them, dropping failures.

Trying to aggregate too many tests into a single one can be counter-intuitive as
you would ideally want to parallelize your test suite (so a super-long aggregated
test continuing after the rest are done will slow down the suite). And in general
more tests will run aggregated if they are grouped so that tests that can't be
aggregated together are in different groups.

In general you can call C<Test2::Aggregate::run_tests> multiple times in a test and
even load C<run_tests> with tests that already contain another C<run_tests>, the
only real issue with multiple calls is that if you use C<repeat < 0> on a call,
L<Test2::Plugin::BailOnFail> is loaded so any subsequent failure, on any following
C<run_tests> call will trigger a Bail.

=head2 Test::More

If you haven't switched to the L<Test2::Suite> you are generally advised to do so
for a number of reasons, compatibility with this module being only a very minor
one. If you are stuck with a L<Test::More> suite, L<Test2::Aggregate> can still
probably help you more than the similarly-named C<Test::Aggregate...> modules.

Although the module tries to load C<Test2> with minimal imports to not interfere,
it is generally better to do C<use Test::More;> in your aggregating test (i.e.
alongside with C<use Test2::Aggregate>).

One more caveat is that C<Test2::Aggregate::run_tests> uses C<subtest> from the
L<Test2::Suite>, which on rare occasions can return a true value when a L<Test::More>
subtest fails by running no tests, so you could have a failed test show up as
having a 100 C<pass_perc> in the C<Test2::Aggregate::run_tests> output.

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

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>
 
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
