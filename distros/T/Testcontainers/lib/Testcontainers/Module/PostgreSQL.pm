package Testcontainers::Module::PostgreSQL;
# ABSTRACT: PostgreSQL container module for Testcontainers

use strict;
use warnings;
use Carp qw( croak );
use Testcontainers;
use Testcontainers::Wait;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw( postgres_container );

use constant {
    DEFAULT_IMAGE    => 'postgres:16-alpine',
    DEFAULT_PORT     => '5432/tcp',
    DEFAULT_USER     => 'test',
    DEFAULT_PASSWORD => 'test',
    DEFAULT_DB       => 'testdb',
};

=head1 SYNOPSIS

    use Testcontainers::Module::PostgreSQL qw( postgres_container );

    # Quick start with defaults
    my $pg = postgres_container();

    # Custom configuration
    my $pg = postgres_container(
        image    => 'postgres:15-alpine',
        username => 'myuser',
        password => 'mypass',
        database => 'mydb',
    );

    # Get connection details
    my $host = $pg->host;
    my $port = $pg->mapped_port('5432/tcp');
    my $dsn  = $pg->connection_string;  # "postgresql://test:test@localhost:32789/testdb"

    # Clean up
    $pg->terminate;

=head1 DESCRIPTION

Pre-configured PostgreSQL container module, equivalent to Go's
C<testcontainers-go/modules/postgres>. Provides a PostgreSQL database
ready for testing with sensible defaults.

=cut

sub postgres_container {
    my (%opts) = @_;

    my $image    = $opts{image}    // DEFAULT_IMAGE;
    my $username = $opts{username} // DEFAULT_USER;
    my $password = $opts{password} // DEFAULT_PASSWORD;
    my $database = $opts{database} // DEFAULT_DB;
    my $port     = $opts{port}     // DEFAULT_PORT;

    my $container = Testcontainers::run($image,
        exposed_ports   => [$port],
        env             => {
            POSTGRES_USER     => $username,
            POSTGRES_PASSWORD => $password,
            POSTGRES_DB       => $database,
        },
        _internal_labels => {
            'org.testcontainers.module' => 'postgresql',
        },
        wait_for        => Testcontainers::Wait::for_log(
            'database system is ready to accept connections',
            occurrences => 2,
        ),
        startup_timeout => $opts{startup_timeout} // 60,
        ($opts{name} ? (name => $opts{name}) : ()),
    );

    # Bless into our subclass for extra methods
    return Testcontainers::Module::PostgreSQL::Container->new(
        _inner   => $container,
        username => $username,
        password => $password,
        database => $database,
        port     => $port,
    );
}

=func postgres_container(%opts)

Create and start a PostgreSQL container. Returns a container object with
additional PostgreSQL-specific methods.

Options:

=over

=item * C<image> - Docker image (default: C<postgres:16-alpine>)

=item * C<username> - PostgreSQL user (default: C<test>)

=item * C<password> - PostgreSQL password (default: C<test>)

=item * C<database> - Database name (default: C<testdb>)

=item * C<port> - Container port (default: C<5432/tcp>)

=item * C<startup_timeout> - Timeout in seconds (default: 60)

=item * C<name> - Container name

=back

=cut


package Testcontainers::Module::PostgreSQL::Container;

use strict;
use warnings;
use Moo;

has _inner   => (is => 'ro', required => 1, handles => [qw(
    id image host mapped_port mapped_port_info endpoint container_id
    name state is_running logs exec stop start terminate refresh
)]);
has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);
has database => (is => 'ro', required => 1);
has port     => (is => 'ro', required => 1);

sub connection_string {
    my ($self) = @_;
    my $host = $self->host;
    my $mapped = $self->mapped_port($self->port);
    return sprintf("postgresql://%s:%s\@%s:%s/%s",
        $self->username, $self->password, $host, $mapped, $self->database);
}

=method connection_string

Returns a PostgreSQL connection string:
C<postgresql://user:pass@host:port/dbname>

=cut

sub dsn {
    my ($self) = @_;
    my $host = $self->host;
    my $mapped = $self->mapped_port($self->port);
    return sprintf("dbi:Pg:dbname=%s;host=%s;port=%s",
        $self->database, $host, $mapped);
}

=method dsn

Returns a DBI-compatible DSN: C<dbi:Pg:dbname=...;host=...;port=...>

=cut

sub DEMOLISH {
    my ($self, $in_global) = @_;
    return if $in_global;
    $self->_inner->terminate if $self->_inner;
    return;
}

1;
