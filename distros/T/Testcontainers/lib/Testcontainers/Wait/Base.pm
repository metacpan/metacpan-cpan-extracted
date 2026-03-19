package Testcontainers::Wait::Base;
# ABSTRACT: Base role for wait strategies

use strict;
use warnings;
use Moo::Role;
use Carp qw( croak );
use Log::Any qw( $log );
use Time::HiRes qw( time sleep );

our $VERSION = '0.001';

=head1 DESCRIPTION

Base role that all wait strategies must consume. Provides the common
C<wait_until_ready> interface and the polling loop infrastructure.

=cut

has startup_timeout => (
    is      => 'rw',
    default => 60,
);

=attr startup_timeout

Maximum seconds to wait before timing out. Default: 60.
Can be overridden per-strategy or via the C<startup_timeout> option in C<run()>.

=cut

has poll_interval => (
    is      => 'rw',
    default => 0.1,
);

=attr poll_interval

Seconds between poll attempts. Default: 0.1 (100ms).

=cut

requires 'check';

sub wait_until_ready {
    my ($self, $container, $timeout) = @_;
    $timeout //= $self->startup_timeout;

    my $deadline = time() + $timeout;
    my $strategy_name = ref($self) =~ s/.*:://r;

    $log->debugf("Waiting for %s strategy (timeout: %ds)", $strategy_name, $timeout);

    while (time() < $deadline) {
        my $ready = eval { $self->check($container) };
        if ($@) {
            $log->tracef("Wait check failed: %s", $@);
        }

        if ($ready) {
            $log->debugf("%s strategy: container is ready", $strategy_name);
            return 1;
        }

        sleep($self->poll_interval);
    }

    croak sprintf(
        "Timeout after %ds waiting for container %s (%s strategy)",
        $timeout, $container->id, $strategy_name
    );
}

=method wait_until_ready($container, $timeout)

Poll the C<check()> method until it returns true or the timeout is reached.
Dies with a timeout error if the container doesn't become ready in time.

=cut

1;
