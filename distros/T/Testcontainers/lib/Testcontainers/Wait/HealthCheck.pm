package Testcontainers::Wait::HealthCheck;
# ABSTRACT: Wait strategy for Docker health checks

use strict;
use warnings;
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

our $VERSION = '0.001';

with 'Testcontainers::Wait::Base';

=head1 SYNOPSIS

    use Testcontainers::Wait;

    my $wait = Testcontainers::Wait::for_health_check();

=head1 DESCRIPTION

Waits for the Docker health check (if configured in the image) to report
"healthy". Equivalent to Go's C<wait.ForHealthCheck()>.

=cut

sub check {
    my ($self, $container) = @_;

    my $state = eval { $container->state };
    return 0 unless $state;

    my $health = $state->{Health} // {};
    my $status = $health->{Status} // '';

    $log->tracef("Health check status: %s", $status);

    return lc($status) eq 'healthy' ? 1 : 0;
}

=method check($container)

Check if Docker reports the container as "healthy".

=cut

1;
