package Testcontainers::Module::Nginx;
# ABSTRACT: Nginx container module for Testcontainers

use strict;
use warnings;
use Carp qw( croak );
use Testcontainers;
use Testcontainers::Wait;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw( nginx_container );

use constant {
    DEFAULT_IMAGE => 'nginx:alpine',
    DEFAULT_PORT  => '80/tcp',
};

=head1 SYNOPSIS

    use Testcontainers::Module::Nginx qw( nginx_container );

    my $nginx = nginx_container();

    my $url = $nginx->base_url;  # "http://localhost:32789"

    $nginx->terminate;

=head1 DESCRIPTION

Pre-configured Nginx container module, equivalent to Go's
Nginx example.

=cut

sub nginx_container {
    my (%opts) = @_;

    my $image = $opts{image} // DEFAULT_IMAGE;
    my $port  = $opts{port}  // DEFAULT_PORT;

    my $container = Testcontainers::run($image,
        exposed_ports   => [$port],
        _internal_labels => {
            'org.testcontainers.module' => 'nginx',
        },
        wait_for        => Testcontainers::Wait::for_http('/'),
        startup_timeout => $opts{startup_timeout} // 30,
        ($opts{name} ? (name => $opts{name}) : ()),
    );

    return Testcontainers::Module::Nginx::Container->new(
        _inner => $container,
        port   => $port,
    );
}

=func nginx_container(%opts)

Create and start an Nginx container.

Options: C<image>, C<port>, C<startup_timeout>, C<name>.

=cut


package Testcontainers::Module::Nginx::Container;

use strict;
use warnings;
use Moo;

has _inner => (is => 'ro', required => 1, handles => [qw(
    id image host mapped_port mapped_port_info endpoint container_id
    name state is_running logs exec stop start terminate refresh
)]);
has port   => (is => 'ro', required => 1);

sub base_url {
    my ($self) = @_;
    my $host = $self->host;
    my $mapped = $self->mapped_port($self->port);
    return sprintf("http://%s:%s", $host, $mapped);
}

=method base_url

Returns the base HTTP URL: C<http://host:port>.

=cut

sub DEMOLISH {
    my ($self, $in_global) = @_;
    return if $in_global;
    $self->_inner->terminate if $self->_inner;
    return;
}

1;
