package App::Yath::Command::start;
use strict;
use warnings;

our $VERSION = '1.000038';

use App::Yath::Util qw/find_pfile/;
use App::Yath::Options;

use Test2::Harness::Run;
use Test2::Harness::Util::Queue;
use Test2::Harness::Util::File::JSON;
use Test2::Harness::IPC;

use Test2::Harness::Util::JSON qw/encode_json decode_json/;
use Test2::Harness::Util qw/mod2file open_file parse_exit/;
use Test2::Util::Table qw/table/;

use Test2::Harness::Util::IPC qw/run_cmd USE_P_GROUPS/;

use POSIX;
use File::Spec;

use Time::HiRes qw/sleep/;

use Carp qw/croak/;
use File::Path qw/remove_tree/;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

include_options(
    'App::Yath::Options::Debug',
    'App::Yath::Options::PreCommand',
    'App::Yath::Options::Runner',
    'App::Yath::Options::Workspace',
    'App::Yath::Options::Persist',
);

option_group {prefix => 'runner', category => "Persistent Runner Options"} => sub {
    option quiet => (
        short       => 'q',
        type        => 'c',
        description => "Be very quiet.",
        default     => 0,
    );
};

sub MAX_ATTACH() { 1_048_576 }

sub group { 'persist' }

sub always_keep_dir { 1 }

sub summary { "Start the persistent test runner" }
sub cli_args { "" }

sub description {
    return <<"    EOT";
This command is used to start a persistant instance of yath. A persistant
instance is useful because it allows you to preload modules in advance,
reducing start time for any tests you decide to run as you work.

A running instance will watch for changes to any preloaded files, and restart
itself if anything changes. Changed files are blacklisted for subsequent
reloads so that reloading is not a frequent occurence when editing the same
file over and over again.
    EOT
}

sub run {
    my $self = shift;

    my $settings = $self->settings;
    my $dir      = $settings->workspace->workdir;

    my $pfile = find_pfile($settings, vivify => 1);

    if (-f $pfile) {
        remove_tree($dir, {safe => 1, keep_root => 0});
        die "Persistent harness appears to be running, found $pfile\n";
    }

    $self->write_settings_to($dir, 'settings.json');

    my $run_queue = Test2::Harness::Util::Queue->new(file => File::Spec->catfile($dir, 'run_queue.jsonl'));
    $run_queue->start();

    $_->setup($self->settings) for @{$self->settings->harness->plugins};

    my $stderr = File::Spec->catfile($dir, 'error.log');
    my $stdout = File::Spec->catfile($dir, 'output.log');

    my @prof;
    if ($settings->runner->nytprof) {
        push @prof => '-d:NYTProf';
    }

    my $pid = run_cmd(
        stderr => $stderr,
        stdout => $stdout,

        no_set_pgrp => $settings->runner->daemon,

        command => [
            $^X, @prof, $settings->harness->script,
            (map { "-D$_" } @{$settings->harness->dev_libs}),
            '--no-scan-plugins',    # Do not preload any plugin modules
            runner           => $dir,
            monitor_preloads => 1,
            persist          => $pfile,
            jobs_todo        => 0,
        ],
    );

    unless ($settings->runner->quiet) {
        print "\nPersistent runner started!\n";

        print "Runner PID: $pid\n";
        print "Runner dir: $dir\n";
        print "\nUse `yath watch` to monitor the persistent runner\n\n" if $settings->runner->daemon;
    }

    Test2::Harness::Util::File::JSON->new(name => $pfile)->write({pid => $pid, dir => $dir, version => $VERSION});

    return 0 if $settings->runner->daemon;

    $SIG{TERM} = sub { kill(TERM => $pid) };
    $SIG{INT}  = sub { kill(INT  => $pid) };

    my $err_fh = open_file($stderr, '<');
    my $out_fh = open_file($stdout, '<');

    while (1) {
        my $out = waitpid($pid, WNOHANG);
        my $wstat = $?;

        my $count = 0;
        while (my $line = <$out_fh>) {
            $count++;
            print STDOUT $line;
        }
        while (my $line = <$err_fh>) {
            $count++;
            print STDERR $line;
        }

        sleep(0.02) unless $out || $count;

        next if $out == 0;
        return 255 if $out < 0;

        my $exit = parse_exit($?);
        return $exit->{err} || $exit->{sig} || 0;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::start - Start the persistent test runner

=head1 DESCRIPTION

This command is used to start a persistant instance of yath. A persistant
instance is useful because it allows you to preload modules in advance,
reducing start time for any tests you decide to run as you work.

A running instance will watch for changes to any preloaded files, and restart
itself if anything changes. Changed files are blacklisted for subsequent
reloads so that reloading is not a frequent occurence when editing the same
file over and over again.


=head1 USAGE

    $ yath [YATH OPTIONS] start [COMMAND OPTIONS]

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


=back

=head3 Persistent Runner Options

=over 4

=item --quiet

=item -q

=item --no-quiet

Be very quiet.

Can be specified multiple times


=back

=head3 Runner Options

=over 4

=item --blib

=item -b

=item --no-blib

(Default: include if it exists) Include 'blib/lib' and 'blib/arch' in your module path


=item --cover

=item --cover=-silent,1,+ignore,^t/,+ignore,^t2/,+ignore,^xt,+ignore,^test.pl

=item --no-cover

Use Devel::Cover to calculate test coverage. This disables forking. If no args are specified the following are used: -silent,1,+ignore,^t/,+ignore,^t2/,+ignore,^xt,+ignore,^test.pl


=item --daemon

=item --no-daemon

Start the runner as a daemon (Default: True)


=item --event-timeout SECONDS

=item --et SECONDS

=item --no-event-timeout

Kill test if no output is received within timeout period. (Default: 60 seconds). Add the "# HARNESS-NO-TIMEOUT" comment to the top of a test file to disable timeouts on a per-test basis. This prevents a hung test from running forever.


=item --include ARG

=item --include=ARG

=item -I ARG

=item -I=ARG

=item --no-include

Add a directory to your include paths

Can be specified multiple times


=item --job-count ARG

=item --job-count=ARG

=item --jobs ARG

=item --jobs=ARG

=item -j ARG

=item -j=ARG

=item --no-job-count

Set the number of concurrent jobs to run (Default: 1)

Can also be set with the following environment variables: C<YATH_JOB_COUNT>, C<T2_HARNESS_JOB_COUNT>, C<HARNESS_JOB_COUNT>


=item --lib

=item -l

=item --no-lib

(Default: include if it exists) Include 'lib' in your module path


=item --nytprof

=item --no-nytprof

Use Devel::NYTProf on tests. This will set addpid=1 for you. This works with or without fork.


=item --post-exit-timeout SECONDS

=item --pet SECONDS

=item --no-post-exit-timeout

Stop waiting post-exit after the timeout period. (Default: 15 seconds) Some tests fork and allow the parent to exit before writing all their output. If Test2::Harness detects an incomplete plan after the test exits it will monitor for more events until the timeout period. Add the "# HARNESS-NO-TIMEOUT" comment to the top of a test file to disable timeouts on a per-test basis.


=item --preload-threshold ARG

=item --preload-threshold=ARG

=item --Pt ARG

=item --Pt=ARG

=item -W ARG

=item -W=ARG

=item --no-preload-threshold

Only do preload if at least N tests are going to be run. In some cases a full preload takes longer than simply running the tests, this lets you specify a minimum number of test jobs that will be run for preload to happen. This has no effect for a persistent runner. The default is 0, and it means always preload.


=item --preloads ARG

=item --preloads=ARG

=item --preload ARG

=item --preload=ARG

=item -P ARG

=item -P=ARG

=item --no-preloads

Preload a module before running tests

Can be specified multiple times


=item --resource Port

=item --resource +Test2::Harness::Runner::Resource::Port

=item -R Port

=item --no-resource

Use a resource module to assign resource assignments to individual tests

Can be specified multiple times


=item --switch ARG

=item --switch=ARG

=item -S ARG

=item -S=ARG

=item --no-switch

Pass the specified switch to perl for each test. This is not compatible with preload.

Can be specified multiple times


=item --tlib

=item --no-tlib

(Default: off) Include 't/lib' in your module path


=item --unsafe-inc

=item --no-unsafe-inc

perl is removing '.' from @INC as a security concern. This option keeps things from breaking for now.

Can also be set with the following environment variables: C<PERL_USE_UNSAFE_INC>


=item --use-fork

=item --fork

=item --no-use-fork

(default: on, except on windows) Normally tests are run by forking, which allows for features like preloading. This will turn off the behavior globally (which is not compatible with preloading). This is slower, it is better to tag misbehaving tests with the '# HARNESS-NO-PRELOAD' comment in their header to disable forking only for those tests.

Can also be set with the following environment variables: C<!T2_NO_FORK>, C<T2_HARNESS_FORK>, C<!T2_HARNESS_NO_FORK>, C<YATH_FORK>, C<!YATH_NO_FORK>


=item --use-timeout

=item --timeout

=item --no-use-timeout

(default: on) Enable/disable timeouts


=back

=head3 Workspace Options

=over 4

=item --clear

=item -C

=item --no-clear

Clear the work directory if it is not already empty


=item --tmp-dir ARG

=item --tmp-dir=ARG

=item --tmpdir ARG

=item --tmpdir=ARG

=item -t ARG

=item -t=ARG

=item --no-tmp-dir

Use a specific temp directory (Default: use system temp dir)

Can also be set with the following environment variables: C<T2_HARNESS_TEMP_DIR>, C<YATH_TEMP_DIR>, C<TMPDIR>, C<TEMPDIR>, C<TMP_DIR>, C<TEMP_DIR>


=item --workdir ARG

=item --workdir=ARG

=item -w ARG

=item -w=ARG

=item --no-workdir

Set the work directory (Default: new temp directory)

Can also be set with the following environment variables: C<T2_WORKDIR>, C<YATH_WORKDIR>


=back

=head3 YathUI Options

=over 4

=item --yathui-api-key ARG

=item --yathui-api-key=ARG

=item --no-yathui-api-key

Yath-UI API key. This is not necessary if your Yath-UI instance is set to single-user


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

