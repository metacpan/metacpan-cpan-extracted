package App::Yath::Command::db::sync;
use strict;
use warnings;

our $VERSION = '2.000005';

use DBI;
use App::Yath::Schema::Sync;

use App::Yath::Schema::Util qw/schema_config_from_settings/;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

sub summary     { "Sync runs and associated data from one db to another" }
sub description { "Sync runs and associated data from one db to another" }
sub group       { "database" }

sub cli_args { "" }

use Getopt::Yath;

for my $set (qw/from to/) {
    option_group {group => $set, prefix => $set, category => ucfirst($set) . " Database Options"} => sub {
        option config => (
            type          => 'Scalar',
            description   => "Module that implements 'MODULE->yath_db_config(%params)' which should return a App::Yath::Schema::Config instance.",
            from_env_vars => [qw/YATH_DB_CONFIG/],
        );

        option driver => (
            type          => 'Scalar',
            description   => "DBI Driver to use",
            long_examples => [' Pg', ' PostgreSQL', ' MySQL', ' MariaDB', ' Percona', ' SQLite'],
            from_env_vars => [qw/YATH_DB_DRIVER/],
        );

        option name => (
            type          => 'Scalar',
            description   => 'Name of the database to use',
            from_env_vars => [qw/YATH_DB_NAME/],
        );

        option user => (
            type          => 'Scalar',
            description   => 'Username to use when connecting to the db',
            from_env_vars => [qw/YATH_DB_USER USER/],
        );

        option pass => (
            type          => 'Scalar',
            description   => 'Password to use when connecting to the db',
            from_env_vars => [qw/YATH_DB_PASS/],
        );

        option dsn => (
            type          => 'Scalar',
            description   => 'DSN to use when connecting to the db',
            from_env_vars => [qw/YATH_DB_DSN/],
        );

        option host => (
            type          => 'Scalar',
            description   => 'hostname to use when connecting to the db',
            from_env_vars => [qw/YATH_DB_HOST/],
        );

        option port => (
            type          => 'Scalar',
            description   => 'port to use when connecting to the db',
            from_env_vars => [qw/YATH_DB_PORT/],
        );

        option socket => (
            type          => 'Scalar',
            description   => 'socket to use when connecting to the db',
            from_env_vars => [qw/YATH_DB_SOCKET/],
        );
    };
}

sub run {
    my $self = shift;

    my $args = $self->args;
    my $settings = $self->settings;

    my $from_cfg = schema_config_from_settings($settings, settings_group => 'from');
    my $to_cfg   = schema_config_from_settings($settings, settings_group => 'to');

    my $source_dbh = $self->get_dbh($from_cfg);
    my $dest_dbh   = $self->get_dbh($to_cfg);

    my $sync = App::Yath::Schema::Sync->new();

    my $delta = $sync->run_delta($source_dbh, $dest_dbh);

    $sync->sync(
        from_dbh  => $source_dbh,
        to_dbh    => $dest_dbh,
        run_uuids => $delta->{missing_in_b},

        debug => 1,    # Print a notice for each dumped run_id
    );

    return 0;
}

sub get_dbh {
    my $self = shift;
    my ($cfg) = @_;

    return DBI->connect($cfg->dbi_dsn, $cfg->dbi_user, $cfg->dbi_pass, {AutoCommit => 1, RaiseError => 1});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::db::sync - Sync runs and associated data from one db to another

=head1 DESCRIPTION

Sync runs and associated data from one db to another

=head1 USAGE

    $ yath [YATH OPTIONS] db-sync [COMMAND OPTIONS]

=head2 OPTIONS

=head3 From Database Options

=over 4

=item --from-config ARG

=item --from-config=ARG

=item --no-from-config

Module that implements 'MODULE->yath_db_config(%params)' which should return a App::Yath::Schema::Config instance.

Can also be set with the following environment variables: C<YATH_DB_CONFIG>


=item --from-driver Pg

=item --from-driver MySQL

=item --from-driver SQLite

=item --from-driver MariaDB

=item --from-driver Percona

=item --from-driver PostgreSQL

=item --no-from-driver

DBI Driver to use

Can also be set with the following environment variables: C<YATH_DB_DRIVER>


=item --from-dsn ARG

=item --from-dsn=ARG

=item --no-from-dsn

DSN to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_DSN>


=item --from-host ARG

=item --from-host=ARG

=item --no-from-host

hostname to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_HOST>


=item --from-name ARG

=item --from-name=ARG

=item --no-from-name

Name of the database to use

Can also be set with the following environment variables: C<YATH_DB_NAME>


=item --from-pass ARG

=item --from-pass=ARG

=item --no-from-pass

Password to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PASS>


=item --from-port ARG

=item --from-port=ARG

=item --no-from-port

port to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PORT>


=item --from-socket ARG

=item --from-socket=ARG

=item --no-from-socket

socket to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_SOCKET>


=item --from-user ARG

=item --from-user=ARG

=item --no-from-user

Username to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_USER>, C<USER>


=back

=head3 To Database Options

=over 4

=item --to-config ARG

=item --to-config=ARG

=item --no-to-config

Module that implements 'MODULE->yath_db_config(%params)' which should return a App::Yath::Schema::Config instance.

Can also be set with the following environment variables: C<YATH_DB_CONFIG>


=item --to-driver Pg

=item --to-driver MySQL

=item --to-driver SQLite

=item --to-driver MariaDB

=item --to-driver Percona

=item --to-driver PostgreSQL

=item --no-to-driver

DBI Driver to use

Can also be set with the following environment variables: C<YATH_DB_DRIVER>


=item --to-dsn ARG

=item --to-dsn=ARG

=item --no-to-dsn

DSN to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_DSN>


=item --to-host ARG

=item --to-host=ARG

=item --no-to-host

hostname to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_HOST>


=item --to-name ARG

=item --to-name=ARG

=item --no-to-name

Name of the database to use

Can also be set with the following environment variables: C<YATH_DB_NAME>


=item --to-pass ARG

=item --to-pass=ARG

=item --no-to-pass

Password to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PASS>


=item --to-port ARG

=item --to-port=ARG

=item --no-to-port

port to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PORT>


=item --to-socket ARG

=item --to-socket=ARG

=item --no-to-socket

socket to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_SOCKET>


=item --to-user ARG

=item --to-user=ARG

=item --no-to-user

Username to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_USER>, C<USER>


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

