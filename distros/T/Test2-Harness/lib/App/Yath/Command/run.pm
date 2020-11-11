package App::Yath::Command::run;
use strict;
use warnings;

our $VERSION = '1.000038';

use App::Yath::Options;

use Test2::Harness::Run;
use Test2::Harness::Util::Queue;
use Test2::Harness::Util::File::JSON;
use Test2::Harness::IPC;

use App::Yath::Util qw/find_pfile/;
use Test2::Harness::Util qw/open_file/;
use Test2::Harness::Util::JSON qw/encode_json decode_json/;
use Test2::Harness::Util qw/mod2file open_file/;
use Test2::Util::Table qw/table/;

use File::Spec;

use Carp qw/croak/;

use parent 'App::Yath::Command::test';
use Test2::Harness::Util::HashBase qw/+pfile_data +pfile/;

include_options(
    'App::Yath::Options::Debug',
    'App::Yath::Options::Display',
    'App::Yath::Options::Finder',
    'App::Yath::Options::Logging',
    'App::Yath::Options::PreCommand',
    'App::Yath::Options::Run',
);

sub group { 'persist' }

sub summary { "Run tests using the persistent test runner" }
sub cli_args { "[--] [test files/dirs] [::] [arguments to test scripts]" }

sub description {
    return <<"    EOT";
This command will run tests through an already started persistent instance. See
the start command for details on how to launch a persistant instance.
    EOT
}

sub terminate_queue {}
sub write_settings_to {}
sub setup_plugins {}
sub teardown_plugins {}

sub monitor_preloads { 1 }
sub job_count { 1 }

sub pfile {
    my $self = shift;
    $self->{+PFILE} //= find_pfile($self->settings) or die "No persistent harness was found for the current path.\n";
}

sub pfile_data {
    my $self = shift;
    return $self->{+PFILE_DATA} if $self->{+PFILE_DATA};

    my $pfile = $self->pfile;

    return $self->{+PFILE_DATA} = Test2::Harness::Util::File::JSON->new(name => $pfile)->read();
}

sub workdir {
    my $self = shift;
    return $self->pfile_data->{dir};
}

sub start_runner {
    my $self = shift;

    my $data = $self->pfile_data;

    if ($data->{version} ne $VERSION) {
        die "Version mismatch, persistent runner is version $data->{version}, runner is version $VERSION.\n";
    }

    $self->{+RUNNER_PID} = $data->{pid};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::run - Run tests using the persistent test runner

=head1 DESCRIPTION

This command will run tests through an already started persistent instance. See
the start command for details on how to launch a persistant instance.


=head1 USAGE

    $ yath [YATH OPTIONS] run [COMMAND OPTIONS]

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

Normally yath scans for and loads all App::Yath::Plugin::* modules in order to bring in command-line options they may provide. This flag will disable that. This is useful if you have a naughty plugin that it loading other modules when it should not.


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

=head3 Display Options

=over 4

=item --color

=item --no-color

Turn color on, default is true if STDOUT is a TTY.


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

Only search for tests for changed files (Requires --coverage-from, also requires a list of changes either from the --changed option, or a plugin that implements changed_files())


=item --changes-plugin Git

=item --changes-plugin +App::Yath::Plugin::Git

=item --no-changes-plugin

What plugin should be used to detect changed files.


=item --coverage-from path/to/log.jsonl

=item --coverage-from http://example.com/coverage

=item --coverage-from path/to/coverage.json

=item --no-coverage-from

Where to fetch coverage data. Can be a path to a .jsonl(.bz|.gz)? log file. Can be a path or url to a json file containing a hash where source files are key, and value is a list of tests to run.


=item --coverage-url-use-post

=item --no-coverage-url-use-post

If coverage_from is a url, use the http POST method with a list of changed files. This allows the server to tell us what tests to run instead of downloading all the coverage data and determining what tests to run from that.


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


=item --maybe-coverage-from path/to/log.jsonl

=item --maybe-coverage-from http://example.com/coverage

=item --maybe-coverage-from path/to/coverage.json

=item --no-maybe-coverage-from

Where to fetch coverage data. Can be a path to a .jsonl(.bz|.gz)? log file. Can be a path or url to a json file containing a hash where source files are key, and value is a list of tests to run.


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


=item --keep-dirs

=item --keep_dir

=item -k

=item --no-keep-dirs

Do not delete directories when done. This is useful if you want to inspect the directories used for various commands.


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


=item --write-coverage

=item --write-coverage=coverage.json

=item --no-write-coverage

Create a json file of all coverage data seen during the run (This implies --cover-files).


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


=back

=head3 Run Options

=over 4

=item --author-testing

=item -A

=item --no-author-testing

This will set the AUTHOR_TESTING environment to true


=item --cover-files

=item --no-cover-files

Use Test2::Plugin::Cover to collect coverage data for what files are touched by what tests. Unlike Devel::Cover this has very little performance impact (About 4% difference)


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


=item --yathui-project ARG

=item --yathui-project=ARG

=item --no-yathui-project

The Yath-UI project for your test results


=item --yathui-retry

=item --no-yathui-retry

How many times to try an operation before giving up

Can be specified multiple times


=item --yathui-upload

=item --no-yathui-upload

Upload the log to Yath-UI


=item --yathui-url http://my-yath-ui.com/...

=item --uri http://my-yath-ui.com/...

=item --no-yathui-url

Yath-UI url


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

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

