package Testcontainers::Module::Redis;
# ABSTRACT: Redis container module for Testcontainers

use strict;
use warnings;
use Carp qw( croak );
use Testcontainers;
use Testcontainers::Wait;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw( redis_container );

use constant {
    DEFAULT_IMAGE => 'redis:7-alpine',
    DEFAULT_PORT  => '6379/tcp',
};

=head1 SYNOPSIS

    use Testcontainers::Module::Redis qw( redis_container );

    my $redis = redis_container();

    my $host = $redis->host;
    my $port = $redis->mapped_port('6379/tcp');
    my $url  = $redis->connection_string;  # "redis://localhost:32789"

    $redis->terminate;

=head1 DESCRIPTION

Pre-configured Redis container module, equivalent to Go's
C<testcontainers-go/modules/redis>.

=cut

sub redis_container {
    my (%opts) = @_;

    my $image = $opts{image} // DEFAULT_IMAGE;
    my $port  = $opts{port}  // DEFAULT_PORT;

    my @cmd;
    if ($opts{password}) {
        push @cmd, 'redis-server', '--requirepass', $opts{password};
    }

    my $container = Testcontainers::run($image,
        exposed_ports   => [$port],
        _internal_labels => {
            'org.testcontainers.module' => 'redis',
        },
        ($opts{password} ? (cmd => \@cmd) : ()),
        wait_for        => Testcontainers::Wait::for_log('Ready to accept connections'),
        startup_timeout => $opts{startup_timeout} // 30,
        ($opts{name} ? (name => $opts{name}) : ()),
    );

    return Testcontainers::Module::Redis::Container->new(
        _inner   => $container,
        password => $opts{password},
        port     => $port,
    );
}

=func redis_container(%opts)

Create and start a Redis container.

Options: C<image>, C<port>, C<password>, C<startup_timeout>, C<name>.

=cut


package Testcontainers::Module::Redis::Container;

use strict;
use warnings;
use Moo;

has _inner   => (is => 'ro', required => 1, handles => [qw(
    id image host mapped_port mapped_port_info endpoint container_id
    name state is_running logs exec stop start terminate refresh
)]);
has password => (is => 'ro', default => undef);
has port     => (is => 'ro', required => 1);

sub connection_string {
    my ($self) = @_;
    my $host = $self->host;
    my $mapped = $self->mapped_port($self->port);
    if ($self->password) {
        return sprintf("redis://:%s\@%s:%s", $self->password, $host, $mapped);
    }
    return sprintf("redis://%s:%s", $host, $mapped);
}

=method connection_string

Returns a Redis connection URL: C<redis://host:port> or
C<redis://:password@host:port>.

=cut

sub DEMOLISH {
    my ($self, $in_global) = @_;
    return if $in_global;
    $self->_inner->terminate if $self->_inner;
    return;
}

1;
