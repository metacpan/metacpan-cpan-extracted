package App::Yath::Options::WebServer;
use strict;
use warnings;

our $VERSION = '2.000005';

use Getopt::Yath;

include_options(
    'App::Yath::Options::DB',
);

option_group {group => 'webserver', category => "Web Server Options"} => sub {
    option launcher => (
        type => 'Scalar',
        default => sub { eval { require Starman; 1 } ? 'Starman' : undef },
        description => 'Command to use to launch the server (--server argument to Plack::Runner) ',
        notes => "You can pass custom args to the launcher after a '::' like `yath server [ARGS] [LOG FILES(s)] :: [LAUNCHER ARGS]`",
        default_text => "Will use 'Starman' if it installed otherwise whatever Plack::Runner uses by default.",
    );

    option port_command => (
        type => 'Scalar',
        description => 'Command to run that returns a port number.',
    );

    option port => (
        type => 'Scalar',
        description => 'Port to listen on.',
        notes => 'This is passed to the launcher via `launcher --port PORT`',
        default => sub {
            my ($option, $settings) = @_;

            if (my $cmd = $settings->webserver->port_command) {
                local $?;
                my $port = `$cmd`;
                die "Port command `$cmd` exited with error code $?.\n" if $?;
                die "Port command `$cmd` did not return a valid port.\n" unless $port;
                chomp($port);
                die "Port command `$cmd` did not return a valid port: $port.\n" unless $port =~ m/^\d+$/;
                return $port;
            }

            return 8080;
        },
    );

    option host => (
        type => 'Scalar',
        default => 'localhost',
        description => "Host/Address to bind to, default 'localhost'.",
    );

    option workers => (
        type => 'Scalar',
        default => sub { eval { require System::Info; System::Info->new->ncore } || 5 },
        default_text => "5, or number of cores if System::Info is installed.",
        description => 'Number of workers. Defaults to the number of cores, or 5 if System::Info is not installed.',
        notes => 'This is passed to the launcher via `launcher --workers WORKERS`',
    );

    option importers => (
        type => 'Scalar',
        default => 2,
        description => 'Number of log importer processes.',
    );

    option launcher_args => (
        type => 'List',
        initialize => sub { [] },
        description => "Set additional options for the loader.",
        notes => "It is better to put loader arguments after '::' at the end of the command line.",
        long_examples => [' "--reload"', '="--reload"'],
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Options::WebServer - FIXME

=head1 DESCRIPTION

=head1 PROVIDED OPTIONS

=head2 Database Options

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

=head2 Web Server Options

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

