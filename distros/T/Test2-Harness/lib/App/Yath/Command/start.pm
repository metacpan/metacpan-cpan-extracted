package App::Yath::Command::start;
use strict;
use warnings;

our $VERSION = '2.000005';

use App::Yath::IPC;

use Test2::Harness::Instance;
use Test2::Harness::TestSettings;
use Test2::Harness::IPC::Protocol;
use Test2::Harness::Collector;
use Test2::Harness::Collector::IOParser;

use Test2::Harness::Util qw/mod2file/;
use Test2::Harness::IPC::Util qw/pid_is_running set_procname/;
use Test2::Harness::Util::JSON qw/encode_json/;

use File::Path qw/remove_tree/;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw{
    +log_file

    +ipc
    +yath_ipc
    +runner
    +scheduler
    +resources
    +instance
    +collector
};

sub option_modules {
    return (
        'App::Yath::Options::IPC',
        'App::Yath::Options::Harness',
        'App::Yath::Options::Workspace',
        'App::Yath::Options::Resource',
        'App::Yath::Options::Runner',
        'App::Yath::Options::Scheduler',
        'App::Yath::Options::Yath',
        'App::Yath::Options::Renderer',
        'App::Yath::Options::Tests',
        'App::Yath::Options::DB',
        'App::Yath::Options::WebClient',
    );
}

use Getopt::Yath;
include_options(__PACKAGE__->option_modules);

use App::Yath::Options::Tests qw/ set_dot_args /;

option_group {group => 'start', category => "Start Options"} => sub {
    option foreground => (
        short => 'f',
        alt => ['no-daemon'],
        alt_no => ['daemon'],
        type => 'Bool',
        description => "Keep yath in the forground instead of daemonizing and returning you to the shell",
        default     => 0,
    );
};

sub load_plugins   { 1 }
sub load_resources { 1 }
sub load_renderers { 1 }

sub accepts_dot_args { 1 }
sub args_include_tests { 0 }

sub group { 'daemon' }

sub summary  { "Start a test runner" }

sub description {
    return <<"    EOT";
This command is used to start a yath daemon that will load up and run tests on demand.
(Use --no-daemon or -f to start one and keep it in the foreground)
    EOT
}

sub process_base_name { shift->should_daemonize ? "daemon" : "instance" }
sub process_collector_name { "collector" }

sub check_argv {
    my $self = shift;

    return unless @{$self->{+ARGS} // []};

    die "Invalid arguments to 'start' command: " . join(", " => @{$self->{+ARGS} // []}) . "\n";
}

sub munge_settings {
    my $self = shift;

    my $settings = $self->settings;
    $settings->runner->reloader('Test2::Harness::Reloader')
        unless $settings->runner->reloader;
}

sub run {
    my $self = shift;

    $self->check_argv();

    set_procname(
        set => [$self->process_base_name, "launcher"],
        prefix => $self->{+SETTINGS}->harness->procname_prefix,
    );

    $self->munge_settings();

    $self->become_daemon if $self->should_daemonize();

    if ($self->start_daemon_runner) {
        my $ipc_specs = $self->yath_ipc->validate_ipc();
        print "Creating ipc file: $ipc_specs->{file}\n";
    }

    # Need to get this pre-fork
    my $collector = $self->collector();

    my $pid = fork // die "Could not fork: $!";
    return $self->become_collector($pid) if $pid;
    return $self->become_instance();
}

sub should_daemonize {
    my $self = shift;

    my $settings = $self->settings;

    return 0 unless $settings->check_group('start');
    return 0 if $settings->start->foreground;
    return 1;
}

sub become_daemon {
    my $self = shift;

    require POSIX;

    close(STDIN);
    open(STDIN, '<', "/dev/null") or die "Could not open devnull: $!";

    POSIX::setsid();

    my $pid = fork // die "Could not fork";
    if ($pid) {
        sleep 2;
        kill('HUP', $pid);
        POSIX::_exit(0);
    }
}

sub become_instance {
    my $self = shift;

    set_procname(
        set => [$self->process_base_name],
        prefix => $self->{+SETTINGS}->harness->procname_prefix,
    );

    my $collector = $self->collector();
    $collector->setup_child_output();

    $self->instance->run;

    return 0;
}

sub become_collector {
    my $self = shift;
    my ($pid) = @_;

    my $settings = $self->settings;

    set_procname(
        set    => [$self->process_base_name],
        append => [$self->process_collector_name],
        prefix => $self->{+SETTINGS}->harness->procname_prefix,
    );

    my $collector = $self->collector();

    my $exit = $collector->process($pid);

    remove_tree($settings->workspace->workdir, {safe => 1, keep_root => 0})
        unless $settings->workspace->keep_dirs;

    return $exit;
}

sub log_file {
    my $self = shift;
    return $self->{+LOG_FILE} //= File::Spec->catfile($self->settings->workspace->workdir, 'log.jsonl');
}

sub collector {
    my $self = shift;

    return $self->{+COLLECTOR} if $self->{+COLLECTOR};

    my $settings = $self->settings;

    my $out_file = $self->log_file;

    my $verbose = 2;
    $verbose = 0 unless $settings->start->foreground;
    $verbose = 0 if $settings->renderer->quiet;
    my $renderers = App::Yath::Options::Renderer->init_renderers($settings, verbose => $verbose, progress => 0);

    $SIG{HUP} = sub {
        $renderers = undef;
        close(STDIN);
        close(STDOUT);
        close(STDERR);
    };

    open(my $log, '>', $out_file) or die "Could not open '$out_file' for writing: $!";
    $log->autoflush(1);

    my $parser = Test2::Harness::Collector::IOParser->new(job_id => 0, job_try => 0, run_id => 0, type => 'runner');
    return $self->{+COLLECTOR} = Test2::Harness::Collector->new(
        parser       => $parser,
        job_id       => 0,
        job_try      => 0,
        run_id       => 0,
        always_flush => 1,
        output       => sub {
            for my $e (@_) {
                print $log encode_json($e), "\n";
                return unless $renderers;
                $_->render_event($e) for @$renderers;
            }
        }
    );
}

sub instance {
    my $self = shift;

    return $self->{+INSTANCE} if $self->{+INSTANCE};

    my $settings = $self->settings;

    my $ipc       = $self->ipc();
    my $runner    = $self->runner();
    my $scheduler = $self->scheduler();
    my $resources = $self->resources();
    my $plugins = $self->plugins();

    return $self->{+INSTANCE} = Test2::Harness::Instance->new(
        ipc        => $ipc,
        scheduler  => $scheduler,
        runner     => $runner,
        resources  => $resources,
        plugins    => $plugins,
        log_file   => $self->log_file,
        single_run => 1,
    );
}

sub start_daemon_runner { 1 }

sub yath_ipc {
    my $self = shift;
    return $self->{+YATH_IPC} //= App::Yath::IPC->new(settings => $self->settings);
}

sub ipc {
    my $self = shift;
    return $self->{+IPC} //= $self->yath_ipc->start(daemon => $self->start_daemon_runner);
}

sub scheduler {
    my $self = shift;

    return $self->{+SCHEDULER} if $self->{+SCHEDULER};

    my $runner    = $self->runner;
    my $resources = $self->resources;
    my $plugins   = $self->plugins;

    my $scheduler_s = $self->settings->scheduler;
    my $class       = $scheduler_s->class;
    require(mod2file($class));

    return $self->{+SCHEDULER} = $class->new($scheduler_s->all, runner => $runner, resources => $resources, plugins => $plugins);
}

sub runner {
    my $self = shift;

    return $self->{+RUNNER} if $self->{+RUNNER};

    my $plugins  = $self->plugins;
    my $settings = $self->settings;
    my $runner_s = $settings->runner;
    my $class    = $runner_s->class;
    require(mod2file($class));

    my $ts = Test2::Harness::TestSettings->new($settings->tests->all);

    return $self->{+RUNNER} = $class->new($runner_s->all, test_settings => $ts, workdir => $settings->workspace->workdir, plugins => $plugins, is_daemon => $self->start_daemon_runner);
}

sub resources {
    my $self = shift;

    return $self->{+RESOURCES} if $self->{+RESOURCES};

    my $settings = $self->settings;
    my $res_s    = $settings->resource;
    my $res_classes = $res_s->classes;

    my @res_class_list = keys %$res_classes;
    require(mod2file($_)) for @res_class_list;

    @res_class_list = sort { $a->sort_weight <=> $b->sort_weight } @res_class_list;

    my @resources;
    for my $mod (@res_class_list) {
        push @resources => $mod->new($res_s->all, @{$res_classes->{$mod}}, $mod->isa('App::Yath::Resource') ? (settings => $settings) : ());
    }

    return $self->{+RESOURCES} = \@resources;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::start - Start a test runner

=head1 DESCRIPTION

This command is used to start a yath daemon that will load up and run tests on demand.
(Use --no-daemon or -f to start one and keep it in the foreground)


=head1 USAGE

    $ yath [YATH OPTIONS] start [COMMAND OPTIONS]

=head2 OPTIONS

=head3 Database Options

=over 4

=item --db-config ARG

=item --db-config=ARG

=item --no-db-config

Module that implements 'MODULE->yath_db_config(%params)' which should return a App::Yath::Schema::Config instance.

Can also be set with the following environment variables: C<YATH_DB_CONFIG>


=item --db-driver Pg

=item --db-driver MySQL

=item --db-driver SQLite

=item --db-driver MariaDB

=item --db-driver Percona

=item --db-driver PostgreSQL

=item --no-db-driver

DBI Driver to use

Can also be set with the following environment variables: C<YATH_DB_DRIVER>


=item --db-dsn ARG

=item --db-dsn=ARG

=item --no-db-dsn

DSN to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_DSN>


=item --db-host ARG

=item --db-host=ARG

=item --no-db-host

hostname to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_HOST>


=item --db-name ARG

=item --db-name=ARG

=item --no-db-name

Name of the database to use

Can also be set with the following environment variables: C<YATH_DB_NAME>


=item --db-pass ARG

=item --db-pass=ARG

=item --no-db-pass

Password to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PASS>


=item --db-port ARG

=item --db-port=ARG

=item --no-db-port

port to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PORT>


=item --db-socket ARG

=item --db-socket=ARG

=item --no-db-socket

socket to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_SOCKET>


=item --db-user ARG

=item --db-user=ARG

=item --no-db-user

Username to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_USER>, C<USER>


=back

=head3 Harness Options

=over 4

=item -d

=item --dummy

=item --no-dummy

Dummy run, do not actually execute anything

Can also be set with the following environment variables: C<T2_HARNESS_DUMMY>

The following environment variables will be cleared after arguments are processed: C<T2_HARNESS_DUMMY>


=item --procname-prefix ARG

=item --procname-prefix=ARG

=item --no-procname-prefix

Add a prefix to all proc names (as seen by ps).

The following environment variables will be set after arguments are processed: C<T2_HARNESS_PROC_PREFIX>


=back

=head3 IPC Options

=over 4

=item --ipc-address ARG

=item --ipc-address=ARG

=item --no-ipc-address

IPC address to use (usually auto-generated or discovered)


=item --ipc-allow-multiple

=item --no-ipc-allow-multiple

Normally yath will prevent you from starting multiple persistent runners in the same project, this option will allow you to start more than one.


=item --ipc-dir ARG

=item --ipc-dir=ARG

=item --no-ipc-dir

Directory for ipc files

Can also be set with the following environment variables: C<T2_HARNESS_IPC_DIR>, C<YATH_IPC_DIR>


=item --ipc-dir-order ARG

=item --ipc-dir-order=ARG

=item --ipc-dir-order '["json","list"]'

=item --ipc-dir-order='["json","list"]'

=item --ipc-dir-order :{ ARG1 ARG2 ... }:

=item --ipc-dir-order=:{ ARG1 ARG2 ... }:

=item --no-ipc-dir-order

When finding ipc-dir automatically, search in this order, default: ['base', 'temp']

Note: Can be specified multiple times


=item --ipc-file ARG

=item --ipc-file=ARG

=item --no-ipc-file

IPC file used to locate instances (usually auto-generated or discovered)


=item --ipc-peer-pid ARG

=item --ipc-peer-pid=ARG

=item --no-ipc-peer-pid

Optionally a peer PID may be provided


=item --ipc-port ARG

=item --ipc-port=ARG

=item --no-ipc-port

Some IPC protocols require a port, otherwise this should be left empty


=item --ipc-prefix ARG

=item --ipc-prefix=ARG

=item --no-ipc-prefix

Prefix for ipc files


=item --ipc-protocol IPSocket

=item --ipc-protocol AtomicPipe

=item --ipc-protocol UnixSocket

=item --ipc-protocol +Test2::Harness::IPC::Protocol::AtomicPipe

=item --no-ipc-protocol

Specify what IPC Protocol to use. Use the "+" prefix to specify a fully qualified namespace, otherwise Test2::Harness::IPC::Protocol::XXX namespace is assumed.


=back

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

=head3 Resource Options

=over 4

=item -x2

=item --job-slots 2

=item --slots-per-job 2

=item --no-job-slots

This sets the number of slots each job will use (default 1). This is normally set by the ':#' in '-j#:#'.

Can also be set with the following environment variables: C<T2_HARNESS_JOB_CONCURRENCY>

The following environment variables will be cleared after arguments are processed: C<T2_HARNESS_JOB_CONCURRENCY>


=item -RMyResource

=item -R +My::Resource

=item -R MyResource=opt1,opt2

=item -R MyResource,MyOtherResource

=item -R=:{ MyResource opt1,opt2,... }:

=item -R :{ MyResource :{ opt1 opt2 }: }:

=item --resource +My::Resource

=item --resources +My::Resource

=item --resource MyResource=opt1,opt2

=item --resources MyResource=opt1,opt2

=item --resource MyResource,MyOtherResource

=item --resources MyResource,MyOtherResource

=item --resource=:{ MyResource opt1,opt2,... }:

=item --resources=:{ MyResource opt1,opt2,... }:

=item --resource :{ MyResource :{ opt1 opt2 }: }:

=item --resources :{ MyResource :{ opt1 opt2 }: }:

=item --no-resources

Specify resources. Use "+" to give a fully qualified module name. Without "+" "App::Yath::Resource::" and "Test2::Harness::Resource::" will be searched for a matching resource module.

Note: Can be specified multiple times


=item -j4

=item -j8:2

=item --jobs 4

=item --slots 4

=item --jobs 8:2

=item --slots 8:2

=item --job-count 4

=item --job-count 8:2

=item --no-slots

Set the number of concurrent jobs to run. Add a :# if you also wish to designate multiple slots per test. 8:2 means 8 slots, but each test gets 2 slots, so 4 tests run concurrently. Tests can find their concurrency assignemnt in the "T2_HARNESS_MY_JOB_CONCURRENCY" environment variable.

Can also be set with the following environment variables: C<YATH_JOB_COUNT>, C<T2_HARNESS_JOB_COUNT>, C<HARNESS_JOB_COUNT>

The following environment variables will be cleared after arguments are processed: C<YATH_JOB_COUNT>, C<T2_HARNESS_JOB_COUNT>, C<HARNESS_JOB_COUNT>

Note: If System::Info is installed, this will default to half the cpu core count, otherwise the default is 2.


=back

=head3 Runner Options

=over 4

=item --dump-depmap

=item --no-dump-depmap

When using staged preload, dump the depmap for each stage as json files


=item --preload-early key=val

=item --preload-early=key=val

=item --preload-early '{"json":"hash"}'

=item --preload-early='{"json":"hash"}'

=item --preload-early :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --preload-early=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-preload-early

Preload a module when spawning perl to launch the preload stages, before any other preload.

Note: Can be specified multiple times


=item --preload-retry-delay ARG

=item --preload-retry-delay=ARG

=item --no-preload-retry-delay

Time in seconds to wait before trying to load a preload/stage after a failed attempt


=item -P ARG

=item -P=ARG

=item -P '["json","list"]'

=item -P='["json","list"]'

=item -P :{ ARG1 ARG2 ... }:

=item -P=:{ ARG1 ARG2 ... }:

=item --preload ARG

=item --preload=ARG

=item --preloads ARG

=item --preloads=ARG

=item --preload '["json","list"]'

=item --preload='["json","list"]'

=item --preloads '["json","list"]'

=item --preloads='["json","list"]'

=item --preload :{ ARG1 ARG2 ... }:

=item --preload=:{ ARG1 ARG2 ... }:

=item --preloads :{ ARG1 ARG2 ... }:

=item --preloads=:{ ARG1 ARG2 ... }:

=item --no-preloads

Preload a module before running tests

Note: Can be specified multiple times


=item --reload

=item --reload-in-place

=item --no-reload-in-place

Reload modules in-place when possible (Not recommended)


=item --reloader

=item --reloader=ARG

=item --no-reloader

Use a reloader (default Test2::Harness::Reloader) to detect module changes, and reload stages as necessary.


=item --restrict-reload

=item --restrict-reload=ARG

=item --restrict-reload='["json","list"]'

=item --restrict-reload=:{ ARG1 ARG2 ... }:

=item --no-restrict-reload

NO DESCRIPTION - FIX ME

Note: Can be specified multiple times


=item --runner MyRunner

=item --runner +Test2::Harness::Runner::MyRunner

=item --no-runner

Specify what Runner subclass to use. Use the "+" prefix to specify a fully qualified namespace, otherwise Test2::Harness::Runner::XXX namespace is assumed.


=back

=head3 Scheduler Options

=over 4

=item --scheduler MyScheduler

=item --scheduler +Test2::Harness::MyScheduler

=item --no-scheduler

Specify what Scheduler subclass to use. Use the "+" prefix to specify a fully qualified namespace, otherwise Test2::Harness::Scheduler::XXX namespace is assumed.


=back

=head3 Start Options

=over 4

=item -f

=item --no-daemon

=item --foreground

=item --no-foreground

=item --daemon

Keep yath in the forground instead of daemonizing and returning you to the shell


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

=head3 Test Options

=over 4

=item --allow-retry

=item --no-allow-retry

Toggle retry capabilities on and off (default: on)


=item -b

=item --blib

=item --no-blib

(Default: include if it exists) Include 'blib/lib' and 'blib/arch' in your module path (These will come after paths you specify with -D or -I)


=item --cover

=item --cover=-silent,1,+ignore,^t/,+ignore,^t2/,+ignore,^xt,+ignore,^test.pl

=item --no-cover

Use Devel::Cover to calculate test coverage. This disables forking. If no args are specified the following are used: -silent,1,+ignore,^t/,+ignore,^t2/,+ignore,^xt,+ignore,^test.pl

Can also be set with the following environment variables: C<T2_DEVEL_COVER>

The following environment variables will be set after arguments are processed: C<T2_DEVEL_COVER>


=item -E key=val

=item -E=key=val

=item -Ekey=value

=item -E '{"json":"hash"}'

=item -E='{"json":"hash"}'

=item -E:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -E :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -E=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-var key=val

=item --env-var=key=val

=item --env-vars key=val

=item --env-vars=key=val

=item --env-var '{"json":"hash"}'

=item --env-var='{"json":"hash"}'

=item --env-vars '{"json":"hash"}'

=item --env-vars='{"json":"hash"}'

=item --env-var :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-var=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-vars :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-vars=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-env-vars

Set environment variables

Note: Can be specified multiple times


=item --et SECONDS

=item --event-timeout SECONDS

=item --no-event-timeout

Kill test if no output is received within timeout period. (Default: 60 seconds). Add the "# HARNESS-NO-TIMEOUT" comment to the top of a test file to disable timeouts on a per-test basis. This prevents a hung test from running forever.


=item --event-uuids

=item --no-event-uuids

Use Test2::Plugin::UUID inside tests (default: on)


=item -I ARG

=item -I=ARG

=item -I '*.*'

=item -I='*.*'

=item -I '["json","list"]'

=item -I='["json","list"]'

=item -I :{ ARG1 ARG2 ... }:

=item -I=:{ ARG1 ARG2 ... }:

=item --include ARG

=item --include=ARG

=item --include '*.*'

=item --include='*.*'

=item --include '["json","list"]'

=item --include='["json","list"]'

=item --include :{ ARG1 ARG2 ... }:

=item --include=:{ ARG1 ARG2 ... }:

=item --no-include

Add a directory to your include paths

Note: Can be specified multiple times


=item --input ARG

=item --input=ARG

=item --no-input

Input string to be used as standard input for ALL tests. See also: --input-file


=item --input-file ARG

=item --input-file=ARG

=item --no-input-file

Use the specified file as standard input to ALL tests


=item -l

=item --lib

=item --no-lib

(Default: include if it exists) Include 'lib' in your module path (These will come after paths you specify with -D or -I)


=item -m ARG

=item -m=ARG

=item -m '["json","list"]'

=item -m='["json","list"]'

=item -m :{ ARG1 ARG2 ... }:

=item -m=:{ ARG1 ARG2 ... }:

=item --load ARG

=item --load=ARG

=item --load-module ARG

=item --load-module=ARG

=item --load '["json","list"]'

=item --load='["json","list"]'

=item --load :{ ARG1 ARG2 ... }:

=item --load=:{ ARG1 ARG2 ... }:

=item --load-module '["json","list"]'

=item --load-module='["json","list"]'

=item --load-module :{ ARG1 ARG2 ... }:

=item --load-module=:{ ARG1 ARG2 ... }:

=item --no-load

Load a module in each test (after fork). The "import" method is not called.

Note: Can be specified multiple times


=item -M Module

=item -M Module=import_arg1,arg2,...

=item -M '{"Data::Dumper":["Dumper"]}'

=item --loadim Module

=item --load-import Module

=item --loadim Module=import_arg1,arg2,...

=item --loadim '{"Data::Dumper":["Dumper"]}'

=item --load-import Module=import_arg1,arg2,...

=item --load-import '{"Data::Dumper":["Dumper"]}'

=item --no-load-import

Load a module in each test (after fork). Import is called.

Note: Can be specified multiple times


=item --mem-usage

=item --no-mem-usage

Use Test2::Plugin::MemUsage inside tests (default: on)


=item --pet SECONDS

=item --post-exit-timeout SECONDS

=item --no-post-exit-timeout

Stop waiting post-exit after the timeout period. (Default: 15 seconds) Some tests fork and allow the parent to exit before writing all their output. If Test2::Harness detects an incomplete plan after the test exits it will monitor for more events until the timeout period. Add the "# HARNESS-NO-TIMEOUT" comment to the top of a test file to disable timeouts on a per-test basis.


=item -rARG

=item -r ARG

=item -r=ARG

=item --retry ARG

=item --retry=ARG

=item --no-retry

Run any jobs that failed a second time. NOTE: --retry=1 means failing tests will be attempted twice!


=item --retry-iso

=item --retry-isolated

=item --no-retry-isolated

If true then any job retries will be done in isolation (as though -j1 was set)


=item --stream

=item --use-stream

=item --no-stream

=item --TAP

The TAP format is lossy and clunky. Test2::Harness normally uses a newer streaming format to receive test results. There are old/legacy tests where this causes problems, in which case setting --TAP or --no-stream can help.


=item -S ARG

=item -S=ARG

=item -S '["json","list"]'

=item -S='["json","list"]'

=item -S :{ ARG1 ARG2 ... }:

=item -S=:{ ARG1 ARG2 ... }:

=item --switch ARG

=item --switch=ARG

=item --switches ARG

=item --switches=ARG

=item --switch '["json","list"]'

=item --switch='["json","list"]'

=item --switches '["json","list"]'

=item --switches='["json","list"]'

=item --switch :{ ARG1 ARG2 ... }:

=item --switch=:{ ARG1 ARG2 ... }:

=item --switches :{ ARG1 ARG2 ... }:

=item --switches=:{ ARG1 ARG2 ... }:

=item --no-switches

Pass the specified switch to perl for each test. This is not compatible with preload.

Note: Can be specified multiple times


=item --test-arg ARG

=item --test-arg=ARG

=item --test-args ARG

=item --test-args=ARG

=item --test-arg '["json","list"]'

=item --test-arg='["json","list"]'

=item --test-args '["json","list"]'

=item --test-args='["json","list"]'

=item --test-arg :{ ARG1 ARG2 ... }:

=item --test-arg=:{ ARG1 ARG2 ... }:

=item --test-args :{ ARG1 ARG2 ... }:

=item --test-args=:{ ARG1 ARG2 ... }:

=item --no-test-args

Arguments to pass in as @ARGV for all tests that are run. These can be provided easier using the '::' argument separator.

Note: Can be specified multiple times


=item --tlib

=item --no-tlib

(Default: off) Include 't/lib' in your module path (These will come after paths you specify with -D or -I)


=item --unsafe-inc

=item --no-unsafe-inc

perl is removing '.' from @INC as a security concern. This option keeps things from breaking for now.

Can also be set with the following environment variables: C<PERL_USE_UNSAFE_INC>

The following environment variables will be set after arguments are processed: C<PERL_USE_UNSAFE_INC>


=item --fork

=item --use-fork

=item --no-use-fork

(default: on, except on windows) Normally tests are run by forking, which allows for features like preloading. This will turn off the behavior globally (which is not compatible with preloading). This is slower, it is better to tag misbehaving tests with the '# HARNESS-NO-PRELOAD' comment in their header to disable forking only for those tests.

Can also be set with the following environment variables: C<!T2_NO_FORK>, C<T2_HARNESS_FORK>, C<!T2_HARNESS_NO_FORK>, C<YATH_FORK>, C<!YATH_NO_FORK>


=item --timeout

=item --use-timeout

=item --no-use-timeout

(default: on) Enable/disable timeouts


=back

=head3 Web Client Options

=over 4

=item --api-key ARG

=item --api-key=ARG

=item --no-api-key

Yath server API key. This is not necessary if your Yath server instance is set to single-user

Can also be set with the following environment variables: C<YATH_API_KEY>


=item --grace

=item --no-grace

If yath cannot connect to a server it normally throws an error, use this to make it fail gracefully. You get a warning, but things keep going.


=item --request-retry

=item --request-retry=COUNT

=item --no-request-retry

How many times to try an operation before giving up

Note: Can be specified multiple times, counter bumps each time it is used.


=item --url http://my-yath-server.com/...

=item --uri http://my-yath-server.com/...

=item --no-url

Yath server url

Can also be set with the following environment variables: C<YATH_URL>


=back

=head3 Workspace Options

=over 4

=item -C

=item --clear

=item --no-clear

Clear the work directory if it is not already empty


=item -k

=item --keep-dir

=item --keep-dirs

=item --no-keep-dirs

Do not delete directories when done. This is useful if you want to inspect the directories used for various commands.


=item --tmpdir ARG

=item --tmpdir=ARG

=item --tmp-dir ARG

=item --tmp-dir=ARG

=item --no-tmpdir

Use a specific temp directory (Default: create a temp dir under the system one)

Can also be set with the following environment variables: C<T2_HARNESS_TEMP_DIR>, C<YATH_TEMP_DIR>

The following environment variables will be cleared after arguments are processed: C<T2_HARNESS_TEMP_DIR>, C<YATH_TEMP_DIR>

The following environment variables will be set after arguments are processed: C<TMPDIR>, C<TEMPDIR>, C<TMP_DIR>, C<TEMP_DIR>


=item --workdir ARG

=item --workdir=ARG

=item --no-workdir

Set the work directory (Default: new temp directory)

Can also be set with the following environment variables: C<T2_WORKDIR>, C<YATH_WORKDIR>

The following environment variables will be cleared after arguments are processed: C<T2_WORKDIR>, C<YATH_WORKDIR>


=back

=head3 Yath Options

=over 4

=item --base-dir ARG

=item --base-dir=ARG

=item --no-base-dir

Root directory for the project being tested (usually where .yath.rc lives)


=item -D

=item -Dlib

=item -Dlib

=item -D=lib

=item -D"lib/*"

=item --dev-lib

=item --dev-lib=lib

=item --dev-lib="lib/*"

=item --no-dev-lib

This is what you use if you are developing yath or yath plugins to make sure the yath script finds the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.

Note: This option can cause yath to use exec() to reload itself with the correct libraries in place. Each occurence of this argument can cause an additional exec() call. Use --dev-libs-verbose BEFORE any -D calls to see the exec() calls.

Note: Can be specified multiple times


=item --dev-libs-verbose

=item --no-dev-libs-verbose

Be verbose and announce that yath will re-exec in order to have the correct includes (normally yath will just call exec() quietly)


=item -h

=item -h=Group

=item --help

=item --help=Group

=item --no-help

exit after showing help information


=item -p key=val

=item -p=key=val

=item -pkey=value

=item -p '{"json":"hash"}'

=item -p='{"json":"hash"}'

=item -p:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin key=val

=item --plugin=key=val

=item --plugins key=val

=item --plugins=key=val

=item --plugin '{"json":"hash"}'

=item --plugin='{"json":"hash"}'

=item --plugins '{"json":"hash"}'

=item --plugins='{"json":"hash"}'

=item --plugin :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-plugins

Load a yath plugin.

Note: Can be specified multiple times


=item --project ARG

=item --project=ARG

=item --project-name ARG

=item --project-name=ARG

=item --no-project

This lets you provide a label for your current project/codebase. This is best used in a .yath.rc file.


=item --scan-options key=val

=item --scan-options=key=val

=item --scan-options '{"json":"hash"}'

=item --scan-options='{"json":"hash"}'

=item --scan-options(?^:^--(no-)?(?^:scan-(.+))$)

=item --scan-options :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --scan-options=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-scan-options

=item /^--(no-)?scan-(.+)$/

Yath will normally scan plugins for options. Some commands scan other libraries (finders, resources, renderers, etc) for options. You can use this to disable all scanning, or selectively disable/enable some scanning.

Note: This is parsed early in the argument processing sequence, before options that may be earlier in your argument list.

Note: Can be specified multiple times


=item --show-opts

=item --show-opts=group

=item --no-show-opts

Exit after showing what yath thinks your options mean


=item --user ARG

=item --user=ARG

=item --no-user

Username to associate with logs, database entries, and yath servers.

Can also be set with the following environment variables: C<YATH_USER>, C<USER>


=item -V

=item --version

=item --no-version

Exit after showing a helpful usage message


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

