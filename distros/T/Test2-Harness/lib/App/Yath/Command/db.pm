package App::Yath::Command::db;
use strict;
use warnings;

our $VERSION = '2.000005';

use App::Yath::Server;
use App::Yath::Schema::Util qw/schema_config_from_settings/;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

sub summary     { "Start a yath database server" }
sub description { "Starts a database that can be used to temporarily store data (data is deleted when server shuts down)" }
sub group       { "database" }

sub cli_args { "" }

use Getopt::Yath;
include_options(
    'App::Yath::Options::Yath',
    'App::Yath::Options::DB',
    'App::Yath::Options::Server',
);

sub run {
    my $self = shift;

    my $args = $self->args;
    my $settings = $self->settings;

    my $daemon = $settings->server->daemon;

    if ($daemon) {
        my $pid = fork // die "Could not fork";
        exit(0) if $pid;

        POSIX::setsid();
        setpgrp(0, 0);

        $pid = fork // die "Could not fork";
        exit(0) if $pid;
    }

    my $ephemeral = $settings->server->ephemeral;
    unless($ephemeral) {
        $ephemeral = 'Auto';
        $settings->server->ephemeral($ephemeral);
    }

    my $config = schema_config_from_settings($settings, ephemeral => $ephemeral);

    my $qdb_params = {
        single_user => $settings->server->single_user // 0,
        single_run  => $settings->server->single_run  // 0,
        no_upload   => $settings->server->no_upload   // 0,
        email       => $settings->server->email       // undef,
    };

    my $server = App::Yath::Server->new(schema_config => $config, qdb_params => $qdb_params);
    $server->start_ephemeral_db;

    my $dsn = $config->dbi_dsn;

    print "\nDBI_DSN: $dsn\n";

    my $done = 0;
    $SIG{TERM} = sub { $done++; print "Caught SIGTERM shutting down...\n" unless $daemon; $SIG{TERM} = 'DEFAULT' };
    $SIG{INT}  = sub { $done++; print "Caught SIGINT shutting down...\n"  unless $daemon; $SIG{INT}  = 'DEFAULT' };

    if ($settings->server->shell) {
        print "\n";
        local $ENV{YATH_SHELL} = 1;
        system($ENV{SHELL});
    }
    else {
        $server->qdb->watcher->detach if $daemon;
        sleep 1 until $done;
    }

    $server->stop_ephemeral_db if $server->qdb;

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::db - Start a yath database server

=head1 DESCRIPTION

Starts a database that can be used to temporarily store data (data is deleted when server shuts down)

=head1 USAGE

    $ yath [YATH OPTIONS] db [COMMAND OPTIONS]

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

