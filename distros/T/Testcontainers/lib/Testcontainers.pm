package Testcontainers;
# ABSTRACT: Testcontainers for Perl - Docker containers for testing

use strict;
use warnings;
use Carp qw( croak );
use Log::Any qw( $log );

use Testcontainers::DockerClient;
use Testcontainers::Container;
use Testcontainers::ContainerRequest;
use Testcontainers::Labels qw( session_id );
use Testcontainers::Wait;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw( run terminate_container );

=head1 SYNOPSIS

    use Testcontainers qw( run terminate_container );
    use Testcontainers::Wait;

    # Simple usage - run a container
    my $container = run('nginx:alpine',
        exposed_ports => ['80/tcp'],
        wait_for      => Testcontainers::Wait::for_listening_port('80/tcp'),
    );

    # Get connection details
    my $host = $container->host;
    my $port = $container->mapped_port('80/tcp');

    # Use the container in tests...

    # Clean up
    $container->terminate;

    # Or with environment variables and labels
    my $container = run('postgres:16-alpine',
        exposed_ports => ['5432/tcp'],
        env           => { POSTGRES_PASSWORD => 'test', POSTGRES_DB => 'testdb' },
        labels        => { 'testcontainers' => 'true' },
        wait_for      => Testcontainers::Wait::for_log('database system is ready to accept connections'),
    );

=head1 DESCRIPTION

Testcontainers for Perl is a Perl library that makes it simple to create and clean up
container-based dependencies for automated integration/smoke tests. The clean,
easy-to-use API enables developers to programmatically define containers that
should be run as part of a test and clean up those resources when the test is done.

This library is inspired by the L<Testcontainers for Go|https://golang.testcontainers.org/>
project and uses L<WWW::Docker> as its Docker client library.

=head1 FEATURES

=over

=item * Simple API for creating and managing test containers

=item * Wait strategies: port listening, HTTP endpoints, log messages, health checks

=item * Pre-built modules for popular services (PostgreSQL, MySQL, Redis, Nginx)

=item * Automatic container cleanup

=item * Port mapping and host resolution

=item * Environment variable and label support

=item * Container lifecycle hooks

=back

=cut

sub run {
    my ($image, %opts) = @_;
    croak "Image name required" unless $image;

    $log->debugf("Creating container from image: %s", $image);

    # Build a ContainerRequest from the options
    my $request = Testcontainers::ContainerRequest->new(
        image         => $image,
        exposed_ports => $opts{exposed_ports} // [],
        env           => $opts{env}           // {},
        labels           => $opts{labels}           // {},
        _internal_labels => $opts{_internal_labels} // {},
        cmd           => $opts{cmd}           // [],
        entrypoint    => $opts{entrypoint}    // [],
        name          => $opts{name}          // undef,
        wait_for      => $opts{wait_for}      // undef,
        tmpfs         => $opts{tmpfs}         // {},
        startup_timeout => $opts{startup_timeout} // 60,
        privileged    => $opts{privileged}    // 0,
        network_mode  => $opts{network_mode}  // undef,
        networks      => $opts{networks}      // [],
        session_id    => session_id(),
    );

    # Create the Docker client
    my $docker = Testcontainers::DockerClient->new(
        ($opts{docker_host} ? (docker_host => $opts{docker_host}) : ()),
    );

    # Pull image if needed
    $docker->pull_image($image) unless $opts{no_pull};

    # Create container configuration
    my $config = $request->to_docker_config;

    # Create the container
    my $create_result = $docker->create_container($config, $request->name);
    my $container_id = $create_result->{Id};

    $log->debugf("Created container: %s", $container_id);

    # Create the Container object
    my $container = Testcontainers::Container->new(
        id       => $container_id,
        image    => $image,
        docker   => $docker,
        request  => $request,
    );

    # Start the container
    $docker->start_container($container_id);
    $log->debugf("Started container: %s", $container_id);

    # Refresh container info to get port mappings
    $container->refresh;

    # Execute wait strategy if defined
    if ($request->wait_for) {
        $log->debug("Executing wait strategy...");
        $request->wait_for->wait_until_ready($container, $request->startup_timeout);
        $log->debug("Container is ready");
    }

    return $container;
}

=func run($image, %opts)

Create and start a new container. Returns a L<Testcontainers::Container> object.

Arguments:

=over

=item * C<$image> - Docker image name (required)

=item * C<exposed_ports> - ArrayRef of ports to expose (e.g., C<['80/tcp', '443/tcp']>)

=item * C<env> - HashRef of environment variables

=item * C<labels> - HashRef of container labels

=item * C<cmd> - ArrayRef of command arguments

=item * C<entrypoint> - ArrayRef for container entrypoint

=item * C<name> - Container name (optional)

=item * C<wait_for> - Wait strategy object (from L<Testcontainers::Wait>)

=item * C<tmpfs> - HashRef of tmpfs mounts (path => options)

=item * C<startup_timeout> - Timeout in seconds for wait strategy (default: 60)

=item * C<privileged> - Run in privileged mode (default: false)

=item * C<network_mode> - Docker network mode

=item * C<networks> - ArrayRef of network names

=item * C<docker_host> - Docker daemon URL (overrides DOCKER_HOST)

=item * C<no_pull> - Skip pulling the image (default: false)

=back

=cut

sub terminate_container {
    my ($container) = @_;
    return unless $container;
    return $container->terminate;
}

=func terminate_container($container)

Terminate and remove a container. Safe to call with undef.

=cut

=head1 ENVIRONMENT VARIABLES

=over

=item C<DOCKER_HOST>

Docker daemon connection URL. Default: C<unix:///var/run/docker.sock>

=item C<TESTCONTAINERS_RYUK_DISABLED>

Set to C<1> to disable the Ryuk resource reaper (container cleanup).

=back

=head1 SEE ALSO

=over

=item * L<Testcontainers::Container> - Container instance methods

=item * L<Testcontainers::Wait> - Wait strategy factory

=item * L<Testcontainers::Module::PostgreSQL> - PostgreSQL module

=item * L<Testcontainers::Module::MySQL> - MySQL module

=item * L<Testcontainers::Module::Redis> - Redis module

=item * L<WWW::Docker> - Docker client library

=item * L<https://golang.testcontainers.org/> - Testcontainers for Go (reference)

=back

=cut

1;
