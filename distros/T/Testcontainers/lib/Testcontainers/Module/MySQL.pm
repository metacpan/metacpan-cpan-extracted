package Testcontainers::Module::MySQL;
# ABSTRACT: MySQL container module for Testcontainers

use strict;
use warnings;
use Carp qw( croak );
use Testcontainers;
use Testcontainers::Wait;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw( mysql_container );

use constant {
    DEFAULT_IMAGE         => 'mysql:8.0',
    DEFAULT_PORT          => '3306/tcp',
    DEFAULT_ROOT_PASSWORD => 'test',
    DEFAULT_USER          => 'test',
    DEFAULT_PASSWORD      => 'test',
    DEFAULT_DB            => 'testdb',
};

=head1 SYNOPSIS

    use Testcontainers::Module::MySQL qw( mysql_container );

    my $mysql = mysql_container();

    my $host = $mysql->host;
    my $port = $mysql->mapped_port('3306/tcp');
    my $dsn  = $mysql->dsn;

    $mysql->terminate;

=head1 DESCRIPTION

Pre-configured MySQL container module, equivalent to Go's
C<testcontainers-go/modules/mysql>.

=cut

sub mysql_container {
    my (%opts) = @_;

    my $image         = $opts{image}         // DEFAULT_IMAGE;
    my $root_password = $opts{root_password} // DEFAULT_ROOT_PASSWORD;
    my $username      = $opts{username}      // DEFAULT_USER;
    my $password      = $opts{password}      // DEFAULT_PASSWORD;
    my $database      = $opts{database}      // DEFAULT_DB;
    my $port          = $opts{port}          // DEFAULT_PORT;

    my $container = Testcontainers::run($image,
        exposed_ports   => [$port],
        env             => {
            MYSQL_ROOT_PASSWORD => $root_password,
            MYSQL_USER          => $username,
            MYSQL_PASSWORD      => $password,
            MYSQL_DATABASE      => $database,
        },
        _internal_labels => {
            'org.testcontainers.module' => 'mysql',
        },
        wait_for        => Testcontainers::Wait::for_log(
            'port: 3306  MySQL Community Server',
        ),
        startup_timeout => $opts{startup_timeout} // 120,
        ($opts{name} ? (name => $opts{name}) : ()),
    );

    return Testcontainers::Module::MySQL::Container->new(
        _inner        => $container,
        username      => $username,
        password      => $password,
        root_password => $root_password,
        database      => $database,
        port          => $port,
    );
}

=func mysql_container(%opts)

Create and start a MySQL container.

Options: C<image>, C<root_password>, C<username>, C<password>, C<database>,
C<port>, C<startup_timeout>, C<name>.

=cut


package Testcontainers::Module::MySQL::Container;

use strict;
use warnings;
use Moo;

has _inner        => (is => 'ro', required => 1, handles => [qw(
    id image host mapped_port mapped_port_info endpoint container_id
    name state is_running logs exec stop start terminate refresh
)]);
has username      => (is => 'ro', required => 1);
has password      => (is => 'ro', required => 1);
has root_password => (is => 'ro', required => 1);
has database      => (is => 'ro', required => 1);
has port          => (is => 'ro', required => 1);

sub connection_string {
    my ($self) = @_;
    my $host = $self->host;
    my $mapped = $self->mapped_port($self->port);
    return sprintf("mysql://%s:%s\@%s:%s/%s",
        $self->username, $self->password, $host, $mapped, $self->database);
}

sub dsn {
    my ($self) = @_;
    my $host = $self->host;
    my $mapped = $self->mapped_port($self->port);
    return sprintf("dbi:mysql:database=%s;host=%s;port=%s",
        $self->database, $host, $mapped);
}

=method dsn

Returns a DBI-compatible DSN: C<dbi:mysql:database=...;host=...;port=...>

=cut

sub DEMOLISH {
    my ($self, $in_global) = @_;
    return if $in_global;
    $self->_inner->terminate if $self->_inner;
    return;
}

1;
