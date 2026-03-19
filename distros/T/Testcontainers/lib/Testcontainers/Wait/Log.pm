package Testcontainers::Wait::Log;
# ABSTRACT: Wait strategy for container log messages

use strict;
use warnings;
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

our $VERSION = '0.001';

with 'Testcontainers::Wait::Base';

=head1 SYNOPSIS

    use Testcontainers::Wait;

    # Wait for a specific log message
    my $wait = Testcontainers::Wait::for_log('ready to accept connections');

    # Wait for a regex pattern
    my $wait = Testcontainers::Wait::for_log(qr/listening on port \d+/);

    # Wait for multiple occurrences
    my $wait = Testcontainers::Wait::for_log('connected', occurrences => 2);

=head1 DESCRIPTION

Waits for a specific string or regex pattern to appear in the container logs.
Equivalent to Go's C<wait.ForLog()>.

=cut

has pattern => (
    is       => 'ro',
    required => 1,
);

=attr pattern

String or compiled regex (qr//) to match in container logs.

=cut

has occurrences => (
    is      => 'ro',
    default => 1,
);

=attr occurrences

Number of times the pattern must appear. Default: 1.

=cut

sub check {
    my ($self, $container) = @_;

    my $logs = eval { $container->logs(stdout => 1, stderr => 1) };
    return 0 unless defined $logs;

    # Ensure logs is a string
    $logs = ref $logs ? "$logs" : $logs;

    my $pattern = $self->pattern;
    my $count;

    if (ref $pattern eq 'Regexp') {
        my @matches = ($logs =~ /$pattern/g);
        $count = scalar @matches;
    } else {
        # Count occurrences of literal string
        $count = 0;
        my $pos = 0;
        while (($pos = index($logs, $pattern, $pos)) != -1) {
            $count++;
            $pos += length($pattern);
        }
    }

    $log->tracef("Log pattern matched %d/%d times", $count, $self->occurrences);

    return $count >= $self->occurrences ? 1 : 0;
}

=method check($container)

Check container logs for the pattern. Returns true when the required
number of occurrences is found.

=cut

1;
