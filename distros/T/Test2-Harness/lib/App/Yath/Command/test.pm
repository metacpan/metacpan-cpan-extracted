package App::Yath::Command::test;
use strict;
use warnings;

our $VERSION = '1.000038';

use App::Yath::Options;

use Test2::Harness::Run;
use Test2::Harness::Event;
use Test2::Harness::Util::Queue;
use Test2::Harness::Util::File::JSON;
use Test2::Harness::IPC;

use Test2::Harness::Runner::State;

use Test2::Harness::Util::JSON qw/encode_json decode_json JSON/;
use Test2::Harness::Util qw/mod2file open_file chmod_tmp/;
use Test2::Util::Table qw/table/;

use Test2::Harness::Util::Term qw/USE_ANSI_COLOR/;

use File::Spec;

use Time::HiRes qw/sleep time/;
use List::Util qw/sum max/;
use Carp qw/croak/;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw/
    <runner_pid +ipc +signal

    +run

    +auditor_reader
    +collector_writer
    +renderer_reader
    +auditor_writer

    +renderers
    +logger

    +tests_seen
    +asserts_seen

    +run_queue
    +tasks_queue
    +state

    <final_data

    <coverage_aggregator
/;

include_options(
    'App::Yath::Options::Debug',
    'App::Yath::Options::Display',
    'App::Yath::Options::Finder',
    'App::Yath::Options::Logging',
    'App::Yath::Options::PreCommand',
    'App::Yath::Options::Run',
    'App::Yath::Options::Runner',
    'App::Yath::Options::Workspace',
);

sub MAX_ATTACH() { 1_048_576 }

sub group { ' test' }

sub summary  { "Run tests" }
sub cli_args { "[--] [test files/dirs] [::] [arguments to test scripts]" }

sub description {
    return <<"    EOT";
This yath command (which is also the default command) will run all the test
files for the current project. If no test files are specified this command will
look for the 't', and 't2' directories, as well as the 'test.pl' file.

This command is always recursive when given directories.

This command will add 'lib', 'blib/arch' and 'blib/lib' to the perl path for
you by default (after any -I's). You can specify -l if you just want lib, -b if
you just want the blib paths. If you specify both -l and -b both will be added
in the order you specify (order relative to any -I options will also be
preserved.  If you do not specify they will be added in this order: -I's, lib,
blib/lib, blib/arch. You can also add --no-lib and --no-blib to avoid both.

Any command line argument that is not an option will be treated as a test file
or directory of test files to be run.

If you wish to specify the ARGV for tests you may append them after '::'. This
is mainly useful for Test::Class::Moose and similar tools. EVERY test run will
get the same ARGV.
    EOT
}

sub cover {
    return unless $ENV{T2_DEVEL_COVER};
    return unless $ENV{T2_COVER_SELF};
    return '-MDevel::Cover=-silent,1,+ignore,^t/,+ignore,^t2/,+ignore,^xt,+ignore,^test.pl';
}

sub init {
    my $self = shift;
    $self->SUPER::init() if $self->can('SUPER::init');

    $self->{+TESTS_SEEN}   //= 0;
    $self->{+ASSERTS_SEEN} //= 0;
}

sub auditor_reader {
    my $self = shift;
    return $self->{+AUDITOR_READER} if $self->{+AUDITOR_READER};
    pipe($self->{+AUDITOR_READER}, $self->{+COLLECTOR_WRITER}) or die "Could not create pipe: $!";
    return $self->{+AUDITOR_READER};
}

sub collector_writer {
    my $self = shift;
    return $self->{+COLLECTOR_WRITER} if $self->{+COLLECTOR_WRITER};
    pipe($self->{+AUDITOR_READER}, $self->{+COLLECTOR_WRITER}) or die "Could not create pipe: $!";
    return $self->{+COLLECTOR_WRITER};
}

sub renderer_reader {
    my $self = shift;
    return $self->{+RENDERER_READER} if $self->{+RENDERER_READER};
    pipe($self->{+RENDERER_READER}, $self->{+AUDITOR_WRITER}) or die "Could not create pipe: $!";
    return $self->{+RENDERER_READER};
}

sub auditor_writer {
    my $self = shift;
    return $self->{+AUDITOR_WRITER} if $self->{+AUDITOR_WRITER};
    pipe($self->{+RENDERER_READER}, $self->{+AUDITOR_WRITER}) or die "Could not create pipe: $!";
    return $self->{+AUDITOR_WRITER};
}

sub workdir {
    my $self = shift;
    $self->settings->workspace->workdir;
}

sub ipc {
    my $self = shift;
    return $self->{+IPC} //= Test2::Harness::IPC->new(
        handlers => {
            INT  => sub { $self->handle_sig(@_) },
            TERM => sub { $self->handle_sig(@_) },
        }
    );
}

sub handle_sig {
    my $self = shift;
    my ($sig) = @_;

    print STDERR "\nCaught SIG$sig, forwarding signal to child processes...\n";
    $self->ipc->killall($sig);

    if ($self->{+SIGNAL}) {
        print STDERR "\nSecond signal ($self->{+SIGNAL} followed by $sig), exiting now without waiting\n";
        exit 1;
    }

    $self->{+SIGNAL} = $sig;
}

sub monitor_preloads { 0 }

sub run {
    my $self = shift;

    my $settings = $self->settings;
    my $plugins = $self->settings->harness->plugins;

    if ($self->start()) {
        $self->render();
        $self->stop();

        my $final_data = $self->{+FINAL_DATA} or die "Final data never received from auditor!\n";
        my $pass = $self->{+TESTS_SEEN} && $final_data->{pass};
        $self->render_final_data($final_data);
        $self->produce_summary($pass);

        if (@$plugins) {
            my %args = (
                settings     => $settings,
                final_data   => $final_data,
                pass         => $pass ? 1 : 0,
                tests_seen   => $self->{+TESTS_SEEN} // 0,
                asserts_seen => $self->{+ASSERTS_SEEN} // 0,
            );
            $_->finish(%args) for @$plugins;
        }

        return $pass ? 0 : 1;
    }

    $self->stop();
    return 1;
}

sub start {
    my $self = shift;

    $self->ipc->start();
    $self->parse_args;
    $self->write_settings_to($self->workdir, 'settings.json');

    my $pop = $self->populate_queue();
    $self->terminate_queue();

    return unless $pop;

    $self->setup_plugins();

    $self->start_runner(jobs_todo => $pop);
    $self->start_collector();
    $self->start_auditor();

    return 1;
}

sub setup_plugins {
    my $self = shift;
    $_->setup($self->settings) for @{$self->settings->harness->plugins};
}

sub teardown_plugins {
    my $self = shift;
    $_->teardown($self->settings) for @{$self->settings->harness->plugins};
}

sub render {
    my $self = shift;

    my $ipc       = $self->ipc;
    my $settings  = $self->settings;
    my $renderers = $self->renderers;
    my $logger    = $self->logger;
    my $plugins = $self->settings->harness->plugins;

    my $cover = $settings->logging->write_coverage;
    if ($cover) {
        require Test2::Harness::Log::CoverageAggregator;
        $self->{+COVERAGE_AGGREGATOR} //= Test2::Harness::Log::CoverageAggregator->new();
    }

    $plugins = [grep {$_->can('handle_event')} @$plugins];

    # render results from log
    my $reader = $self->renderer_reader();
    $reader->blocking(0);
    my $buffer;
    while (1) {
        return if $self->{+SIGNAL};

        my $line = <$reader>;
        unless(defined $line) {
            $ipc->wait() if $ipc;
            sleep 0.02;
            next;
        }

        if ($buffer) {
            $line = $buffer . $line;
            $buffer = undef;
        }

        unless (substr($line, -1, 1) eq "\n") {
            $buffer //= "";
            $buffer .= $line;
            next;
        }

        print $logger $line if $logger;
        my $e = decode_json($line);
        last unless defined $e;

        bless($e, 'Test2::Harness::Event');

        if (my $final = $e->{facet_data}->{harness_final}) {
            $self->{+FINAL_DATA} = $final;
        }
        else {
            $_->render_event($e) for @$renderers;

            $self->{+COVERAGE_AGGREGATOR}->process_event($e) if $cover && (
                $e->{facet_data}->{coverage} ||
                $e->{facet_data}->{harness_job_end} ||
                $e->{facet_data}->{harness_job_start}
            );
        }

        $self->{+TESTS_SEEN}++   if $e->{facet_data}->{harness_job_launch};
        $self->{+ASSERTS_SEEN}++ if $e->{facet_data}->{assert};

        $_->handle_event($e, $settings) for @$plugins;

        $ipc->wait() if $ipc;
    }
}


sub stop {
    my $self = shift;

    my $settings  = $self->settings;
    my $renderers = $self->renderers;
    my $logger    = $self->logger;
    close($logger) if $logger;

    $self->teardown_plugins();

    $_->finish() for @$renderers;

    my $ipc = $self->ipc;
    print STDERR "Waiting for child processes to exit...\n" if $self->{+SIGNAL};
    $ipc->wait(all => 1);
    $ipc->stop;

    my $cover = $settings->logging->write_coverage;
    if ($cover) {
        my $coverage = $self->{+COVERAGE_AGGREGATOR}->coverage;

        if (open(my $fh, '>', $cover)) {
            print $fh encode_json($coverage);
            close($fh);
        }
        else {
            warn "Could not write coverage file '$cover': $!";
        }
    }

    unless ($settings->display->quiet > 2) {
        printf STDERR "\nNo tests were seen!\n" unless $self->{+TESTS_SEEN};

        printf("\nKeeping work dir: %s\n", $self->workdir)
            if $settings->debug->keep_dirs;

        print "\nWrote log file: " . $settings->logging->log_file . "\n"
            if $settings->logging->log;

        print "\nWrote coverage file: $cover\n"
            if $cover;
    }
}

sub terminate_queue {
    my $self = shift;

    $self->tasks_queue->end();
    $self->state->end_queue();
}

sub build_run {
    my $self = shift;

    return $self->{+RUN} if $self->{+RUN};

    my $settings = $self->settings;
    my $dir = $self->workdir;

    my $run = $settings->build(run => 'Test2::Harness::Run');

    mkdir($run->run_dir($dir)) or die "Could not make run dir: $!";
    chmod_tmp($dir);

    return $self->{+RUN} = $run;
}

sub state {
    my $self = shift;

    $self->{+STATE} //= Test2::Harness::Runner::State->new(
        workdir   => $self->workdir,
        job_count => $self->job_count,
        no_poll   => 1,
    );
}

sub job_count {
    my $self = shift;

    return $self->settings->runner->job_count;
}

sub run_queue {
    my $self = shift;
    my $dir = $self->workdir;
    return $self->{+RUN_QUEUE} //= Test2::Harness::Util::Queue->new(file => File::Spec->catfile($dir, 'run_queue.jsonl'));
}

sub tasks_queue {
    my $self = shift;

    $self->{+TASKS_QUEUE} //= Test2::Harness::Util::Queue->new(
        file => File::Spec->catfile($self->build_run->run_dir($self->workdir), 'queue.jsonl'),
    );
}

sub finder_args {()}

sub populate_queue {
    my $self = shift;

    my $run = $self->build_run();
    my $settings = $self->settings;
    my $finder = $settings->build(finder => $settings->finder->finder, $self->finder_args);

    my $state = $self->state;
    my $tasks_queue = $self->tasks_queue;
    my $plugins = $settings->harness->plugins;

    $state->queue_run($run->queue_item($plugins));

    my @files = @{$finder->find_files($plugins, $self->settings)};

    for my $plugin (@$plugins) {
        next unless $plugin->can('sort_files');
        @files = $plugin->sort_files(@files);
    }

    my $job_count = 0;
    for my $file (@files) {
        my $task = $file->queue_item(++$job_count, $run->run_id,
            $settings->check_prefix('display') ? (verbose => $settings->display->verbose) : (),
        );
        $state->queue_task($task);
        $tasks_queue->enqueue($task);
    }

    $state->stop_run($run->run_id);

    return $job_count;
}

sub produce_summary {
    my $self = shift;
    my ($pass) = @_;

    my $settings = $self->settings;

    my $time_data = {
        start => $settings->harness->start,
        stop  => time(),
    };

    $time_data->{wall} = $time_data->{stop} - $time_data->{start};

    my @times = times();
    @{$time_data}{qw/user system cuser csystem/} = @times;
    $time_data->{cpu} = sum @times;

    my $cpu_usage = int($time_data->{cpu} / $time_data->{wall} * 100);

    $self->write_summary($pass, $time_data, $cpu_usage);
    $self->render_summary($pass, $time_data, $cpu_usage);
}

sub write_summary {
    my $self = shift;
    my ($pass, $time_data, $cpu_usage) = @_;

    my $file = $self->settings->debug->summary or return;

    my $final_data = $self->{+FINAL_DATA};

    my $failures = @{$final_data->{failed} // []};

    my %data = (
        %$final_data,

        pass => $pass ? JSON->true : JSON->false,

        total_failures => $failures              // 0,
        total_tests    => $self->{+TESTS_SEEN}   // 0,
        total_asserts  => $self->{+ASSERTS_SEEN} // 0,

        cpu_usage => $cpu_usage,

        times => $time_data,
    );

    require Test2::Harness::Util::File::JSON;
    my $jfile = Test2::Harness::Util::File::JSON->new(name => $file);
    $jfile->write(\%data);

    print "\nWrote summary file: $file\n\n";

    return;
}

sub render_summary {
    my $self = shift;
    my ($pass, $time_data, $cpu_usage) = @_;

    return if $self->settings->display->quiet > 1;

    my $final_data = $self->{+FINAL_DATA};
    my $failures = @{$final_data->{failed} // []};

    my @summary = (
        $failures ? ("     Fail Count: $failures") : (),
        "     File Count: $self->{+TESTS_SEEN}",
        "Assertion Count: $self->{+ASSERTS_SEEN}",
        $time_data ? (
            sprintf("      Wall Time: %.2f seconds", $time_data->{wall}),
            sprintf("       CPU Time: %.2f seconds (usr: %.2fs | sys: %.2fs | cusr: %.2fs | csys: %.2fs)", @{$time_data}{qw/cpu user system cuser csystem/}),
            sprintf("      CPU Usage: %i%%", $cpu_usage),
        ) : (),
    );

    my $res = "    -->  Result: " . ($pass ? 'PASSED' : 'FAILED') . "  <--";
    if ($self->settings->display->color && USE_ANSI_COLOR) {
        my $color = $pass ? Term::ANSIColor::color('bold bright_green') : Term::ANSIColor::color('bold bright_red');
        my $reset = Term::ANSIColor::color('reset');
        $res = "$color$res$reset";
    }
    push @summary => $res;

    my $msg = "Yath Result Summary";
    my $length = max map { length($_) } @summary;
    my $prefix = ($length - length($msg)) / 2;

    print "\n";
    print " " x $prefix;
    print "$msg\n";
    print "-" x $length;
    print "\n";
    print join "\n" => @summary;
    print "\n";
}

sub render_final_data {
    my $self = shift;
    my ($final_data) = @_;

    return if $self->settings->display->quiet > 1;

    if (my $rows = $final_data->{retried}) {
        print "\nThe following jobs failed at least once:\n";
        print join "\n" => table(
            header => ['Job ID', 'Times Run', 'Test File', "Succeeded Eventually?"],
            rows   => $rows,
        );
        print "\n";
    }

    if (my $rows = $final_data->{failed}) {
        print "\nThe following jobs failed:\n";
        print join "\n" => table(
            header => ['Job ID', 'Test File'],
            rows   => $rows,
        );
        print "\n";
    }

    if (my $rows = $final_data->{halted}) {
        print "\nThe following jobs requested all testing be halted:\n";
        print join "\n" => table(
            header => ['Job ID', 'Test File', "Reason"],
            rows   => $rows,
        );
        print "\n";
    }

    if (my $rows = $final_data->{unseen}) {
        print "\nThe following jobs never ran:\n";
        print join "\n" => table(
            header => ['Job ID', 'Test File'],
            rows   => $rows,
        );
        print "\n";
    }
}

sub logger {
    my $self = shift;

    return $self->{+LOGGER} if $self->{+LOGGER};

    my $settings = $self->{+SETTINGS};

    return unless $settings->logging->log;

    my $file = $settings->logging->log_file;

    if ($settings->logging->bzip2) {
        no warnings 'once';
        require IO::Compress::Bzip2;
        $self->{+LOGGER} = IO::Compress::Bzip2->new($file) or die "Could not open log file '$file': $IO::Compress::Bzip2::Bzip2Error";
        return $self->{+LOGGER};
    }
    elsif ($settings->logging->gzip) {
        no warnings 'once';
        require IO::Compress::Gzip;
        $self->{+LOGGER} = IO::Compress::Gzip->new($file) or die "Could not open log file '$file': $IO::Compress::Gzip::GzipError";
        return $self->{+LOGGER};
    }

    return $self->{+LOGGER} = open_file($file, '>');
}

sub renderers {
    my $self = shift;

    return $self->{+RENDERERS} if $self->{+RENDERERS};

    my $settings = $self->{+SETTINGS};

    my @renderers;
    for my $class (@{$settings->display->renderers->{'@'}}) {
        require(mod2file($class));
        my $args     = $settings->display->renderers->{$class};
        my $renderer = $class->new(@$args, settings => $settings);
        push @renderers => $renderer;
    }

    return $self->{+RENDERERS} = \@renderers;
}

sub start_auditor {
    my $self = shift;

    my $run = $self->build_run();
    my $settings = $self->settings;

    my $ipc = $self->ipc;
    $ipc->spawn(
        stdin       => $self->auditor_reader(),
        stdout      => $self->auditor_writer(),
        no_set_pgrp => 1,
        command     => [
            $^X, cover(), $settings->harness->script,
            (map { "-D$_" } @{$settings->harness->dev_libs}),
            '--no-scan-plugins',    # Do not preload any plugin modules
            auditor => 'Test2::Harness::Auditor',
            $run->run_id,
        ],
    );

    close($self->auditor_writer());
}

sub start_collector {
    my $self = shift;

    my $dir        = $self->workdir;
    my $run        = $self->build_run();
    my $settings   = $self->settings;
    my $runner_pid = $self->runner_pid;

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not create pipe";

    my $ipc = $self->ipc;
    $ipc->spawn(
        stdout      => $self->collector_writer,
        stdin       => $rh,
        no_set_pgrp => 1,
        command     => [
            $^X, cover(), $settings->harness->script,
            (map { "-D$_" } @{$settings->harness->dev_libs}),
            '--no-scan-plugins',    # Do not preload any plugin modules
            collector => 'Test2::Harness::Collector',
            $dir, $run->run_id, $runner_pid,
            show_runner_output => 1,
        ],
    );

    close($rh);
    print $wh encode_json($run) . "\n";
    close($wh);

    close($self->collector_writer());
}

sub start_runner {
    my $self = shift;
    my %args = @_;

    $args{monitor_preloads} //= $self->monitor_preloads;

    my $settings = $self->settings;
    my $dir = $settings->workspace->workdir;

    my @prof;
    if ($settings->runner->nytprof) {
        push @prof => '-d:NYTProf';
    }

    my $ipc = $self->ipc;
    my $proc = $ipc->spawn(
        stderr => File::Spec->catfile($dir, 'error.log'),
        stdout => File::Spec->catfile($dir, 'output.log'),
        env_vars => { @prof ? (NYTPROF => 'start=no:addpid=1') : () },
        no_set_pgrp => 1,
        command => [
            $^X, @prof, cover(), $settings->harness->script,
            (map { "-D$_" } @{$settings->harness->dev_libs}),
            '--no-scan-plugins', # Do not preload any plugin modules
            runner => $dir,
            %args,
        ],
    );

    $self->{+RUNNER_PID} = $proc->pid;

    return $proc;
}

sub parse_args {
    my $self = shift;
    my $settings = $self->settings;
    my $args = $self->args;

    my $dest = $settings->finder->search;
    for my $arg (@$args) {
        next if $arg eq '--';
        if ($arg eq '::') {
            $dest = $settings->run->test_args;
            next;
        }

        push @$dest => $arg;
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::test - Run tests

=head1 DESCRIPTION

This yath command (which is also the default command) will run all the test
files for the current project. If no test files are specified this command will
look for the 't', and 't2' directories, as well as the 'test.pl' file.

This command is always recursive when given directories.

This command will add 'lib', 'blib/arch' and 'blib/lib' to the perl path for
you by default (after any -I's). You can specify -l if you just want lib, -b if
you just want the blib paths. If you specify both -l and -b both will be added
in the order you specify (order relative to any -I options will also be
preserved.  If you do not specify they will be added in this order: -I's, lib,
blib/lib, blib/arch. You can also add --no-lib and --no-blib to avoid both.

Any command line argument that is not an option will be treated as a test file
or directory of test files to be run.

If you wish to specify the ARGV for tests you may append them after '::'. This
is mainly useful for Test::Class::Moose and similar tools. EVERY test run will
get the same ARGV.


=head1 USAGE

    $ yath [YATH OPTIONS] test [COMMAND OPTIONS]

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

