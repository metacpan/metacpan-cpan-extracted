package WebService::LogicMonitor::EscalationChain::Recipient;

# ABSTRACT: An escalation destination

use v5.16.3;
use Moo;

sub BUILDARGS {
    my ($class, $args) = @_;

    if (exists $args->{comment} && !$args->{comment}) {
        delete $args->{comment};
    }

    return $args;
}

has addr    => (is => 'ro');    # str
has method  => (is => 'ro');    # enum sms|email|smsemail|voice
has comment => (is => 'rw');    # array of str - emails?
has type    => (is => 'rw');    # enum? admin|arbitrary

sub TO_JSON {
    my $self = shift;

    my %hash = %{$self};

    return \%hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::EscalationChain::Recipient - An escalation destination

=head1 VERSION

version 0.211560

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
