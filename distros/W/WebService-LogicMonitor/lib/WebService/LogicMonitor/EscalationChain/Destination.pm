package WebService::LogicMonitor::EscalationChain::Destination;

# ABSTRACT: An escalation destination

use v5.16.3;
use Moo;

has type   => (is => 'rw');    # enum simple|timebased
has stages => (is => 'rw');    # arrayref

sub TO_JSON {
    my $self = shift;

    my @stages;

    #$self->stages
    return [{
            type   => $self->type,
            stages => $self->stages,
        }];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::EscalationChain::Destination - An escalation destination

=head1 VERSION

version 0.211560

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
