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

Version 0.05

=cut

our $VERSION = '0.05';


=head1 DESCRIPTION

Aggregates all tests specified in C<dirs> (which can even be individual tests), 
to avoid forking, reloading etc that can help with performance or profiling.
Test files are expected to end in B<.t> and are run as subtests of a single
aggregate test.

A bit similar but simpler in concept and execution than C<Test::Aggregate>,
which makes it more likely to work with your test suite and also with more
modern Test2 bundles. It does not try to package each test which may be good or
bad (e.g. redefines), depending on your requirements.

=head1 METHODS
 
=head2 C<run_tests>

    Test2::Aggregate::run_tests(
        dirs          => \@dirs,              # optional if lists defined
        lists         => \@lists,             # optional if dirs defined
        root          => '/testroot/',        # optional
        load_modules  => \@modules,           # optional
        shuffle       => 0,                   # optional
        reverse       => 0,                   # optional
        repeat        => 1,                   # optional, requires Test2::Plugin::BailOnFail for < 0
        slow          => 0,                   # optional
        override      => \%override,          # optional, requires Sub::Override
        stats_output  => $stats_output_path,  # optional, requires Time::HiRes
        test_warnings => 0                    # optional
    );

Runs the aggregate tests. Hash parameter specifies:

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

Tests for warnings over all the tests if set to true. It will print an array of
warnings, however if you want to see the warnings the moment they are generated
(for debugging etc), then leave it disabled.

=item * C<stats_output_path> (optional)

C<stats_output_path> when defined specifies a path where a file with running
time per test (average if multiple iterations are specified), starting with the
slowest test and passing percentage gets written. On negative C<repeat> the
stats of each successful run will be written separately instead of the averages.
The name of the file is C<caller_script-YYYYMMDD_HHmmss.txt>.
If C<-> is passed instead of a path, then STDOUT will be used instead.
The timing stats are useful because the test harness doesn not normally measure
type by subtest.

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

    my $warnings=[];
    if ($args{repeat} && $args{repeat} < 0) {
        require Test2::Plugin::BailOnFail;
        my $iter = 0;
        while (!@$warnings) {
            $iter++;
            print "Test suite iteration $iter\n";
            if ($args{test_warnings}) {
                $warnings = Test2::V0::warnings{_run_tests(\@tests, \%args)};
            } else {
                _run_tests(\@tests, \%args);
            }
        }
    } elsif ($args{test_warnings}) {
        $warnings = Test2::V0::warnings { _run_tests(\@tests, \%args) };
        Test2::V0::is(
            @$warnings,
            0,
            'No warnings in the aggregate tests.'
        );
    } else {
        _run_tests(\@tests, \%args);
    }
    warn "Test warning output:\n".join("\n", @$warnings)."\n" if @$warnings;
}

sub _run_tests {
    my $tests  = shift;
    my $args   = shift;
    my $repeat = $args->{repeat} || 1;
    $repeat = 1 if $repeat < 0;
    my %stats;

    require Time::HiRes if $args->{stats_output};

    for (1 .. $repeat) {
        my $iter = $repeat > 1 ? "Iter: $_/$repeat - " : '';
        foreach my $test (@$tests) {
            my $start  = Time::HiRes::time() if $args->{stats_output};
            my $result = subtest $iter. "Running test $test" => sub {
                do $test;
            };
            $stats{time}{$test} += (Time::HiRes::time() - $start)/$repeat
                 if $args->{stats_output};
            $stats{pass_perc}{$test} += $result ? 100/$repeat : 0;
        }
    }

    _print_stats(\%stats, $args) if $args->{stats_output};
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

    print $fh "TIME PASS% TEST\n";
    my $total = 0;
    foreach my $test (sort {$stats->{time}->{$b}<=>$stats->{time}->{$a}} keys %{$stats->{time}}) {
        $total += $stats->{time}->{$test};
        printf $fh "%.2f %d $test\n",
            $stats->{time}->{$test}, $stats->{pass_perc}->{$test};
    }
    printf $fh "TOTAL TIME: %.1f sec\n", $total;
    close $fh unless $args->{stats_output} =~ /^-$/;
}

sub _timestamp {
    my ($s, $m, $h, $D, $M, $Y) = localtime(time);
    return sprintf "%04d%02d%02d_%02d%02d%02d", $Y+1900, $M+1, $D, $h, $m, $s;
}

=head1 USAGE NOTES

Not all tests can be modified to run under the aggregator, it is not intended
for tests that require an isolated environment. So, for those that do not and
can potentially run under the aggregator, sometimes very simple changes might be
needed like giving unique names to subs (or not warning for redefines), replacing
things that complain, restoring the environment at the end of the test etc.

The environment variable C<AGGREGATE_TESTS> will be set while the tests are
running. Example usage is a module that can only be loaded once, so you load it
on the aggregated test file and then use something like this in the individual
test files:

 eval 'use My::Module' unless $ENV{AGGREGATE_TESTS};

Trying to aggregate too many tests into a single one can be counter-intuitive as
you would ideally want to parallelize your test suite (so a super-long test
continuing after the rest are done will slow down the suite). And in general
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
