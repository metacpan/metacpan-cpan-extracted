package App::Yath::Command::db::sweeper;
use strict;
use warnings;

our $VERSION = '2.000005';

use App::Yath::Schema::Sweeper;

use App::Yath::Schema::Util qw/schema_config_from_settings/;

sub summary     { "Sweep a database" }
sub description { "Deletes old data from a database" }
sub group       { "database" }

use parent 'App::Yath::Command';
use Getopt::Yath;

include_options(
    'App::Yath::Options::DB',
);

option_group {group => 'sweeper', category => "Sweeper Options"} => sub {
    option coverage => (
        type => 'Bool',
        default => 1,
        description => 'Delete old coverage data (default: yes)',
    );

    option events => (
        type => 'Bool',
        default => 1,
        description => 'Delete old event data (default: yes)',
    );

    option job_try_fields => (
        type => 'Bool',
        default => 1,
        description => 'Delete old job field data (default: yes)',
    );

    option jobs => (
        type => 'Bool',
        default => 1,
        description => 'Delete old job data (default: yes)',
    );

    option job_tries => (
        type => 'Bool',
        default => 1,
        description => 'Delete old job try data (default: yes)',
    );

    option reports => (
        type => 'Bool',
        default => 1,
        description => 'Delete old report data (default: yes)',
    );

    option resources => (
        type => 'Bool',
        default => 1,
        description => 'Delete old resource data (default: yes)',
    );

    option run_fields => (
        type => 'Bool',
        default => 1,
        description => 'Delete old run_field data (default: yes)',
    );

    option runs => (
        type => 'Bool',
        default => 1,
        description => 'Delete old run data (default: yes)',
    );

    option subtests => (
        type => 'Bool',
        default => 1,
        description => 'Delete old subtest data (default: yes)',
    );

    option interval => (
        type => 'Scalar',
        default => "7 days",
        description => "Interval (sql format) to delete (things older than this) defeult: '7 days'",
    );

    option job_concurrency => (
        type => 'Scalar',
        default => 1,
        from_env_vars => ['YATH_SWEEPER_JOB_CONCURRENCY'],
        description => "How many jobs to process concurrently (This compounds with run concurrency)",
    );

    option run_concurrency => (
        type => 'Scalar',
        default => 1,
        from_env_vars => ['YATH_SWEEPER_RUN_CONCURRENCY'],
        description => "How many runs to process concurrently (This compounds with job concurrency)",
    );

    option name => (
        type => 'Scalar',
        default => sub { $ENV{USER} },
        from_env_vars => ['YATH_SWEEPER_NAME'],
        description => "Give a name to the sweep",
    );
};

sub run {
    my $self = shift;

    my $settings = $self->settings;
    my $config = schema_config_from_settings($settings);

    my $sweeper = App::Yath::Schema::Sweeper->new(
        interval => $settings->sweeper->interval,
        config   => $config,
    );

    $sweeper->sweep($settings->sweeper->all);

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::db::sweeper - Sweep a database

=head1 DESCRIPTION

Deletes old data from a database

=head1 USAGE

    $ yath [YATH OPTIONS] db-sweeper [COMMAND OPTIONS]

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

=head3 Sweeper Options

=over 4

=item --coverage

=item --no-coverage

Delete old coverage data (default: yes)


=item --events

=item --no-events

Delete old event data (default: yes)


=item --interval ARG

=item --interval=ARG

=item --no-interval

Interval (sql format) to delete (things older than this) defeult: '7 days'


=item --job-concurrency ARG

=item --job-concurrency=ARG

=item --no-job-concurrency

How many jobs to process concurrently (This compounds with run concurrency)

Can also be set with the following environment variables: C<YATH_SWEEPER_JOB_CONCURRENCY>


=item --job-tries

=item --no-job-tries

Delete old job try data (default: yes)


=item --job-try-fields

=item --no-job-try-fields

Delete old job field data (default: yes)


=item --jobs

=item --no-jobs

Delete old job data (default: yes)


=item --name ARG

=item --name=ARG

=item --no-name

Give a name to the sweep

Can also be set with the following environment variables: C<YATH_SWEEPER_NAME>


=item --reports

=item --no-reports

Delete old report data (default: yes)


=item --resources

=item --no-resources

Delete old resource data (default: yes)


=item --run-concurrency ARG

=item --run-concurrency=ARG

=item --no-run-concurrency

How many runs to process concurrently (This compounds with job concurrency)

Can also be set with the following environment variables: C<YATH_SWEEPER_RUN_CONCURRENCY>


=item --run-fields

=item --no-run-fields

Delete old run_field data (default: yes)


=item --runs

=item --no-runs

Delete old run data (default: yes)


=item --subtests

=item --no-subtests

Delete old subtest data (default: yes)


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
