package App::Yath::Command::server;
use strict;
use warnings;

use feature 'state';

use App::Yath::Server;

use App::Yath::Schema::Util qw/schema_config_from_settings format_uuid_for_db/;
use Test2::Util::UUID qw/gen_uuid/;
use App::Yath::Schema::ImportModes qw/is_mode/;

use Test2::Harness::Util qw/clean_path/;

our $VERSION = '2.000005';

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw{
    <server
    <config
};

sub summary     { "Start a yath web server" }
sub description { "Starts a web server that can be used to view test runs in a web browser" }
sub group       { "server" }

sub cli_args { "[log1.jsonl[.gz|.bz2] [log2.jsonl[.gz|.bz2]]]" }
sub cli_dot  { "[:: STARMAN/PLACKUP ARGS]" }

sub accepts_dot_args { 1 }

sub set_dot_args {
    my $class = shift;
    my ($settings, $dot_args) = @_;
    push @{$settings->webserver->launcher_args} => @$dot_args;
    return;
}

use Getopt::Yath;
include_options(
    'App::Yath::Options::Term',
    'App::Yath::Options::Yath',
    'App::Yath::Options::DB',
    'App::Yath::Options::WebServer',
    'App::Yath::Options::Server',
);

option_group {group => 'server', category => "Server Options"} => sub {
    option dev => (
        type => 'Bool',
        default => 0,
        description => 'Launches in "developer mode" which accepts some developer commands while the server is running.',
    );
};


sub run {
    my $self = shift;
    my $pid = $$;

    $0 = "yath-server";

    my $args = $self->args;
    my $settings = $self->settings;

    my $dev       = $settings->server->dev;
    my $shell     = $settings->server->shell;
    my $daemon    = $settings->server->daemon;
    my $ephemeral = $settings->server->ephemeral;

    die "Cannot combine --dev, --shell, and/or --daemon.\n" if ($dev && $daemon) || ($dev && $shell) || ($shell && $daemon);

    if ($daemon) {
        my $pid = fork // die "Could not fork";
        exit(0) if $pid;

        POSIX::setsid();
        setpgrp(0, 0);

        $pid = fork // die "Could not fork";
        exit(0) if $pid;

        open(STDOUT, '>>', '/dev/null');
        open(STDERR, '>>', '/dev/null');
    }

    my $config = $self->{+CONFIG} = schema_config_from_settings($settings, ephemeral => $ephemeral);

    my $qdb_params = {
        single_user => $settings->server->single_user // 0,
        single_run  => $settings->server->single_run  // 0,
        no_upload   => $settings->server->no_upload   // 0,
        email       => $settings->server->email       // undef,
    };

    my $server = $self->{+SERVER} = App::Yath::Server->new(schema_config => $config, $settings->webserver->all, qdb_params => $qdb_params);
    $server->start_server;

    my $user = $config->schema->resultset('User')->create({username => $ENV{USER}, password => 'password', realname => $ENV{USER}});
    my $api_key = $config->schema->resultset('ApiKey')->create({value => format_uuid_for_db(gen_uuid()), user_id => $user->user_id, name => "ephemeral"});
    $ENV{YATH_API_KEY} = $api_key->value;

    my $done = 0;
    $SIG{TERM} = sub { $done++; print "Caught SIGTERM shutting down...\n" unless $daemon; $SIG{TERM} = 'DEFAULT' };
    $SIG{INT}  = sub { $done++; print "Caught SIGINT shutting down...\n"  unless $daemon; $SIG{INT}  = 'DEFAULT' };

    for my $log (@{$args // []}) {
        $self->load_file($log);
    }

    sleep 1;

    $ENV{YATH_URL} = "http://" . $settings->webserver->host . ":" . $settings->webserver->port . "/";
    print "\nYath URL: $ENV{YATH_URL}\n\n";

    if ($shell) {
        local $ENV{YATH_SHELL} = 1;
        system($ENV{SHELL});
    }
    else {
        SERVER_LOOP: until ($done) {
            if ($dev && !$daemon) {
                $ENV{T2_HARNESS_SERVER_DEV} = 1;

                unless(eval { $done = $self->shell($pid); 1 }) {
                    warn $@;
                    $done = 1;
                }
            }
            else {
                sleep 1;
            }
        }
    }

    if ($pid == $$) {
        $server->stop_server if $server->pid;
    }
    else {
        die "Scope leak, wrong PID";
    }

    return 0;
}


sub load_file {
    my $self = shift;
    my ($file, $mode, $project) = @_;

    my $config = $self->{+CONFIG};

    die "No .jsonl[.*] log file provided.\n" unless $file;
    die "Invalid log file '$file': File not found, or not a normal file.\n" unless -f $file;
    $file = clean_path($file);

    $mode //= 'complete';

    state %projects;

    unless($project) {
        my $base = $file;
        $base =~ s{^.*/}{}g;
        $base =~ s{\.jsonl.*$}{}g;
        $base =~ s/-\d.*$//g;
        $project = $base || "devshell";
    }

    unless ($projects{$project}) {
        my $p = $config->schema->resultset('Project')->find_or_create({name => $project});
        $projects{$project} = $p;
    }

    my $logfile = $config->schema->resultset('LogFile')->create({
        name        => $file,
        local_file  => $file =~ m{^/} ? $file : "./demo/$file",
    });

    state $user = $config->schema->resultset('User')->find_or_create({username => 'root', password => 'root', realname => 'root'});

    my $run = $config->schema->resultset('Run')->create({
        run_uuid   => format_uuid_for_db(gen_uuid()),
        user_id    => $user->user_id,
        mode       => $mode,
        status     => 'pending',
        canon      => 1,
        project_id => $projects{$project}->project_id,

        log_file_id => $logfile->log_file_id,
    });

    return $run;
}

sub shell {
    my $self = shift;
    my ($pid) = @_;

    # Return that we should exit if the PID is wrong.
    return 1 unless $pid == $$;

    my $settings = $self->settings;
    my $server = $self->{+SERVER};
    my $config = $self->{+CONFIG};

    $SIG{TERM} = sub { $SIG{TERM} = 'DEFAULT'; die "Cought SIGTERM exiting...\n" };
    $SIG{INT}  = sub { $SIG{INT}  = 'DEFAULT'; die "Cought SIGINT exiting...\n" };

    STDERR->autoflush();

    my $dsn = $config->dbi_dsn;

    print "DBI_DSN: $dsn\n\n";
    print "\n";
    print "| Yath Server Developer Shell       |\n";
    print "| type 'help', 'h', or '?' for help |\n";

    use Term::ReadLine;
    my $term   = Term::ReadLine->new('Yath dev console');
    my $OUT    = $term->OUT || \*STDOUT;

    my $cmds = $self->command_list();
    $term->Attribs->{'attempted_completion_function'} = sub {
        my ($text, $start, $end) = @_;

        if ($start !~ m/\s/) {
            my @found;
            for my $set (@$cmds) {
                next unless $set->[0] =~ m/^\Q$text\E/;
                push @found => $set->[0];
            }

            return @found;
        }

        my ($fname) = reverse(split m/\s+/, $text);

        return Term::ReadLine::Gnu->filename_completion_function($fname // '', 0);
    };

    my $prompt = "\n> ";
    while (1) {
        my $in = $term->readline($prompt);

        return 1 if !defined($in);
        chomp($in);
        next unless length($in);

        return 1 if $in =~ m/^(q|x|exit|quit)$/;

        $term->addhistory($in);

        if ($in =~ m/^(help|h|\?)(?:\s(.+))?$/) {
            $self->shell_help($1);
            next;
        }

        my ($cmd, $args) = split /\s/, $in, 2;

        my $meth = "shell_$cmd";
        if ($self->can($meth)) {
            eval { $self->$meth($args); 1 } or warn $@;
        }
        else {
            print STDERR "Invalid command '$in'\n";
        }
    }
}

sub shell_help_text { "Show command list." }
sub shell_help {
    my $self = shift;
    my $class = ref($self);

    print "\nAvailable commands:\n";
    printf(" %-12s   %s\n", "[q]uit", "Quit the program.");
    printf(" %-12s   %s\n", "e[x]it", "Exit the program.");
    printf(" %-12s   %s\n", "[h]elp", "Show this help.");
    printf(" %-12s   %s\n", "?", "Show this help.");

    my $cmds = $self->command_list();
    for my $set (@$cmds) {
        my ($cmd, $text) = @$set;
        next if $cmd eq 'help';
        printf(" %-12s   %s\n", $cmd, $text);
    }

    print "\n";
}

sub command_list {
    my $self = shift;
    my $class = ref($self) || $self;

    my @out;

    my $stash = do { no strict 'refs'; \%{"$class\::"} };
    for my $sym (sort keys %$stash) {
        next unless $sym =~ m/^shell_(.*)/;
        my $cmd = $1;
        next if $sym =~ m/_text$/;
        next unless $self->can($sym);

        my $text = "${sym}_text";
        $text = $self->can($text) ? $self->$text() : 'No description.';

        push @out => [$cmd, $text];
    }

    return \@out;
}

sub shell_reload_text { "Restart web server (does not restart database or importers)." }
sub shell_reload { $_[0]->server->restart_server }

sub shell_reloaddb_text { "Restart database (data is lost)." }
sub shell_reloaddb {
    my $self = shift;

    my $server = $self->server;
    $server->stop_server;
    $server->stop_importers;
    $server->reset_ephemeral_db;
    $server->start_server;
}

sub shell_reloadimp_text { "Restart the importers." }
sub shell_reloadimp { $_[0]->restart_importers() }

sub shell_db_text { "Open the database." }
sub shell_db { $_[0]->server->qdb->shell('harness_ui') }

sub shell_shell_text { "Open a shell" }
sub shell_shell { $ENV{YATH_SHELL} = 1; system($ENV{SHELL}) }

sub shell_load_text { "Load a database file (filename given as argument)" }
sub shell_load {
    my $self = shift;
    my ($args) = @_;

    my ($file, $mode, $project);
    for my $part (split /\s+/, $args) {
        if (is_mode($part)) {
            die "Multiple modes provided: $mode and $part.\n" if $mode;
            $mode = $part;
        }
        elsif ($part =~ m/\.jsonl/) {
            die "Multiple files provided: $file and $part.\n" if $file;
            $file = $part;
        }
        else {
            die "Multiple projects provided: $project and $part.\n" if $project;
            $project = $part;
        }
    }

    $self->load_file($file, $mode, $project);
}

{
    no warnings 'once';
    *shell_r        = \*shell_reload;
    *shell_r_text   = \*shell_reload_text;
    *shell_rdb      = \*shell_reloaddb;
    *shell_rdb_text = \*shell_reloaddb_text;
    *shell_ri       = \*shell_reloadimp;
    *shell_ri_text  = \*shell_reloadimp_text;
    *shell_l        = \*shell_load;
    *shell_l_text   = \*shell_load_text;
    *shell_s        = \*shell_shell;
    *shell_s_text   = \*shell_shell_text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::server - Start a yath web server

=head1 DESCRIPTION

Starts a web server that can be used to view test runs in a web browser

=head1 USAGE

    $ yath [YATH OPTIONS] server [COMMAND OPTIONS] [COMMAND ARGUMENTS]

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

=head3 Server Options

=over 4

=item --daemon

=item --no-daemon

Run the server in the background.


=item --dev

=item --no-dev

Launches in "developer mode" which accepts some developer commands while the server is running.


=item --email ARG

=item --email=ARG

=item --no-email

When using an ephemeral database you can use this to set a 'from' email address for email sent from this server.


=item --ephemeral

=item --ephemeral=Auto

=item --ephemeral=MySQL

=item --ephemeral=SQLite

=item --ephemeral=MariaDB

=item --ephemeral=Percona

=item --ephemeral=PostgreSQL

=item --no-ephemeral

Use a temporary 'ephemeral' database that will be destroyed when the server exits.


=item --no-upload

=item --no-no-upload

When using an ephemeral database you can use this to enable no-upload mode which removes the upload workflow.


=item --shell

=item --no-shell

Drop into a shell where the server and/or database env vars are set so that yath commands will use the started server.


=item --single-run

=item --no-single-run

When using an ephemeral database you can use this to enable single run mode which causes the server to take you directly to the first run.


=item --single-user

=item --no-single-user

When using an ephemeral database you can use this to enable single user mode to avoid login and user credentials.


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

=head3 Web Server Options

=over 4

=item --host ARG

=item --host=ARG

=item --no-host

Host/Address to bind to, default 'localhost'.


=item --importers ARG

=item --importers=ARG

=item --no-importers

Number of log importer processes.


=item --launcher ARG

=item --launcher=ARG

=item --no-launcher

Command to use to launch the server (--server argument to Plack::Runner)

Note: You can pass custom args to the launcher after a '::' like `yath server [ARGS] [LOG FILES(s)] :: [LAUNCHER ARGS]`


=item --launcher-args "--reload"

=item --launcher-args="--reload"

=item --no-launcher-args

Set additional options for the loader.

Note: It is better to put loader arguments after '::' at the end of the command line.

Note: Can be specified multiple times


=item --port ARG

=item --port=ARG

=item --no-port

Port to listen on.

Note: This is passed to the launcher via `launcher --port PORT`


=item --port-command ARG

=item --port-command=ARG

=item --no-port-command

Command to run that returns a port number.


=item --workers ARG

=item --workers=ARG

=item --no-workers

Number of workers. Defaults to the number of cores, or 5 if System::Info is not installed.

Note: This is passed to the launcher via `launcher --workers WORKERS`


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

