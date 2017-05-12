package WebService::LogicMonitor::EscalationChain;

# ABSTRACT: An escalation chain

use v5.16.3;
use JSON qw//;
use WebService::LogicMonitor::EscalationChain::Destination;
use WebService::LogicMonitor::EscalationChain::Recipient;
use Moo;

with 'WebService::LogicMonitor::Object';

sub BUILDARGS {
    my ($class, $args) = @_;

    my %transform = (
        enableThrottling => 'enable_throttling',
        inAlerting       => 'in_alerting',
        throttlingAlerts => 'throttling_alerts',
        throttlingPeriod => 'throttling_period',
    );

    for my $key (keys %transform) {
        $args->{$transform{$key}} = delete $args->{$key} if $args->{$key};
    }

    if (exists $args->{ccdestination} && !scalar @{$args->{ccdestination}}) {
        delete $args->{ccdestination};
    }

    if ($args->{destination}) {

        # XXX under what circumstances would this array actually have more than
        # one value

        my $d = shift @{$args->{destination}};
        delete $args->{destination};

        my @stages;
        my %cache
          ; # cache recipients so we can use references instread of duplicating
        for my $stage (@{$d->{stages}}) {
            my @recipients;

            for (@$stage) {
                my $key = sprintf '%s_%s', $_->{addr}, $_->{method};
                if (exists $cache{$key}) {
                    push @recipients, $cache{$key};
                } else {
                    my $recipient =
                      WebService::LogicMonitor::EscalationChain::Recipient
                      ->new($_);
                    push @recipients, $recipient;
                    $cache{$key} = $recipient;
                }

            }
            push @stages, \@recipients;
        }

        $args->{destination} =
          WebService::LogicMonitor::EscalationChain::Destination->new(
            type   => (delete $d->{type}),
            stages => \@stages,
          );

    }

    return $args;
}

has id => (is => 'ro');    # int

has name => (is => 'ro');  # str

has ccdestination => (is => 'rw');    # array of str - emails?

has description => (is => 'rw');      # str

has destination => (is => 'rw');      # array

has enable_throttling => (is => 'rw');    # bool

has in_alerting => (is => 'ro');          # bool

has throttling_alerts => (is => 'rw');    # int

has throttling_period => (is => 'rw');    # int


sub update {
    my $self = shift;

    my %transform = (
        enable_throttling => 'enableThrottling',
        throttling_alerts => 'throttlingAlerts',
        throttling_period => 'throttlingPeriod',
    );

    my %params;

    for my $key (keys %transform) {
        $params{$transform{$key}} = $self->$key;
    }

    for my $key (qw/id name description/) {
        $params{$key} = $self->$key;
    }

    my $json = JSON->new;

    foreach my $key (qw/destination ccdestination/) {
        next unless $self->$key;
        $params{$key} =
          $json->allow_blessed->convert_blessed->encode($self->$key);
    }

    return $self->_lm->_http_get('updateEscalatingChain', \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::EscalationChain - An escalation chain

=head1 VERSION

version 0.153170

=head1 METHODS

=head2 C<update>

id and name are the minimum to update a chain, but everything else that is
not sent in the update will be reset to defaults.

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
