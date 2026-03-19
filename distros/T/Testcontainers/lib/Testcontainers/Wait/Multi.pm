package Testcontainers::Wait::Multi;
# ABSTRACT: Composite wait strategy combining multiple strategies

use strict;
use warnings;
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

our $VERSION = '0.001';

with 'Testcontainers::Wait::Base';

=head1 SYNOPSIS

    use Testcontainers::Wait;

    my $wait = Testcontainers::Wait::for_all(
        Testcontainers::Wait::for_listening_port('5432/tcp'),
        Testcontainers::Wait::for_log('ready to accept connections'),
    );

=head1 DESCRIPTION

Combines multiple wait strategies. All strategies must pass for the
container to be considered ready. Equivalent to Go's C<wait.ForAll()>.

=cut

has strategies => (
    is       => 'ro',
    required => 1,
);

=attr strategies

ArrayRef of wait strategy objects. All must pass.

=cut

sub check {
    my ($self, $container) = @_;

    for my $strategy (@{$self->strategies}) {
        my $ready = eval { $strategy->check($container) };
        unless ($ready) {
            $log->tracef("Multi strategy: %s not ready", ref $strategy);
            return 0;
        }
    }

    $log->debugf("All %d strategies passed", scalar @{$self->strategies});
    return 1;
}

=method check($container)

All child strategies must return true for this to return true.

=cut

1;
