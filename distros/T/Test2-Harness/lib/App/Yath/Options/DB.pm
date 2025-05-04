package App::Yath::Options::DB;
use strict;
use warnings;

our $VERSION = '2.000005';

use Getopt::Yath;

option_group {group => 'db', prefix => 'db', category => "Database Options"} => sub {
    option config => (
        type => 'Scalar',
        description => "Module that implements 'MODULE->yath_db_config(%params)' which should return a App::Yath::Schema::Config instance.",
        from_env_vars => [qw/YATH_DB_CONFIG/],
    );

    option driver => (
        type => 'Scalar',
        description => "DBI Driver to use",
        long_examples => [' Pg', ' PostgreSQL', ' MySQL', ' MariaDB', ' Percona', ' SQLite'],
        from_env_vars => [qw/YATH_DB_DRIVER/],
    );

    option name => (
        type => 'Scalar',
        description => 'Name of the database to use',
        from_env_vars => [qw/YATH_DB_NAME/],
    );

    option user => (
        type => 'Scalar',
        description => 'Username to use when connecting to the db',
        from_env_vars => [qw/YATH_DB_USER USER/],
    );

    option pass => (
        type => 'Scalar',
        description => 'Password to use when connecting to the db',
        from_env_vars => [qw/YATH_DB_PASS/],
    );

    option dsn => (
        type => 'Scalar',
        description => 'DSN to use when connecting to the db',
        from_env_vars => [qw/YATH_DB_DSN/],
    );

    option host => (
        type => 'Scalar',
        description => 'hostname to use when connecting to the db',
        from_env_vars => [qw/YATH_DB_HOST/],
    );

    option port => (
        type => 'Scalar',
        description => 'port to use when connecting to the db',
        from_env_vars => [qw/YATH_DB_PORT/],
    );

    option socket => (
        type => 'Scalar',
        description => 'socket to use when connecting to the db',
        from_env_vars => [qw/YATH_DB_SOCKET/],
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Options::DB - Options used for database connections.

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

