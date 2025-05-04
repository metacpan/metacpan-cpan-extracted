package App::Yath::Command::replay;
use strict;
use warnings;

our $VERSION = '2.000005';

use Test2::Harness::Util::File::JSONL;

use parent 'App::Yath::Command::run';
use Test2::Harness::Util::HashBase qw{
    +renderers
    <final_data
    <log_file
    <tests_seen
    <asserts_seen
};

use Getopt::Yath;

include_options(
    'App::Yath::Options::Renderer',
);

include_options(
    'App::Yath::Options::Renderer',
);

option_group {group => 'run', category => "Run Options"} => sub {
    option run_auditor => (
        type => 'Scalar',
        default => 'Test2::Harness::Collector::Auditor::Run',
        normalize => sub { fqmod($_[0], 'Test2::Harness::Collector::Auditor::Run') },
        description => 'Auditor class to use when auditing the overall test run',
    );
};

sub load_renderers     { 1 }
sub load_plugins       { 0 }
sub load_resources     { 0 }
sub args_include_tests { 0 }

sub group { 'log parsing' }

sub summary { "Replay a test run from an event log" }

sub cli_args { "[--] event_log.jsonl[.gz|.bz2] [job1, job2, ...]" }

sub description {
    return <<"    EOT";
This yath command will re-run the harness against an event log produced by a
previous test run. The only required argument is the path to the log file,
which maybe compressed. Any extra arguments are assumed to be job id's. If you
list any jobs, only listed jobs will be processed.

This command accepts all the same renderer/formatter options that the 'test'
command accepts.
    EOT
}

sub run {
    my $self = shift;

    my $args     = $self->args;
    my $settings = $self->settings;

    shift @$args if @$args && $args->[0] eq '--';

    $self->{+LOG_FILE} = shift @$args or die "You must specify a log file";
    die "'$self->{+LOG_FILE}' is not a valid log file" unless -f $self->{+LOG_FILE};
    die "'$self->{+LOG_FILE}' does not look like a log file" unless $self->{+LOG_FILE} =~ m/\.jsonl(\.(gz|bz2))?$/;

    my $stream = Test2::Harness::Util::File::JSONL->new(name => $self->{+LOG_FILE});
    while (1) {
        my ($e) = $stream->poll(max => 1);
        die "Could not find run_id in log.\n" unless $e;

        my $run_id = Test2::Harness::Event->new($e)->run_id or next;

        $settings->run->create_option(run_id => $run_id);
        last;
    }

    # Reset the stream
    $stream = Test2::Harness::Util::File::JSONL->new(name => $self->{+LOG_FILE});

    $self->start_plugins_and_renderers();

    my $jobs = @$args ? {map {$_ => 1} @$args} : undef;

    while (1) {
        my @events = $stream->poll(max => 1000) or last;

        for my $e (@events) {
            last unless defined $e;

            if ($jobs) {
                my $f = $e->{facet_data}->{harness_job_start} // $e->{facet_data}->{harness_job_queued};
                if ($f && !$jobs->{$e->{job_id}}) {
                    for my $field (qw/rel_file abs_file file/) {
                        my $file = $f->{$field} or next;
                        next unless $jobs->{$file};
                        $jobs->{$e->{job_id}} = 1;
                        last;
                    }
                }

                next unless $jobs->{$e->{job_id}};
            }

            $self->handle_event($e);
        }
    }

    my $exit = $self->stop_plugins_and_renderers();
    return $exit;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::replay - Replay a test run from an event log

=head1 DESCRIPTION

This yath command will re-run the harness against an event log produced by a
previous test run. The only required argument is the path to the log file,
which maybe compressed. Any extra arguments are assumed to be job id's. If you
list any jobs, only listed jobs will be processed.

This command accepts all the same renderer/formatter options that the 'test'
command accepts.


=head1 USAGE

    $ yath [YATH OPTIONS] replay [COMMAND OPTIONS] [COMMAND ARGUMENTS]

=head2 OPTIONS

=head3 Renderer Options

=over 4

=item --hide-runner-output

=item --no-hide-runner-output

Hide output from the runner, showing only test output. (See Also truncate_runner_output)


=item -q

=item --quiet

=item --no-quiet

Be very quiet.


=item --qvf

=item --no-qvf

Replaces App::Yath::Theme::Default with App::Yath::Theme::QVF which is quiet for passing tests and verbose for failing ones.


=item --renderer +My::Renderer

=item --renderers +My::Renderer

=item --renderer MyRenderer=opt1,opt2

=item --renderers MyRenderer=opt1,opt2

=item --renderer MyRenderer,MyOtherRenderer

=item --renderers MyRenderer,MyOtherRenderer

=item --renderer=:{ MyRenderer opt1,opt2,... }:

=item --renderers=:{ MyRenderer opt1,opt2,... }:

=item --renderer :{ MyRenderer :{ opt1 opt2 }: }:

=item --renderers :{ MyRenderer :{ opt1 opt2 }: }:

=item --no-renderers

Specify renderers. Use "+" to give a fully qualified module name. Without "+" "App::Yath::Renderer::" will be prepended to your argument.

Note: Can be specified multiple times


=item --server

=item --server=ARG

=item --no-server

Start an ephemeral yath database and web server to view results


=item --show-job-end

=item --no-show-job-end

Show output when a job ends. (Default: on)


=item --show-job-info

=item --no-show-job-info

Show the job configuration when a job starts. (Default: off, unless -vv)


=item --show-job-launch

=item --no-show-job-launch

Show output for the start of a job. (Default: off unless -v)


=item --show-run-fields

=item --no-show-run-fields

Show run fields. (Default: off, unless -vv)


=item --show-run-info

=item --no-show-run-info

Show the run configuration when a run starts. (Default: off, unless -vv)


=item -T

=item --show-times

=item --no-show-times

Show the timing data for each job.


=item -tARG

=item -t ARG

=item -t=ARG

=item --theme ARG

=item --theme=ARG

=item --no-theme

Select a theme for the renderer (not all renderers use this)


=item --truncate-runner-output

=item --no-truncate-runner-output

Only show runner output that was generated after the current command. This is only useful with a persistent runner.


=item -v

=item -vv

=item -vvv..

=item -v=COUNT

=item --verbose

=item --verbose=COUNT

=item --no-verbose

Be more verbose

The following environment variables will be set after arguments are processed: C<T2_HARNESS_IS_VERBOSE>, C<HARNESS_IS_VERBOSE>

Note: Can be specified multiple times, counter bumps each time it is used.


=item --wrap

=item --no-wrap

When active (default) renderers should try to wrap text in a human-friendly way. When this is turned off they should just throw text at the terminal.


=back

=head3 Run Options

=over 4

=item --run-auditor ARG

=item --run-auditor=ARG

=item --no-run-auditor

Auditor class to use when auditing the overall test run


=back

=head3 Terminal Options

=over 4

=item -c

=item --color

=item --no-color

Turn color on, default is true if STDOUT is a TTY.

Can also be set with the following environment variables: C<YATH_COLOR>, C<CLICOLOR_FORCE>

The following environment variables will be set after arguments are processed: C<YATH_COLOR>


=item --progress

=item --no-progress

Toggle progress indicators. On by default if STDOUT is a TTY. You can use --no-progress to disable the 'events seen' counter and buffered event pre-display


=item --term-size 80

=item --term-width 80

=item --term-size 200

=item --term-width 200

=item --no-term-width

Alternative to setting $TABLE_TERM_SIZE. Setting this will override the terminal width detection to the number of characters specified.

Can also be set with the following environment variables: C<TABLE_TERM_SIZE>

The following environment variables will be set after arguments are processed: C<TABLE_TERM_SIZE>


=back


=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

