package App::Yath::Command::replay;
use strict;
use warnings;

our $VERSION = '1.000155';

use App::Yath::Options;
require App::Yath::Command::test;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw/+renderers <final_data <log_file <tests_seen <asserts_seen/;

include_options(
    'App::Yath::Options::Debug',
    'App::Yath::Options::Display',
    'App::Yath::Options::PreCommand',
);


sub group { 'log' }

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

sub init {
    my $self = shift;
    $self->SUPER::init() if $self->can('SUPER::init');

    $self->{+TESTS_SEEN}   //= 0;
    $self->{+ASSERTS_SEEN} //= 0;
}

sub run {
    my $self = shift;

    my $args      = $self->args;
    my $settings  = $self->settings;
    my $renderers = $self->App::Yath::Command::test::renderers;

    shift @$args if @$args && $args->[0] eq '--';

    $self->{+LOG_FILE} = shift @$args or die "You must specify a log file";
    die "'$self->{+LOG_FILE}' is not a valid log file" unless -f $self->{+LOG_FILE};
    die "'$self->{+LOG_FILE}' does not look like a log file" unless $self->{+LOG_FILE} =~ m/\.jsonl(\.(gz|bz2))?$/;

    my $jobs = @$args ? {map {$_ => 1} @$args} : undef;

    my $stream = Test2::Harness::Util::File::JSONL->new(name => $self->{+LOG_FILE});

    while (1) {
        my @events = $stream->poll(max => 1000) or last;

        for my $e (@events) {
            last unless defined $e;

            $self->{+TESTS_SEEN}++   if $e->{facet_data}->{harness_job_launch};
            $self->{+ASSERTS_SEEN}++ if $e->{facet_data}->{assert};

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
            }

            if (my $final = $e->{facet_data}->{harness_final}) {
                $self->{+FINAL_DATA} = $final;
            }
            else {
                next if $jobs && !$jobs->{$e->{job_id}};
                $_->render_event($e) for @$renderers;
            }
        }
    }

    $_->finish() for @$renderers;

    my $final_data = $self->{+FINAL_DATA} or die "Log did not contain final data!\n";

    $self->App::Yath::Command::test::render_final_data($final_data);
    $self->App::Yath::Command::test::render_summary($final_data->{pass});

    return $final_data->{pass} ? 0 : 1;
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

    $ yath [YATH OPTIONS] replay [COMMAND OPTIONS]

=head2 YATH OPTIONS

=head3 Developer

=over 4

=item --dev-lib

=item --dev-lib=lib

=item -D

=item -D=lib

=item -Dlib

=item --no-dev-lib

Add paths to @INC before loading ANYTHING. This is what you use if you are developing yath or yath plugins to make sure the yath script finds the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.

Can be specified multiple times


=back

=head3 Environment

=over 4

=item --persist-dir ARG

=item --persist-dir=ARG

=item --no-persist-dir

Where to find persistence files.


=item --persist-file ARG

=item --persist-file=ARG

=item --pfile ARG

=item --pfile=ARG

=item --no-persist-file

Where to find the persistence file. The default is /{system-tempdir}/project-yath-persist.json. If no project is specified then it will fall back to the current directory. If the current directory is not writable it will default to /tmp/yath-persist.json which limits you to one persistent runner on your system.


=item --project ARG

=item --project=ARG

=item --project-name ARG

=item --project-name=ARG

=item --no-project

This lets you provide a label for your current project/codebase. This is best used in a .yath.rc file. This is necessary for a persistent runner.


=back

=head3 Help and Debugging

=over 4

=item --show-opts

=item --no-show-opts

Exit after showing what yath thinks your options mean


=item --version

=item -V

=item --no-version

Exit after showing a helpful usage message


=back

=head3 Plugins

=over 4

=item --no-scan-plugins

=item --no-no-scan-plugins

Normally yath scans for and loads all App::Yath::Plugin::* modules in order to bring in command-line options they may provide. This flag will disable that. This is useful if you have a naughty plugin that is loading other modules when it should not.


=item --plugins PLUGIN

=item --plugins +App::Yath::Plugin::PLUGIN

=item --plugins PLUGIN=arg1,arg2,...

=item --plugin PLUGIN

=item --plugin +App::Yath::Plugin::PLUGIN

=item --plugin PLUGIN=arg1,arg2,...

=item -pPLUGIN

=item --no-plugins

Load a yath plugin.

Can be specified multiple times


=back

=head2 COMMAND OPTIONS

=head3 Cover Options

=over 4

=item --cover-aggregator ByTest

=item --cover-aggregator ByRun

=item --cover-aggregator +Custom::Aggregator

=item --cover-agg ByTest

=item --cover-agg ByRun

=item --cover-agg +Custom::Aggregator

=item --no-cover-aggregator

Choose a custom aggregator subclass


=item --cover-class ARG

=item --cover-class=ARG

=item --no-cover-class

Choose a Test2::Plugin::Cover subclass


=item --cover-dirs ARG

=item --cover-dirs=ARG

=item --cover-dir ARG

=item --cover-dir=ARG

=item --no-cover-dirs

NO DESCRIPTION - FIX ME

Can be specified multiple times


=item --cover-exclude-private

=item --no-cover-exclude-private




=item --cover-files

=item --no-cover-files

Use Test2::Plugin::Cover to collect coverage data for what files are touched by what tests. Unlike Devel::Cover this has very little performance impact (About 4% difference)


=item --cover-from path/to/log.jsonl

=item --cover-from http://example.com/coverage

=item --cover-from path/to/coverage.jsonl

=item --no-cover-from

This can be a test log, a coverage dump (old style json or new jsonl format), or a url to any of the previous. Tests will not be run if the file/url is invalid.


=item --cover-from-type json

=item --cover-from-type jsonl

=item --cover-from-type log

=item --no-cover-from-type

File type for coverage source. Usually it can be detected, but when it cannot be you should specify. "json" is old style single-blob coverage data, "jsonl" is the new by-test style, "log" is a logfile from a previous run.


=item --cover-manager My::Coverage::Manager

=item --no-cover-manager

Coverage 'from' manager to use when coverage data does not provide one


=item --cover-maybe-from path/to/log.jsonl

=item --cover-maybe-from http://example.com/coverage

=item --cover-maybe-from path/to/coverage.jsonl

=item --no-cover-maybe-from

This can be a test log, a coverage dump (old style json or new jsonl format), or a url to any of the previous. Tests will coninue if even if the coverage file/url is invalid.


=item --cover-maybe-from-type json

=item --cover-maybe-from-type jsonl

=item --cover-maybe-from-type log

=item --no-cover-maybe-from-type

Same as "from_type" but for "maybe_from". Defaults to "from_type" if that is specified, otherwise auto-detect


=item --cover-metrics

=item --no-cover-metrics




=item --cover-types ARG

=item --cover-types=ARG

=item --cover-type ARG

=item --cover-type=ARG

=item --no-cover-types

NO DESCRIPTION - FIX ME

Can be specified multiple times


=item --cover-write

=item --cover-write=coverage.jsonl

=item --cover-write=coverage.json

=item --no-cover-write

Create a json or jsonl file of all coverage data seen during the run (This implies --cover-files).


=back

=head3 Display Options

=over 4

=item --color

=item --no-color

Turn color on, default is true if STDOUT is a TTY.


=item --hide-runner-output

=item --no-hide-runner-output

Hide output from the runner, showing only test output. (See Also truncate_runner_output)


=item --no-wrap

=item --no-no-wrap

Do not do fancy text-wrapping, let the terminal handle it


=item --progress

=item --no-progress

Toggle progress indicators. On by default if STDOUT is a TTY. You can use --no-progress to disable the 'events seen' counter and buffered event pre-display


=item --quiet

=item -q

=item --no-quiet

Be very quiet.

Can be specified multiple times


=item --renderers +My::Renderer

=item --renderers Renderer=arg1,arg2,...

=item --renderer +My::Renderer

=item --renderer Renderer=arg1,arg2,...

=item --no-renderers

Specify renderers, (Default: "Formatter=Test2"). Use "+" to give a fully qualified module name. Without "+" "Test2::Harness::Renderer::" will be prepended to your argument.

Can be specified multiple times. If the same key is listed multiple times the value lists will be appended together.


=item --show-times

=item -T

=item --no-show-times

Show the timing data for each job


=item --term-width 80

=item --term-width 200

=item --term-size 80

=item --term-size 200

=item --no-term-width

Alternative to setting $TABLE_TERM_SIZE. Setting this will override the terminal width detection to the number of characters specified.


=item --truncate-runner-output

=item --no-truncate-runner-output

Only show runner output that was generated after the current command. This is only useful with a persistent runner.


=item --verbose

=item -v

=item --no-verbose

Be more verbose

Can be specified multiple times


=back

=head3 Formatter Options

=over 4

=item --formatter ARG

=item --formatter=ARG

=item --no-formatter

NO DESCRIPTION - FIX ME


=item --qvf

=item --no-qvf

[Q]uiet, but [V]erbose on [F]ailure. Hide all output from tests when they pass, except to say they passed. If a test fails then ALL output from the test is verbosely output.


=item --show-job-end

=item --no-show-job-end

Show output when a job ends. (Default: on)


=item --show-job-info

=item --no-show-job-info

Show the job configuration when a job starts. (Default: off, unless -vv)


=item --show-job-launch

=item --no-show-job-launch

Show output for the start of a job. (Default: off unless -v)


=item --show-run-info

=item --no-show-run-info

Show the run configuration when a run starts. (Default: off, unless -vv)


=back

=head3 Git Options

=over 4

=item --git-change-base master

=item --git-change-base HEAD^

=item --git-change-base df22abe4

=item --no-git-change-base

Find files changed by all commits in the current branch from most recent stopping when a commit is found that is also present in the history of the branch/commit specified as the change base.


=back

=head3 Help and Debugging

=over 4

=item --dummy

=item -d

=item --no-dummy

Dummy run, do not actually execute anything

Can also be set with the following environment variables: C<T2_HARNESS_DUMMY>


=item --help

=item -h

=item --no-help

exit after showing help information


=item --interactive

=item -i

=item --no-interactive

Use interactive mode, 1 test at a time, stdin forwarded to it


=item --keep-dirs

=item --keep_dir

=item -k

=item --no-keep-dirs

Do not delete directories when done. This is useful if you want to inspect the directories used for various commands.


=item --procname-prefix ARG

=item --procname-prefix=ARG

=item --no-procname-prefix

Add a prefix to all proc names (as seen by ps).


=back

=head3 YathUI Options

=over 4

=item --yathui-api-key ARG

=item --yathui-api-key=ARG

=item --no-yathui-api-key

Yath-UI API key. This is not necessary if your Yath-UI instance is set to single-user


=item --yathui-db

=item --no-yathui-db

Add the YathUI DB renderer in addition to other renderers


=item --yathui-grace

=item --no-yathui-grace

If yath cannot connect to yath-ui it normally throws an error, use this to make it fail gracefully. You get a warning, but things keep going.


=item --yathui-long-duration 10

=item --no-yathui-long-duration

Minimum duration length (seconds) before a test goes from MEDIUM to LONG


=item --yathui-medium-duration 5

=item --no-yathui-medium-duration

Minimum duration length (seconds) before a test goes from SHORT to MEDIUM


=item --yathui-mode summary

=item --yathui-mode qvf

=item --yathui-mode qvfd

=item --yathui-mode complete

=item --no-yathui-mode

Set the upload mode (default 'qvfd')


=item --yathui-only

=item --no-yathui-only

Only use the YathUI renderer


=item --yathui-only-db

=item --no-yathui-only-db

Only use the YathUI DB renderer


=item --yathui-port 8080

=item --no-yathui-port

Port to use when running a local server


=item --yathui-port-command get_port.sh

=item --yathui-port-command get_port.sh --pid $$

=item --no-yathui-port-command

Use a command to get a port number. "$$" will be replaced with the PID of the yath process


=item --yathui-project ARG

=item --yathui-project=ARG

=item --no-yathui-project

The Yath-UI project for your test results


=item --yathui-render

=item --no-yathui-render

Add the YathUI renderer in addition to other renderers


=item --yathui-resources

=item --yathui-resources=5

=item --no-yathui-resources

Send resource info (for supported resources) to yathui at the specified interval in seconds (5 if not specified)


=item --yathui-retry

=item --no-yathui-retry

How many times to try an operation before giving up

Can be specified multiple times


=item --yathui-schema PostgreSQL

=item --yathui-schema MySQL

=item --yathui-schema MySQL56

=item --no-yathui-schema

What type of DB/schema to use when using a temporary database


=item --yathui-url http://my-yath-ui.com/...

=item --uri http://my-yath-ui.com/...

=item --no-yathui-url

Yath-UI url


=item --yathui-user ARG

=item --yathui-user=ARG

=item --no-yathui-user

Username to attach to the data sent to the db


=item --yathui-db-buffering none

=item --yathui-db-buffering job

=item --yathui-db-buffering diag

=item --yathui-db-buffering run

=item --no-yathui-db-buffering

Type of buffering to use, if "none" then events are written to the db one at a time, which is SLOW


=item --yathui-db-config ARG

=item --yathui-db-config=ARG

=item --no-yathui-db-config

Module that implements 'MODULE->yath_ui_config(%params)' which should return a Test2::Harness::UI::Config instance.


=item --yathui-db-coverage

=item --no-yathui-db-coverage

Pull coverage data directly from the database (default: off)


=item --yathui-db-driver Pg

=item --yathui-db-drivermysql

=item --yathui-db-driverMariaDB

=item --no-yathui-db-driver

DBI Driver to use


=item --yathui-db-dsn ARG

=item --yathui-db-dsn=ARG

=item --no-yathui-db-dsn

DSN to use when connecting to the db


=item --yathui-db-duration-limit ARG

=item --yathui-db-duration-limit=ARG

=item --no-yathui-db-duration-limit

Limit the number of runs to look at for durations data (default: 10)


=item --yathui-db-durations

=item --no-yathui-db-durations

Pull duration data directly from the database (default: off)


=item --yathui-db-flush-interval 2

=item --yathui-db-flush-interval 1.5

=item --no-yathui-db-flush-interval

When buffering DB writes, force a flush when an event is recieved at least N seconds after the last flush.


=item --yathui-db-host ARG

=item --yathui-db-host=ARG

=item --no-yathui-db-host

hostname to use when connecting to the db


=item --yathui-db-name ARG

=item --yathui-db-name=ARG

=item --no-yathui-db-name

Name of the database to use for yathui


=item --yathui-db-pass ARG

=item --yathui-db-pass=ARG

=item --no-yathui-db-pass

Password to use when connecting to the db


=item --yathui-db-port ARG

=item --yathui-db-port=ARG

=item --no-yathui-db-port

port to use when connecting to the db


=item --yathui-db-publisher ARG

=item --yathui-db-publisher=ARG

=item --no-yathui-db-publisher

When using coverage or duration data, only use data uploaded by this user


=item --yathui-db-socket ARG

=item --yathui-db-socket=ARG

=item --no-yathui-db-socket

socket to use when connecting to the db


=item --yathui-db-user ARG

=item --yathui-db-user=ARG

=item --no-yathui-db-user

Username to use when connecting to the db


=back

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2023 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

