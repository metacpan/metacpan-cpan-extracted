package Test2::Aggregate;

use strict;
use warnings;

use File::Find;
use File::Path;
use File::Slurp;

use Test2::V0 'subtest';

=head1 NAME

Test2::Aggregate - Aggregate tests

=head1 SYNOPSIS

    use Test2::Aggregate;

    Test2::Aggregate::run_tests(
        dirs => \@test_dirs
    );

    done_testing();

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 DESCRIPTION

Aggregates all tests specified in C<dirs> (which can even be individual tests), 
to avoid forking, reloading etc that can help with performance (dramatically if
you have numerous small tests) and also facilitate group profiling.
Test files are expected to end in B<.t> and are run as subtests of a single
aggregate test.

A bit similar, but simpler in concept and execution to C<Test::Aggregate>, which
makes it more likely to work with your test suite (especially if you use modern
tools like Test2). It does not even try to package each test by default, which may
be good or bad (e.g. redefines), depending on your requirements.

Generally, the way to use this module is to try to aggregate sets of quick tests
(e.g. unit tests). Try to iterativelly add tests to the aggregator dropping those
that do not work.

=head1 METHODS
 
=head2 C<run_tests>

    my $stats = Test2::Aggregate::run_tests(
        dirs          => \@dirs,              # optional if lists defined
        lists         => \@lists,             # optional if dirs defined
        root          => '/testroot/',        # optional
        load_modules  => \@modules,           # optional
        package       => 0,                   # optional
        shuffle       => 0,                   # optional
        reverse       => 0,                   # optional
        repeat        => 1,                   # optional, requires Test2::Plugin::BailOnFail for < 0
        slow          => 0,                   # optional
        override      => \%override,          # optional, requires Sub::Override
        stats_output  => $stats_output_path,  # optional
        extend_stats  => 0,                   # optional
        test_warnings => 0                    # optional
    );

Runs the aggregate tests. Returns a hashref with stats like this:

  $stats = {
    'test.t' => {
      'test_no'   => 1,                 # numbering starts at 1
      'pass_perc' => 100,               # for single runs pass/fail is 100/0
      'timestamp' => '20190705T145043', # start of test
      'time'      => '0.1732',          # only with stats_output
      'warnings'  => $STDERR            # only with test_warnings on non empty STDERR
    }
  };

The parameters to pass:

=over 4
 
=item * C<dirs> (either this or C<lists> is required)

An arrayref containing directories which will be searched recursively,
or even individual tests. The directories (unless C<shuffle> or C<reverse> are
true) will be processed and tests run in order specified.

=item * C<lists> (either this or C<dirs> is required)

Arrayref of flat files from which each line will be pushed to C<dirs>
(so they have a lower precedence - note C<root> still applies).

=item * C<root> (optional)

If defined, must be a valid root directory that will prefix all C<dirs> and
C<lists> items. You may want to set it to C<'./'> if you want dirs relative
to the current directory and the dot is not in your C<@INC>.

=item * C<load_modules> (optional)

Arrayref with modules to be loaded (with C<eval "use ...">) at the start of the
test. Useful for testing modules with special namespace requirements.

=item * C<package> (optional)

Will package each test in its own namespace (no redefine warnings etc).

=item * C<override> (optional)

Pass C<Sub::Override> key/values as a hashref.

=item * C<repeat> (optional)

Number of times to repeat the test(s) (default is 1 for a single run). If
C<repeat> is negative, the tests will repeat until they fail (or produce a
warning if C<test_warnings> is also set).

=item * C<shuffle> (optional)

Random order of tests if set to true.

=item * C<reverse> (optional)

Reverse order of tests if set to true.

=item * C<slow> (optional)

When true, tests will be skipped if the environment variable C<SKIP_SLOW> is set.

=item * C<test_warnings> (optional)

Tests for warnings over all the tests if set to true - this is added as a final
test which expects zero as the number of tests which had STDERR output.
The STDERR output of each test will be printed at the end of the test run (and
included in the test run result hash), so if you want to see warnings the moment
they are generated (for debugging etc), then leave this option disabled.

=item * C<stats_output_path> (optional)

C<stats_output_path> when defined specifies a path where a file with running
time per test (average if multiple iterations are specified), starting with the
slowest test and passing percentage gets written. On negative C<repeat> the
stats of each successful run will be written separately instead of the averages.
The name of the file is C<caller_script-YYYYMMDDTHHmmss.txt>.
If C<-> is passed instead of a path, then STDOUT will be used instead.
The timing stats are useful because the test harness doesn't normally measure
time per subtest.

=item * C<extend_stats> (optional)

This option is to allow for the default output of C<stats_output_path> to be
fixed/reliable and anything added in future versions will only be written when
C<extend_stats> is enabled.
Currently starting date/time in ISO_8601 is added when the extend option is set.

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
            push @dirs, split(/\r?\n/, read_file("$root$file"));
        }

        find(
            sub {push @tests, $File::Find::name if /\.t$/},
            grep {-e} map {$root . $_} @dirs
        )
            if @dirs;
    }

    @tests = reverse @tests if $args{reverse};

    if ($args{shuffle}) {
        require List::Util;
        @tests = List::Util::shuffle @tests;
    }

    my @stack = caller();
    $args{caller} = $stack[1] || 'aggregate';
    $args{caller} =~ s#^.*?([^/]+)$#$1#;
    $args{repeat} ||= 1;

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
    my %stats;

    require Time::HiRes if $args->{stats_output};

    for my $i (1 .. $repeat) {
        my $iter = $repeat > 1 ? "Iter: $i/$repeat - " : '';
        my $count = 0;
        foreach my $test (@$tests) {
            my $start;

            warn "$test->Test2::Aggregate\n" if $args->{test_warnings};

            $stats{$test}{test_no}=++$count;
            $start = Time::HiRes::time() if $args->{stats_output};
            $stats{$test}{timestamp} = _timestamp();

            my $result = subtest $iter. "Running test $test" => sub {
                eval "package Test.$i.$count;" if $args->{package};
                do $test;
            };

            warn "<-Test2::Aggregate\n" if $args->{test_warnings};

            $stats{$test}{time} += (Time::HiRes::time() - $start)/$repeat
                if $args->{stats_output};
            $stats{$test}{pass_perc} += $result ? 100/$repeat : 0;
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

The environment variable C<AGGREGATE_TESTS> will be set while the tests are running
for your convenience. Example usage is a module that can only be loaded once, so
you load it on the aggregated test file and then use something like this in the
individual test files:

 eval 'use My::Module' unless $ENV{AGGREGATE_TESTS};

Trying to aggregate too many tests into a single one can be counter-intuitive as
you would ideally want to parallelize your test suite (so a super-long aggregated
test continuing after the rest are done will slow down the suite). And in general
more tests will run aggregated if they are grouped so that tests that can't be
aggregated together are in different groups.

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>
 
=head1 BUGS

Please report any bugs or feature requests to C<bug-test2-aggregate at rt.cpan.org>,
or through the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test2-Aggregate>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 GIT

L<https://github.com/SpareRoom/Test2-Aggregate>
 
=head1 COPYRIGHT & LICENSE

Copyright (C) 2019, SpareRoom.com

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
