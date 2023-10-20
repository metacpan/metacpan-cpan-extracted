package App::Yath::Command::status;
use strict;
use warnings;

our $VERSION = '1.000155';

use Term::Table();
use File::Spec();

use Test2::Harness::Runner::State;
use Test2::Harness::Util::File::JSON();
use Test2::Harness::Util::Queue();

use parent 'App::Yath::Command::run';
use Test2::Harness::Util::HashBase;

sub group { 'persist' }

sub summary { "Status info and process lists for the runner" }
sub cli_args { "" }

sub description {
    return <<"    EOT";
This command will provide health details and a process list for the runner.
    EOT
}

sub pfile_params { (no_fatal => 1) }

sub run {
    my $self = shift;

    my $data = $self->pfile_data();

    my $state = Test2::Harness::Runner::State->new(
        workdir => $self->workdir,
        observe => 1,
    );

    $state->poll;

    print "\n**** Pending tests: ****\n";
    my $pending = $state->pending_tasks;
    for my $run ($state->run, @{$state->pending_runs // []}) {
        next unless $run;
        my $run_id =$run->{run_id} or next;

        print "\nRun $run_id:\n";
        my $pending = $pending->{$run_id} // {};
        my @tasks;
        my @check = ($pending);
        while (my $it = shift @check) {
            my $ref = ref($it);

            if ($ref eq 'ARRAY') {
                push @check => @$it;
                next;
            }

            if ($ref eq 'HASH') {
                if ($it->{job_id}) {
                    push @tasks => $it;
                    next;
                }

                push @check => values %$it;
                next;
            }
        }

        if (!@tasks) {
            print "--No pending tasks for this run--\n";
            next;
        }

        my @rows = map {[$_->{job_id}, $_->{is_try} // $_->{job_try} // 0, $_->{rel_file}, join(', ' => @{$_->{conflicts} // []})]} @tasks;
        my $run_table = Term::Table->new(
            collapse => 1,
            header => [qw/uuid try test conflicts/],
            rows => [ sort { $a->[2] cmp $b->[2] } @rows ],
        );

        print "$_\n" for $run_table->render;
    }

    print "\n**** Runner Stages: ****\n";
    my $stage_status = $state->stage_readiness // {};
    my $reload_status = $state->reload_state // {};
    my $reload_issues = 0;

    my $rows = [];
    for my $stage (keys %$stage_status) {
        my $pid = $stage_status->{$stage} ||= '';
        my $ready = $pid ? 'YES' : 'NO';
        $pid = 'N/A' if $pid && $pid == 1;

        my $issues = keys %{$reload_status->{$stage}};
        my $reload = $issues ? 'YES' : 'NO';
        $reload_issues += $issues;

        push @$rows => [$pid, $stage, $ready, $reload];
    }

    @$rows = sort { $a->[0] <=> $b->[0] } @$rows;

    my $stage_table = Term::Table->new(
        collapse => 1,
        header => [qw/pid stage ready/, 'reload issues'],
        rows => $rows,
    );
    print "$_\n" for $stage_table->render;

    if ($reload_issues) {
        my %seen;
        print "\n**** Reload issues: ****\n";
        for my $stage (sort keys %$reload_status) {
            for my $file (keys %{$reload_status->{$stage}}) {
                next if $seen{$file}++;
                my $data = $reload_status->{$stage}->{$file} or next;
                print "\n==== SOURCE FILE: $file ====\n";
                print $data->{error} if $data->{error};
                print $_ for @{$data->{warnings} // []};
            }
        }
        print "\n";
    }

    print "\n**** Running tests: ****\n";
    my $running = $state->running_tasks;
    my $running_tasks = [values %$running];
    my @rows = map {[$self->get_job_pid($_->{run_id}, $_->{job_id}) // 'N/A', $_->{job_id}, $_->{is_try} // $_->{job_try} // 0, $_->{rel_file}, join(', ' => @{$_->{conflicts} // []})]} @$running_tasks;
    if (@rows) {
        my $run_table = Term::Table->new(
            collapse => 1,
            header => [qw/pid uuid try test conflicts/],
            rows => [ sort { $a->[0] <=> $b->[0] } @rows ],
        );
        print "$_\n" for $run_table->render;
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::status - Status info and process lists for the runner

=head1 DESCRIPTION

This command will provide health details and a process list for the runner.


=head1 USAGE

    $ yath [YATH OPTIONS] status [COMMAND OPTIONS]

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

=head3 Finder Options

=over 4

=item --finder MyFinder

=item --finder +Test2::Harness::Finder::MyFinder

=item --no-finder

Specify what Finder subclass to use when searching for files/processing the file list. Use the "+" prefix to specify a fully qualified namespace, otherwise Test2::Harness::Finder::XXX namespace is assumed.


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

=head3 Finder Options

=over 4

=item --changed path/to/file

=item --no-changed

Specify one or more files as having been changed.

Can be specified multiple times


=item --changed-only

=item --no-changed-only

Only search for tests for changed files (Requires a coverage data source, also requires a list of changes either from the --changed option, or a plugin that implements changed_files() or changed_diff())


=item --changes-diff path/to/diff.diff

=item --no-changes-diff

Path to a diff file that should be used to find changed files for use with --changed-only. This must be in the same format as `git diff -W --minimal -U1000000`


=item --changes-exclude-file path/to/file

=item --no-changes-exclude-file

Specify one or more files to ignore when looking at changes

Can be specified multiple times


=item --changes-exclude-loads

=item --no-changes-exclude-loads

Exclude coverage tests which only load changed files, but never call code from them. (default: off)


=item --changes-exclude-nonsub

=item --no-changes-exclude-nonsub

Exclude changes outside of subroutines (perl files only) (default: off)


=item --changes-exclude-opens

=item --no-changes-exclude-opens

Exclude coverage tests which only open() changed files, but never call code from them. (default: off)


=item --changes-exclude-pattern '(apple|pear|orange)'

=item --no-changes-exclude-pattern

Ignore files matching this pattern when looking for changes. Your pattern will be inserted unmodified into a `$file =~ m/$pattern/` check.

Can be specified multiple times


=item --changes-filter-file path/to/file

=item --no-changes-filter-file

Specify one or more files to check for changes. Changes to other files will be ignored

Can be specified multiple times


=item --changes-filter-pattern '(apple|pear|orange)'

=item --no-changes-filter-pattern

Specify a pattern for change checking. When only running tests for changed files this will limit which files are checked for changes. Only files that match this pattern will be checked. Your pattern will be inserted unmodified into a `$file =~ m/$pattern/` check.

Can be specified multiple times


=item --changes-include-whitespace

=item --no-changes-include-whitespace

Include changed lines that are whitespace only (default: off)


=item --changes-plugin Git

=item --changes-plugin +App::Yath::Plugin::Git

=item --no-changes-plugin

What plugin should be used to detect changed files.


=item --default-at-search ARG

=item --default-at-search=ARG

=item --no-default-at-search

Specify the default file/dir search when 'AUTHOR_TESTING' is set. Defaults to './xt'. The default AT search is only used if no files were specified at the command line

Can be specified multiple times


=item --default-search ARG

=item --default-search=ARG

=item --no-default-search

Specify the default file/dir search. defaults to './t', './t2', and 'test.pl'. The default search is only used if no files were specified at the command line

Can be specified multiple times


=item --durations file.json

=item --durations http://example.com/durations.json

=item --no-durations

Point at a json file or url which has a hash of relative test filenames as keys, and 'SHORT', 'MEDIUM', or 'LONG' as values. This will override durations listed in the file headers. An exception will be thrown if the durations file or url does not work.


=item --durations-threshold ARG

=item --durations-threshold=ARG

=item --Dt ARG

=item --Dt=ARG

=item --no-durations-threshold

Only fetch duration data if running at least this number of tests. Default (-j value + 1)


=item --exclude-file t/nope.t

=item --no-exclude-file

Exclude a file from testing

Can be specified multiple times


=item --exclude-list file.txt

=item --exclude-list http://example.com/exclusions.txt

=item --no-exclude-list

Point at a file or url which has a new line separated list of test file names to exclude from testing. Starting a line with a '#' will comment it out (for compatibility with Test2::Aggregate list files).

Can be specified multiple times


=item --exclude-pattern t/nope.t

=item --no-exclude-pattern

Exclude a pattern from testing, matched using m/$PATTERN/

Can be specified multiple times


=item --extension ARG

=item --extension=ARG

=item --ext ARG

=item --ext=ARG

=item --no-extension

Specify valid test filename extensions, default: t and t2

Can be specified multiple times


=item --maybe-durations file.json

=item --maybe-durations http://example.com/durations.json

=item --no-maybe-durations

Point at a json file or url which has a hash of relative test filenames as keys, and 'SHORT', 'MEDIUM', or 'LONG' as values. This will override durations listed in the file headers. An exception will be thrown if the durations file or url does not work.


=item --no-long

=item --no-no-long

Do not run tests that have their duration flag set to 'LONG'


=item --only-long

=item --no-only-long

Only run tests that have their duration flag set to 'LONG'


=item --rerun

=item --rerun=path/to/log.jsonl

=item --rerun=plugin_specific_string

=item --no-rerun

Re-Run tests from a previous run from a log file (or last log file). Plugins can intercept this, such as YathUIDB which will grab a run UUID and derive tests to re-run from that.


=item --rerun-all

=item --rerun-all=path/to/log.jsonl

=item --rerun-all=plugin_specific_string

=item --no-rerun-all

Re-Run all tests from a previous run from a log file (or last log file). Plugins can intercept this, such as YathUIDB which will grab a run UUID and derive tests to re-run from that.


=item --rerun-failed

=item --rerun-failed=path/to/log.jsonl

=item --rerun-failed=plugin_specific_string

=item --no-rerun-failed

Re-Run failed tests from a previous run from a log file (or last log file). Plugins can intercept this, such as YathUIDB which will grab a run UUID and derive tests to re-run from that.


=item --rerun-missed

=item --rerun-missed=path/to/log.jsonl

=item --rerun-missed=plugin_specific_string

=item --no-rerun-missed

Run missed tests from a previously aborted/stopped run from a log file (or last log file). Plugins can intercept this, such as YathUIDB which will grab a run UUID and derive tests to re-run from that.


=item --rerun-modes failed,missed,...

=item --rerun-modes all

=item --rerun-modes failed

=item --rerun-modes missed

=item --rerun-modes passed

=item --rerun-modes retried

=item --rerun-mode failed,missed,...

=item --rerun-mode all

=item --rerun-mode failed

=item --rerun-mode missed

=item --rerun-mode passed

=item --rerun-mode retried

=item --no-rerun-modes

Pick which test categories to run

Can be specified multiple times


=item --rerun-passed

=item --rerun-passed=path/to/log.jsonl

=item --rerun-passed=plugin_specific_string

=item --no-rerun-passed

Re-Run passed tests from a previous run from a log file (or last log file). Plugins can intercept this, such as YathUIDB which will grab a run UUID and derive tests to re-run from that.


=item --rerun-plugin Foo

=item --rerun-plugin +App::Yath::Plugin::Foo

=item --no-rerun-plugin

What plugin(s) should be used for rerun (will fallback to other plugins if the listed ones decline the value, this is just used ot set an order of priority)

Can be specified multiple times


=item --rerun-retried

=item --rerun-retried=path/to/log.jsonl

=item --rerun-retried=plugin_specific_string

=item --no-rerun-retried

Re-Run retried tests from a previous run from a log file (or last log file). Plugins can intercept this, such as YathUIDB which will grab a run UUID and derive tests to re-run from that.


=item --search ARG

=item --search=ARG

=item --no-search

List of tests and test directories to use instead of the default search paths. Typically these can simply be listed as command line arguments without the --search prefix.

Can be specified multiple times


=item --show-changed-files

=item --no-show-changed-files

Print a list of changed files if any are found


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


=item --summary

=item --summary=/path/to/summary.json

=item --no-summary

Write out a summary json file, if no path is provided 'summary.json' will be used. The .json extension is added automatically if omitted.


=back

=head3 Logging Options

=over 4

=item --bzip2

=item --bz2

=item --bzip2_log

=item -B

=item --no-bzip2

Use bzip2 compression when writing the log. This option implies -L. The .bz2 prefix is added to log file name for you


=item --gzip

=item --gz

=item --gzip_log

=item -G

=item --no-gzip

Use gzip compression when writing the log. This option implies -L. The .gz prefix is added to log file name for you


=item --log

=item -L

=item --no-log

Turn on logging


=item --log-dir ARG

=item --log-dir=ARG

=item --no-log-dir

Specify a log directory. Will fall back to the system temp dir.


=item --log-file ARG

=item --log-file=ARG

=item -F ARG

=item -F=ARG

=item --no-log-file

Specify the name of the log file. This option implies -L.


=item --log-file-format ARG

=item --log-file-format=ARG

=item --lff ARG

=item --lff=ARG

=item --no-log-file-format

Specify the format for automatically-generated log files. Overridden by --log-file, if given. This option implies -L (Default: \$YATH_LOG_FILE_FORMAT, if that is set, or else "%!P%Y-%m-%d~%H:%M:%S~%!U~%!p.jsonl"). This is a string in which percent-escape sequences will be replaced as per POSIX::strftime. The following special escape sequences are also replaced: (%!P : Project name followed by a ~, if a project is defined, otherwise empty string) (%!U : the unique test run ID) (%!p : the process ID) (%!S : the number of seconds since local midnight UTC)

Can also be set with the following environment variables: C<YATH_LOG_FILE_FORMAT>, C<TEST2_HARNESS_LOG_FORMAT>


=back

=head3 Notification Options

=over 4

=item --notify-email foo@example.com

=item --no-notify-email

Email the test results to the specified email address(es)

Can be specified multiple times


=item --notify-email-fail foo@example.com

=item --no-notify-email-fail

Email failing results to the specified email address(es)

Can be specified multiple times


=item --notify-email-from foo@example.com

=item --no-notify-email-from

If any email is sent, this is who it will be from


=item --notify-email-owner

=item --no-notify-email-owner

Email the owner of broken tests files upon failure. Add `# HARNESS-META-OWNER foo@example.com` to the top of a test file to give it an owner


=item --notify-no-batch-email

=item --no-notify-no-batch-email

Usually owner failures are sent as a single batch at the end of testing. Toggle this to send failures as they happen.


=item --notify-no-batch-slack

=item --no-notify-no-batch-slack

Usually owner failures are sent as a single batch at the end of testing. Toggle this to send failures as they happen.


=item --notify-slack '#foo'

=item --notify-slack '@bar'

=item --no-notify-slack

Send results to a slack channel and/or user

Can be specified multiple times


=item --notify-slack-fail '#foo'

=item --notify-slack-fail '@bar'

=item --no-notify-slack-fail

Send failing results to a slack channel and/or user

Can be specified multiple times


=item --notify-slack-owner

=item --no-notify-slack-owner

Send slack notifications to the slack channels/users listed in test meta-data when tests fail.


=item --notify-slack-url https://hooks.slack.com/...

=item --no-notify-slack-url

Specify an API endpoint for slack webhook integrations


=item --notify-text ARG

=item --notify-text=ARG

=item --message ARG

=item --message=ARG

=item --msg ARG

=item --msg=ARG

=item --no-notify-text

Add a custom text snippet to email/slack notifications


=item --notify-text-module ARG

=item --notify-text-module=ARG

=item --message_module ARG

=item --message_module=ARG

=item --no-notify-text-module

Use the specified module to generate messages for emails and/or slack.


=back

=head3 Run Options

=over 4

=item --author-testing

=item -A

=item --no-author-testing

This will set the AUTHOR_TESTING environment to true


=item --dbi-profiling

=item --no-dbi-profiling

Use Test2::Plugin::DBIProfile to collect database profiling data


=item --env-var VAR=VAL

=item -EVAR=VAL

=item -E VAR=VAL

=item --no-env-var

Set environment variables to set when each test is run.

Can be specified multiple times


=item --event-uuids

=item --uuids

=item --no-event-uuids

Use Test2::Plugin::UUID inside tests (default: on)


=item --fields name:details

=item --fields JSON_STRING

=item -f name:details

=item -f JSON_STRING

=item --no-fields

Add custom data to the harness run

Can be specified multiple times


=item --input ARG

=item --input=ARG

=item --no-input

Input string to be used as standard input for ALL tests. See also: --input-file


=item --input-file ARG

=item --input-file=ARG

=item --no-input-file

Use the specified file as standard input to ALL tests


=item --io-events

=item --no-io-events

Use Test2::Plugin::IOEvents inside tests to turn all prints into test2 events (default: off)


=item --link 'https://travis.work/builds/42'

=item --link 'https://jenkins.work/job/42'

=item --link 'https://buildbot.work/builders/foo/builds/42'

=item --no-link

Provide one or more links people can follow to see more about this run.

Can be specified multiple times


=item --load ARG

=item --load=ARG

=item --load-module ARG

=item --load-module=ARG

=item -m ARG

=item -m=ARG

=item --no-load

Load a module in each test (after fork). The "import" method is not called.

Can be specified multiple times


=item --load-import Module

=item --load-import Module=import_arg1,arg2,...

=item --loadim Module

=item --loadim Module=import_arg1,arg2,...

=item -M Module

=item -M Module=import_arg1,arg2,...

=item --no-load-import

Load a module in each test (after fork). Import is called.

Can be specified multiple times. If the same key is listed multiple times the value lists will be appended together.


=item --mem-usage

=item --no-mem-usage

Use Test2::Plugin::MemUsage inside tests (default: on)


=item --retry ARG

=item --retry=ARG

=item -r ARG

=item -r=ARG

=item --no-retry

Run any jobs that failed a second time. NOTE: --retry=1 means failing tests will be attempted twice!


=item --retry-isolated

=item --retry-iso

=item --no-retry-isolated

If true then any job retries will be done in isolation (as though -j1 was set)


=item --run-id

=item --id

=item --no-run-id

Set a specific run-id. (Default: a UUID)


=item --test-args ARG

=item --test-args=ARG

=item --no-test-args

Arguments to pass in as @ARGV for all tests that are run. These can be provided easier using the '::' argument separator.

Can be specified multiple times


=item --stream

=item --no-stream

Use the stream formatter (default is on)


=item --tap

=item --TAP

=item ----no-stream

=item --no-tap

The TAP format is lossy and clunky. Test2::Harness normally uses a newer streaming format to receive test results. There are old/legacy tests where this causes problems, in which case setting --TAP or --no-stream can help.


=back

=head3 YathUI Options

=over 4

=item --yathui-api-key ARG

=item --yathui-api-key=ARG

=item --no-yathui-api-key

Yath-UI API key. This is not necessary if your Yath-UI instance is set to single-user


=item --yathui-coverage

=item --no-yathui-coverage

Poll coverage data from Yath-UI to determine what tests should be run for changed files


=item --yathui-db

=item --no-yathui-db

Add the YathUI DB renderer in addition to other renderers


=item --yathui-durations

=item --no-yathui-durations

Poll duration data from Yath-UI to help order tests efficiently


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


=item --yathui-upload

=item --no-yathui-upload

Upload the log to Yath-UI


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

=head3 NO CATEGORY - FIX ME

=over 4

=item --check-reload-state

=item --no-check-reload-state

Abort the run if there are unfixes reload errors and show a confirmation dialogue for unfixed reload warnings.


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

